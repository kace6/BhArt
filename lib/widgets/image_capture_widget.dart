import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bhart/theme/app_theme.dart';

/// Port of ImageCapture.tsx. image_picker handles both the native camera
/// and gallery/web-fallback case in one API, so there's no need for the
/// Capacitor.isNativePlatform() branch the original had.
class ImageCaptureWidget extends StatelessWidget {
  final void Function(Uint8List bytes) onImageCaptured;

  const ImageCaptureWidget({super.key, required this.onImageCaptured});

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    onImageCaptured(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fixed 384px caused overflow on phones narrower than ~430dp. This now
      // grows to fill the available width and only caps out at 384 on wide
      // screens.
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 384),
      child: Row(
        children: [
          Expanded(
            child: _CaptureButton(
              icon: Icons.camera_alt,
              color: AppColors.weaverBlue,
              titleHi: 'फोटो लें',
              titleEn: 'Camera',
              onTap: () => _pick(ImageSource.camera),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _CaptureButton(
              icon: Icons.image,
              color: AppColors.terracotta,
              titleHi: 'गैलरी',
              titleEn: 'Gallery',
              onTap: () => _pick(ImageSource.gallery),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titleHi;
  final String titleEn;
  final VoidCallback onTap;

  const _CaptureButton({
    required this.icon,
    required this.color,
    required this.titleHi,
    required this.titleEn,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(titleHi, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(titleEn, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}