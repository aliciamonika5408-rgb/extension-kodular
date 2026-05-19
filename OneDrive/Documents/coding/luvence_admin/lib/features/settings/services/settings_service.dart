import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class SettingsService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Get all settings as key-value map
  static Future<Map<String, String>> getSettings() async {
    final response = await _client.from('site_settings').select();
    final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(response);
    final Map<String, String> settings = {};
    for (final row in rows) {
      settings[row['key'] as String] = (row['value'] ?? '') as String;
    }
    return settings;
  }

  /// Save multiple settings (upsert)
  static Future<void> saveSettings(Map<String, String> values) async {
    for (final entry in values.entries) {
      await _client.from('site_settings').upsert(
        {'key': entry.key, 'value': entry.value},
        onConflict: 'key',
      );
    }
  }

  /// Toggle maintenance mode (instant apply)
  static Future<void> toggleMaintenance(bool enabled) async {
    await _client.from('site_settings').upsert(
      {'key': 'maintenance_mode', 'value': enabled ? 'true' : 'false'},
      onConflict: 'key',
    );
  }
}
