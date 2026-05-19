import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class RealtimeNotificationService {
  static RealtimeChannel? _channel;
  static final _controller = StreamController<Map<String, dynamic>>.broadcast();
  static final _localNotif = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Stream<Map<String, dynamic>> get onNewTransaction => _controller.stream;

  static Future<void> initialize() async {
    if (_initialized) return;

    await _localNotif.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final android = _localNotif.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }

    _initialized = true;
  }

  static void start() {
    stop();
    _startRealtime();
  }

  static void _startRealtime() {
    try {
      _channel = SupabaseConfig.client.channel('admin-tx-watch');
      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'transactions',
            callback: (payload) {
              final rec = payload.newRecord;
              if (rec.isNotEmpty) _handleNewTransaction(rec);
            },
          )
          .subscribe();
    } catch (e) {
      if (kDebugMode) debugPrint('[NOTIF] Realtime failed: $e');
    }
  }

  static void _handleNewTransaction(Map<String, dynamic> tx) {
    _controller.add(tx);
    _showLocalNotification(tx);
  }

  static List _parseItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw;
    if (raw is String) {
      try { return jsonDecode(raw) as List; } catch (_) { return []; }
    }
    return [];
  }

  static Future<void> _showLocalNotification(Map<String, dynamic> tx) async {
    if (!_initialized) return;

    try {
      final orderId = (tx['order_id'] ?? '-').toString();
      final customer = (tx['customer_username'] ?? tx['customer_email'] ?? '').toString();
      final amount = tx['gross_amount'];
      final items = _parseItems(tx['items']);

      // Product names
      final productNames = <String>[];
      for (final item in items) {
        if (item is Map) {
          final name = (item['name'] ?? item['product_name'] ?? '').toString();
          final qty = item['quantity'] ?? item['qty'] ?? 1;
          if (name.isNotEmpty) productNames.add('$name x$qty');
        }
      }

      // Build body
      final lines = <String>[];
      if (customer.isNotEmpty) lines.add('Customer: $customer');
      if (productNames.isNotEmpty) lines.add('Produk: ${productNames.join(", ")}');
      lines.add('Order: $orderId');
      if (amount != null) {
        final n = int.tryParse(amount.toString()) ?? 0;
        if (n > 0) {
          final fmt = n.toString().replaceAllMapped(
              RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
          lines.add('Total: Rp $fmt');
        }
      }

      final body = lines.join('\n');

      await _localNotif.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Pesanan Baru Masuk!',
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'new_orders',
            'Pesanan Baru',
            channelDescription: 'Notifikasi pesanan baru',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigTextStyleInformation(body),
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[NOTIF] ERROR showing notification: $e');
    }
  }

  static void stop() {
    _channel?.unsubscribe();
    _channel = null;
  }

  static void dispose() {
    stop();
    _controller.close();
  }
}
