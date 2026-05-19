import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class ProductService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Get all products
  static Future<List<Map<String, dynamic>>> getProducts({bool? isActive}) async {
    var query = _client.from('products').select().order('created_at', ascending: false);
    if (isActive != null) {
      query = _client.from('products').select().eq('is_active', isActive).order('created_at', ascending: false);
    }
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Get single product
  static Future<Map<String, dynamic>> getProductById(int id) async {
    return await _client.from('products').select().eq('id', id).single();
  }

  /// Create product
  static Future<void> createProduct(Map<String, dynamic> data) async {
    await _client.from('products').insert(data);
  }

  /// Update product
  static Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('products').update(data).eq('id', id);
  }

  /// Delete product
  static Future<void> deleteProduct(int id) async {
    await _client.from('products').delete().eq('id', id);
  }

  /// Toggle product active status
  static Future<void> toggleActive(int id, bool isActive) async {
    await _client.from('products').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Upload image to Supabase Storage
  static Future<String> uploadImage(File file, String fileName) async {
    final bytes = await file.readAsBytes();
    final path = 'products/$fileName';
    await _client.storage.from('product-images').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return _client.storage.from('product-images').getPublicUrl(path);
  }
}
