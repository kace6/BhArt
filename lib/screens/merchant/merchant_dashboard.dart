import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bhart/models/parsed_product.dart';
import 'package:bhart/services/ai_service.dart';
import 'package:bhart/services/supabase_service.dart';
import 'package:bhart/theme/app_theme.dart';
import 'package:bhart/widgets/image_capture_widget.dart';
import 'package:bhart/widgets/audio_recorder_widget.dart';
import 'package:bhart/widgets/catalog_card.dart';

enum _Step { photo, loading, catalog, voiceEdit }

/// Port of merchant/page.tsx. Same step-machine: photo -> loading -> catalog
/// <-> voice-edit, then publish -> /buyer. Wrapped with the same header/
/// sign-out/alerts nav that merchant/layout.tsx provided.
class MerchantDashboard extends StatefulWidget {
  const MerchantDashboard({super.key});

  @override
  State<MerchantDashboard> createState() => _MerchantDashboardState();
}

class _MerchantDashboardState extends State<MerchantDashboard> {
  _Step _step = _Step.photo;
  ParsedProduct? _product;
  Uint8List? _imageBytes;
  bool _isImageFallback = false;
  int? _fairPrice;
  bool _isPublishing = false;
  String? _aiNotice;

  Future<void> _handleImageCapture(Uint8List bytes) async {
    setState(() {
      _product = null;
      _imageBytes = null;
      _fairPrice = null;
      _isImageFallback = false;
      _aiNotice = null;
      _step = _Step.loading;
    });

    try {
      final base64Image = base64Encode(bytes);
      final result = await AiService.identifyProductFromImage(base64Image);
      final parsed = result.product;
      if (parsed == null) throw Exception('Failed to parse image');

      final notice = result.isMockData
          ? '⚠️ Gemini AI सर्वर व्यस्त है। डेमो डेटा दिखाया गया है। कुछ देर बाद पुनः प्रयास करें। '
              '(AI server is busy. Showing demo data. Please retry in a minute.)'
          : null;

      final results = await Future.wait([
        AiService.estimateFairPrice(name: parsed.name, material: parsed.material, userSuggestedPrice: parsed.userSuggestedPrice),
        AiService.processImage(bytes),
      ]);

      final price = results[0] as int?;
      final imageResult = results[1] as ({List<int> bytes, bool isFallback});

      if (!mounted) return;
      setState(() {
        _aiNotice = notice;
        _product = parsed;
        _fairPrice = price;
        _imageBytes = Uint8List.fromList(imageResult.bytes);
        _isImageFallback = imageResult.isFallback;
        _step = _Step.catalog;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _step = _Step.photo);
      await _showAlert('Error processing image: $e');
    }
  }

  Future<void> _handleVoiceEdit(String audioFilePath) async {
    setState(() => _step = _Step.loading);
    try {
      if (_product != null) {
        final updated = await AiService.parseAudioWithGroq(audioFilePath, existingProduct: _product);
        if (updated != null) {
          final price = await AiService.estimateFairPrice(
              name: updated.name, material: updated.material, userSuggestedPrice: updated.userSuggestedPrice);
          if (!mounted) return;
          setState(() {
            _product = updated;
            if (price != null) _fairPrice = price;
          });
        }
      }
      if (mounted) setState(() => _step = _Step.catalog);
    } catch (e) {
      if (mounted) {
        setState(() => _step = _Step.catalog);
        await _showAlert('Error updating details.');
      }
    } finally {
      try {
        await File(audioFilePath).delete();
      } catch (_) {}
    }
  }

  Future<void> _handlePublish(int finalPrice) async {
    if (_product == null || _imageBytes == null) return;
    if (finalPrice <= 0) {
      await _showAlert('कृपया सही कीमत डालें (Please enter a valid price)');
      return;
    }

    setState(() => _isPublishing = true);
    try {
      // Upload the photo to Supabase Storage and store only its public URL.
      // If the upload fails (e.g. bucket not created yet) fall back to the old
      // behaviour of embedding a base64 data-URL so publishing still works.
      final uploadedUrl = await SupabaseService.uploadProductImage(_imageBytes!);
      final imageUrl = uploadedUrl ??
          'data:${SupabaseService.imageMimeType(_imageBytes!)};base64,${base64Encode(_imageBytes!)}';

      await SupabaseService.publishProduct(
        name: _product!.name,
        material: _product!.material,
        descriptionEn: _product!.descriptionEn,
        descriptionHi: _product!.descriptionHi,
        price: finalPrice,
        imageUrl: imageUrl,
        stockQuantity: _product!.quantity,
        isFallbackImage: _isImageFallback,
      );

      if (!mounted) return;
      // Wait for the dialog to be dismissed before navigating away.
      await _showAlert('कैटलॉग में सफलतापूर्वक जोड़ा गया! (Successfully added to catalog!)');
      if (mounted) context.go('/buyer');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      await _showAlert('Failed to publish: $e');
    }
  }

  Future<void> _showAlert(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(content: Text(message), actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK')),
      ]),
    );
  }

  Future<void> _signOut() async {
    await SupabaseService.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.khadi,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => context.go('/')),
        title: const Text('आर्टिसन मोड'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign Out', onPressed: _signOut),
          IconButton(
            icon: const Icon(Icons.trending_up),
            tooltip: 'Market alerts',
            onPressed: () => context.go('/merchant/alerts'),
          ),
        ],
      ),
      body: Center(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(24), child: _buildStep()))),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.photo:
        return Column(
          children: [
            const SizedBox(height: 24),
            const Text('चरण 1: फोटो लें (Step 1: Take Photo)',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.weaverBlue)),
            const SizedBox(height: 32),
            ImageCaptureWidget(onImageCaptured: _handleImageCapture),
            const SizedBox(height: 32),
            const Text(
              'उत्पाद की एक स्पष्ट तस्वीर लें। हमारा AI बाकी काम करेगा।\n(Take a clear photo of the product. Our AI will do the rest.)',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray500),
            ),
          ],
        );

      case _Step.loading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 60),
            SizedBox(width: 64, height: 64, child: CircularProgressIndicator(color: AppColors.terracotta, strokeWidth: 4)),
            SizedBox(height: 24),
            Text('AI विश्लेषण कर रहा है...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.weaverBlue)),
            SizedBox(height: 8),
            Text('Identifying product & cleaning image', style: TextStyle(color: AppColors.gray500)),
          ],
        );

      case _Step.catalog:
        if (_product == null || _imageBytes == null) return const SizedBox.shrink();
        return Column(
          children: [
            if (_aiNotice != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(_aiNotice!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF92400E), fontSize: 13)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _aiNotice = null;
                        _step = _Step.photo;
                      }),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber500),
                      child: const Text('🔄 पुनः प्रयास करें (Retry)'),
                    ),
                  ],
                ),
              ),
            CatalogCard(
              product: _product!,
              imageBytes: _imageBytes!,
              isImageFallback: _isImageFallback,
              fairPrice: _fairPrice,
              isPublishing: _isPublishing,
              onPublish: _handlePublish,
              onEditAudio: () => setState(() => _step = _Step.voiceEdit),
            ),
          ],
        );

      case _Step.voiceEdit:
        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _step = _Step.catalog),
                icon: const Icon(Icons.arrow_back, color: AppColors.weaverBlue),
                label: const Text('वापस (Back)', style: TextStyle(color: AppColors.weaverBlue, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('आप क्या बदलना चाहते हैं?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.weaverBlue)),
            const Text('(What do you want to change?)', style: TextStyle(color: AppColors.gray500)),
            const SizedBox(height: 32),
            AudioRecorderWidget(onAudioRecorded: _handleVoiceEdit),
          ],
        );
    }
  }
}