import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class PromoService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Get all promos
  static Future<List<Map<String, dynamic>>> getPromos({bool? isActive}) async {
    var query = _client.from('promos').select().order('created_at', ascending: false);
    if (isActive != null) {
      query = _client.from('promos').select().eq('is_active', isActive).order('created_at', ascending: false);
    }
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create promo
  static Future<void> createPromo(Map<String, dynamic> data) async {
    await _client.from('promos').insert(data);
  }

  /// Update promo
  static Future<void> updatePromo(String id, Map<String, dynamic> data) async {
    await _client.from('promos').update(data).eq('id', id);
  }

  /// Delete promo
  static Future<void> deletePromo(String id) async {
    await _client.from('promos').delete().eq('id', id);
  }

  /// Toggle promo active
  static Future<void> toggleActive(String id, bool isActive) async {
    await _client.from('promos').update({'is_active': isActive}).eq('id', id);
  }

  /// Count promo usage from transactions
  static Future<Map<String, int>> getUsageStats() async {
    final response = await _client
        .from('transactions')
        .select('promo_code')
        .not('promo_code', 'is', null)
        .neq('status', 'failed');

    final stats = <String, int>{};
    for (final row in response) {
      final codes = (row['promo_code'] as String).toLowerCase().split(',').map((s) => s.trim());
      for (final code in codes) {
        if (code.isNotEmpty) stats[code] = (stats[code] ?? 0) + 1;
      }
    }
    return stats;
  }
}
