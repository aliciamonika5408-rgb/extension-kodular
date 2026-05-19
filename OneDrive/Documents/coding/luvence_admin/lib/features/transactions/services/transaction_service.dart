import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class TransactionService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Get all transactions with optional filters
  static Future<List<Map<String, dynamic>>> getTransactions({
    String? statusFilter,
    String? shippingFilter,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('transactions').select().order('created_at', ascending: false);

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      if (statusFilter == 'need_ship') {
        // Web admin: status === 'success' && (!shipping_status || shipping_status === 'dikemas')
        query = _client.from('transactions').select()
            .eq('status', 'success')
            .or('shipping_status.is.null,shipping_status.eq.dikemas')
            .order('created_at', ascending: false);
      } else {
        // Direct status filter: success, pending, failed
        query = _client.from('transactions').select()
            .eq('status', statusFilter)
            .order('created_at', ascending: false);
      }
    }

    final response = await query.range(offset, offset + limit - 1);
    List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(response);

    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      results = results.where((t) {
        final orderId = (t['order_id'] ?? '').toString().toLowerCase();
        final email = (t['customer_email'] ?? '').toString().toLowerCase();
        final username = (t['customer_username'] ?? '').toString().toLowerCase();
        return orderId.contains(s) || email.contains(s) || username.contains(s);
      }).toList();
    }

    return results;
  }

  /// Get single transaction by ID
  static Future<Map<String, dynamic>> getTransactionById(String id) async {
    return await _client.from('transactions').select().eq('id', id).single();
  }

  /// Update shipping status and tracking number
  static Future<void> updateShipping({
    required String id,
    required String shippingStatus,
    String? trackingNumber,
  }) async {
    final updates = <String, dynamic>{
      'shipping_status': shippingStatus,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (trackingNumber != null) {
      updates['tracking_number'] = trackingNumber;
    }
    if (shippingStatus == 'selesai') {
      updates['delivery_confirmed_at'] = DateTime.now().toIso8601String();
    }
    await _client.from('transactions').update(updates).eq('id', id);
  }

  /// Get revenue stats
  static Future<Map<String, dynamic>> getRevenueStats() async {
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Include all successful payment statuses: 'success' (app), 'settlement'/'capture' (Midtrans)
    final allSettled = await _client.from('transactions').select('gross_amount, created_at')
        .inFilter('status', ['success', 'settlement', 'capture']);

    final List<Map<String, dynamic>> settled = List<Map<String, dynamic>>.from(allSettled);

    int totalRevenue = 0;
    int monthRevenue = 0;
    int weekRevenue = 0;
    int todayRevenue = 0;
    Map<String, int> dailyRevenue = {};

    for (final t in settled) {
      final amount = (t['gross_amount'] as num?)?.toInt() ?? 0;
      final createdUtc = DateTime.tryParse(t['created_at'] ?? '');
      totalRevenue += amount;

      if (createdUtc != null) {
        // Convert UTC to local time for accurate day comparison
        final created = createdUtc.toLocal();
        final createdDay = DateTime(created.year, created.month, created.day);

        if (created.isAfter(thirtyDaysAgo)) monthRevenue += amount;
        if (created.isAfter(sevenDaysAgo)) weekRevenue += amount;
        if (createdDay == todayLocal) {
          todayRevenue += amount;
        }
        final dayKey = '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
        dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0) + amount;
      }
    }

    return {
      'total': totalRevenue,
      'month': monthRevenue,
      'week': weekRevenue,
      'today': todayRevenue,
      'daily': dailyRevenue,
      'count': settled.length,
    };
  }

  /// Get promo details by code
  static Future<Map<String, dynamic>?> getPromoByCode(String code) async {
    try {
      final result = await _client.from('promos').select().eq('code', code).maybeSingle();
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to new orders (realtime)
  static RealtimeChannel subscribeToNewOrders(void Function(Map<String, dynamic>) onNewOrder) {
    return _client.channel('transactions').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'transactions',
      callback: (payload) => onNewOrder(payload.newRecord),
    ).subscribe();
  }
}
