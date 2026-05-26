import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class SecurityService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Get security log stats
  static Future<Map<String, int>> getStats() async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day).toIso8601String();

    try {
      final results = await Future.wait([
        _client.from('security_logs').select('id'),
        _client.from('security_logs').select('id').gte('timestamp', todayStart),
        _client.from('security_logs').select('id').eq('severity', 'CRITICAL'),
        _client.from('ip_blocklist').select('id').gt('expires_at', DateTime.now().toIso8601String()),
      ]);

      return {
        'total': (results[0] as List).length,
        'today': (results[1] as List).length,
        'critical': (results[2] as List).length,
        'blocked': (results[3] as List).length,
      };
    } catch (_) {
      return {'total': 0, 'today': 0, 'critical': 0, 'blocked': 0};
    }
  }

  /// Get recent security logs
  static Future<List<Map<String, dynamic>>> getLogs({int limit = 50, String? severity, String? attackType}) async {
    try {
      var query = _client.from('security_logs').select();
      if (severity != null && severity.isNotEmpty) {
        if (severity == 'HIGH') {
          query = _client.from('security_logs').select().or('severity.eq.HIGH,severity.eq.CRITICAL');
        } else {
          query = _client.from('security_logs').select().eq('severity', severity);
        }
      }
      if (attackType != null && attackType.isNotEmpty) {
        query = _client.from('security_logs').select().eq('attack_type', attackType);
      }
      final response = await query.order('timestamp', ascending: false).limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  /// Get blocked IPs
  static Future<List<Map<String, dynamic>>> getBlockedIps() async {
    try {
      final response = await _client
          .from('ip_blocklist')
          .select()
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  /// Unblock an IP
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

  /// Get database summary stats (row counts for key tables)
  static Future<Map<String, dynamic>> getDatabaseSummary() async {
    try {
      final results = await Future.wait([
        _client.from('products').select('id'),
        _client.from('profiles').select('id'),
        _client.from('transactions').select('id'),
        _client.from('promos').select('id'),
        _client.from('security_logs').select('id'),
      ]);

      return {
        'products': (results[0] as List).length,
        'users': (results[1] as List).length,
        'transactions': (results[2] as List).length,
        'promos': (results[3] as List).length,
        'security_logs': (results[4] as List).length,
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
      return {
        'fileCount': files.length,
        'totalSize': totalSize,
      };
    } catch (_) {
      return {'fileCount': 0, 'totalSize': 0};
    }
  }
}
