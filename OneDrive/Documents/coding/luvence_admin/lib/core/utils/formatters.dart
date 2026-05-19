import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Formatters {
  Formatters._();

  /// Initialize locale data (call once at app startup)
  static Future<void> initialize() async {
    await initializeDateFormatting('id_ID', null);
  }

  /// Format currency in Indonesian Rupiah
  static String currency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    try {
      final num value = amount is String ? (num.tryParse(amount) ?? 0) : (amount as num);
      final formatter = NumberFormat('#,###', 'id_ID');
      return 'Rp ${formatter.format(value)}';
    } catch (_) {
      return 'Rp $amount';
    }
  }

  /// Format date in Indonesian locale
  static String dateId(DateTime? date) {
    if (date == null) return '-';
    try {
      return DateFormat('d MMMM yyyy', 'id_ID').format(date.toLocal());
    } catch (_) {
      return DateFormat('d MMMM yyyy').format(date.toLocal());
    }
  }

  /// Format date with time
  static String dateTimeId(DateTime? date) {
    if (date == null) return '-';
    try {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(date.toLocal());
    } catch (_) {
      return DateFormat('d MMM yyyy, HH:mm').format(date.toLocal());
    }
  }

  /// Short date
  static String dateShort(DateTime? date) {
    if (date == null) return '-';
    try {
      return DateFormat('d MMM', 'id_ID').format(date.toLocal());
    } catch (_) {
      return DateFormat('d MMM').format(date.toLocal());
    }
  }

  /// Relative time (e.g., "2 jam lalu")
  static String timeAgo(DateTime? date) {
    if (date == null) return '-';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return dateId(date);
  }

  /// Format bytes to human readable
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get time-based greeting (matching web admin)
  static String getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  /// Format full Indonesian date with weekday
  static String fullDateId(DateTime? date) {
    if (date == null) return '-';
    try {
      return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(date.toLocal());
    } catch (_) {
      return DateFormat('EEEE, d MMMM yyyy').format(date.toLocal());
    }
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
