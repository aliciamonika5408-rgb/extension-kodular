import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../config/supabase_config.dart';

class ProductService {
  static SupabaseClient get _client => SupabaseConfig.client;

  /// Max file size: 5 MB
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

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

  /// Compress image to WebP format, max 1200px, quality 80
  static Future<Uint8List> _compressToWebP(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 1200,
      minHeight: 1200,
      quality: 80,
      format: CompressFormat.webp,
    );
    if (result == null) throw Exception('Gagal mengompres gambar');
    return Uint8List.fromList(result);
  }

  /// Upload image to Supabase Storage (auto-converts to WebP, max 5MB)
  static Future<String> uploadImage(File file, String fileName) async {
    // Check original file size
    final originalSize = await file.length();
    if (originalSize > maxFileSizeBytes) {
      throw Exception('Ukuran file terlalu besar (${(originalSize / 1024 / 1024).toStringAsFixed(1)} MB). Maksimal 5 MB.');
    }

    // Compress & convert to WebP
    final webpBytes = await _compressToWebP(file);

    // Double-check compressed size
    if (webpBytes.length > maxFileSizeBytes) {
      throw Exception('Gambar masih terlalu besar setelah dikompress (${(webpBytes.length / 1024 / 1024).toStringAsFixed(1)} MB). Coba gambar yang lebih kecil.');
    }

    // Always save as .webp
    final baseName = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
    final path = 'products/$baseName.webp';

    await _client.storage.from('product-images').uploadBinary(
      path,
      webpBytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/webp'),
    );
    return _client.storage.from('product-images').getPublicUrl(path);
  }
}
