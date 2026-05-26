import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class SecurityService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // ── Accurate count helper using COUNT(*) (no 1000-row cap) ──────────────
  static Future<int> _exactCount(
    String table, {
    Map<String, dynamic>? eqFilters,
    Map<String, dynamic>? gteFilters,
    Map<String, dynamic>? gtFilters,
    List<String>? inFilter,
    String? inField,
  }) async {
    try {
      var q = _client
          .from(table)
          .select('id', const FetchOptions(count: CountOption.exact, head: true));

      // Apply eq filters
      if (eqFilters != null) {
        eqFilters.forEach((col, val) {
          q = q.eq(col, val);
        });
      }
      // Apply gte filters
      if (gteFilters != null) {
        gteFilters.forEach((col, val) {
          q = q.gte(col, val);
        });
      }
      // Apply gt filters
      if (gtFilters != null) {
        gtFilters.forEach((col, val) {
          q = q.gt(col, val);
        });
      }
      // Apply in filter
      if (inField != null && inFilter != null) {
        q = q.inFilter(inField, inFilter);
      }

      final r = await q;
      // PostgrestList.count is set when CountOption.exact is requested
      try {
        final cnt = (r as dynamic).count;
        if (cnt is int) return cnt;
      } catch (_) {}
      return (r as List).length;
    } catch (e) {
      debugPrint('SecurityService _exactCount error: $e');
      return 0;
    }
  }

  /// Get security stats — uses COUNT(*) for accuracy (no row limit issues)
  static Future<Map<String, int>> getStats() async {
    final now = DateTime.now();
    final todayStart =
        DateTime(now.year, now.month, now.day).toIso8601String();
    final last24h =
        now.subtract(const Duration(hours: 24)).toIso8601String();
    final nowStr = now.toIso8601String();

    try {
      final results = await Future.wait([
        // Total all-time events
        _exactCount('security_logs'),
        // Events today (midnight local time)
        _exactCount('security_logs', gteFilters: {'timestamp': todayStart}),
        // Critical only
        _exactCount('security_logs', eqFilters: {'severity': 'CRITICAL'}),
        // Active blocks (not yet expired)
        _exactCount('ip_blocklist', gtFilters: {'expires_at': nowStr}),
        // High + Critical severity
        _exactCount('security_logs',
            inField: 'severity', inFilter: ['HIGH', 'CRITICAL']),
        // Last 24h events
        _exactCount('security_logs', gteFilters: {'timestamp': last24h}),
      ]);

      return {
        'total': results[0],
        'today': results[1],
        'critical': results[2],
        'blocked': results[3],
        'high': results[4],
        'last24h': results[5],
      };
    } catch (e) {
      debugPrint('SecurityService getStats error: $e');
      return {
        'total': 0, 'today': 0, 'critical': 0,
        'blocked': 0, 'high': 0, 'last24h': 0,
      };
    }
  }

  /// Get recent security logs — properly chains filters
  static Future<List<Map<String, dynamic>>> getLogs({
    int limit = 50,
    String? severity,
    String? attackType,
    DateTime? since,
  }) async {
    try {
      var q = _client.from('security_logs').select();

      // Chain filters correctly (don't recreate query)
      if (severity != null && severity.isNotEmpty) {
        if (severity == 'HIGH') {
          q = q.inFilter('severity', ['HIGH', 'CRITICAL']);
        } else {
          q = q.eq('severity', severity);
        }
      }
      if (attackType != null && attackType.isNotEmpty) {
        q = q.eq('attack_type', attackType);
      }
      if (since != null) {
        q = q.gte('timestamp', since.toIso8601String());
      }

      final response =
          await q.order('timestamp', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SecurityService getLogs error: $e');
      return [];
    }
  }

  /// Get actively blocked IPs (not expired)
  static Future<List<Map<String, dynamic>>> getBlockedIps() async {
    try {
      final response = await _client
          .from('ip_blocklist')
          .select()
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('SecurityService getBlockedIps error: $e');
      return [];
    }
  }

  /// Unblock an IP and log the action
  static Future<void> unblockIp(String ip) async {
    await _client.from('ip_blocklist').delete().eq('ip', ip);
    await _client.from('security_logs').insert({
      'ip': ip,
      'attack_type': 'MANUAL_UNBLOCK',
      'severity': 'LOW',
      'action_taken': 'UNBLOCK',
      'source': 'admin_mobile',
      'detection_reason': 'Manual unblock from mobile admin',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Block an IP manually for a given duration
  static Future<void> blockIp(String ip,
      {String reason = 'Manual block', Duration duration = const Duration(hours: 24)}) async {
    final expiresAt = DateTime.now().add(duration).toIso8601String();
    await _client.from('ip_blocklist').upsert({
      'ip': ip,
      'reason': reason,
      'expires_at': expiresAt,
      'created_at': DateTime.now().toIso8601String(),
    });
    await _client.from('security_logs').insert({
      'ip': ip,
      'attack_type': 'MANUAL_BLOCK',
      'severity': 'HIGH',
      'action_taken': 'BLOCK',
      'source': 'admin_mobile',
      'detection_reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get database summary stats (row counts for key tables)
  static Future<Map<String, dynamic>> getDatabaseSummary() async {
    try {
      final results = await Future.wait([
        _exactCount('products'),
        _exactCount('profiles'),
        _exactCount('transactions'),
        _exactCount('promos'),
        _exactCount('security_logs'),
      ]);
      return {
        'products': results[0],
        'users': results[1],
        'transactions': results[2],
        'promos': results[3],
        'security_logs': results[4],
      };
    } catch (_) {
      return {'products': 0, 'users': 0, 'transactions': 0, 'promos': 0, 'security_logs': 0};
    }
  }

  /// Get storage info from product-images bucket
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final files = await _client.storage.from('product-images').list();
      int totalSize = 0;
      for (final f in files) {
        totalSize += (f.metadata?['size'] as int?) ?? 0;
      }
      return {'fileCount': files.length, 'totalSize': totalSize};
    } catch (_) {
      return {'fileCount': 0, 'totalSize': 0};
    }
  }
}
