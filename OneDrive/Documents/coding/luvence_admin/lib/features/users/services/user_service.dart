import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class UserService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Get all user profiles
  static Future<List<Map<String, dynamic>>> getUsers({String? search, String? roleFilter}) async {
    var query = _client.from('profiles').select().order('created_at', ascending: false);
    if (roleFilter != null && roleFilter.isNotEmpty) {
      query = _client.from('profiles').select().eq('role', roleFilter).order('created_at', ascending: false);
    }
    final response = await query;
    List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(response);

    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      results = results.where((u) {
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final username = (u['username'] ?? '').toString().toLowerCase();
        return name.contains(s) || email.contains(s) || username.contains(s);
      }).toList();
    }
    return results;
  }

  /// Get single user profile
  static Future<Map<String, dynamic>> getUserById(String id) async {
    return await _client.from('profiles').select().eq('id', id).single();
  }

  /// Update user profile fields
  static Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  /// Update user role
  static Future<void> updateRole(String userId, String newRole) async {
    await _client.from('profiles').update({'role': newRole}).eq('id', userId);
  }

  /// Get transactions for a specific user
  static Future<List<Map<String, dynamic>>> getUserTransactions(String userId) async {
    final response = await _client.from('transactions').select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update user password (admin action via RPC)
  static Future<void> updatePassword(String userId, String newPassword) async {
    await _client.rpc('admin_update_password', params: {
      'target_user_id': userId,
      'new_password': newPassword,
    });
  }
}
