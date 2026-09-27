import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the same Supabase calls used in supabase.ts,
/// AuthForm.tsx, merchant/page.tsx and buyer/page.tsx.
class SupabaseService {
  SupabaseService._();
  static SupabaseClient get client => Supabase.instance.client;

  /// Public Storage bucket that holds product photos. Create it in the
  /// Supabase dashboard (Storage -> New bucket -> "product-images", public).
  static const productImageBucket = 'product-images';

  static Future<void> init() async {
    await Supabase.initialize(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  static Session? get currentSession => client.auth.currentSession;

  /// The signed-in user's id, or null when logged out.
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Mirrors AuthForm's handleSendOtp — same +91 formatting rule,
  /// same 9999999999 test-number carve-out.
  static Future<void> sendOtp(String rawPhone) async {
    final formatted = _formatPhone(rawPhone);
    await client.auth.signInWithOtp(phone: formatted);
  }

  static Future<AuthResponse> verifyOtp(String rawPhone, String otp) async {
    final formatted = _formatPhone(rawPhone);
    return client.auth.verifyOTP(phone: formatted, token: otp, type: OtpType.sms);
  }

  static String _formatPhone(String phone) {
    if (phone == '9999999999') return phone;
    if (phone.length == 10 && !phone.startsWith('+')) return '+91$phone';
    return phone;
  }

  static Future<void> signOut() => client.auth.signOut();

  /// PNG (remove.bg / RMBG output) vs JPEG (original photo fallback).
  static String imageMimeType(Uint8List bytes) {
    final isPng = bytes.length > 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    return isPng ? 'image/png' : 'image/jpeg';
  }

  /// Uploads the product photo to Supabase Storage and returns its public URL.
  /// Returns null on any failure (bucket missing, policy denied, offline...)
  /// so the caller can decide on a fallback.
  static Future<String?> uploadProductImage(Uint8List bytes) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final mime = imageMimeType(bytes);
    final ext = mime == 'image/png' ? 'png' : 'jpg';
    // Folder = user id, so a storage policy can restrict uploads to the owner.
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await client.storage.from(productImageBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
      return client.storage.from(productImageBucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Storage upload failed: $e');
      return null;
    }
  }

  /// Mirrors handlePublish in merchant/page.tsx.
  static Future<void> publishProduct({
    required String name,
    required String material,
    required String descriptionEn,
    required String descriptionHi,
    required int price,
    required String imageUrl,
    required int stockQuantity,
    required bool isFallbackImage,
  }) async {
    final session = client.auth.currentSession;
    if (session == null) throw Exception('Not logged in');
    if (price <= 0) throw Exception('Price must be greater than 0');

    await client.from('products').insert({
      'user_id': session.user.id,
      'name': name,
      'material': material,
      'description': descriptionEn,
      'price': price,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'metadata': {
        'desc_hi': descriptionHi,
        'is_fallback_image': isFallbackImage,
      },
    });
  }

  /// Mirrors fetchProducts in buyer/page.tsx.
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    final data = await client
        .from('products')
        .select('*, profiles(display_name)')
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Deletes a product only if it belongs to the signed-in user.
  /// Throws if nothing was deleted (not the owner, blocked by RLS, or already
  /// gone) so the UI never removes a card that still exists on the server.
  static Future<void> deleteProduct(String id) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('Not logged in');

    final deleted = await client
        .from('products')
        .delete()
        .eq('id', id)
        .eq('user_id', userId)
        .select('id');

    if ((deleted as List).isEmpty) {
      throw Exception('You can only delete your own items.');
    }
  }
}