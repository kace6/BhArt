import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bhart/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.khadi,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'BhArt',
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.terracotta),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connecting rural artisans with the world.',
                  style: TextStyle(fontSize: 18, color: AppColors.weaverBlue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _HomeTile(
                  icon: Icons.storefront,
                  color: AppColors.terracotta,
                  titleHi: 'मैं बेचना चाहता हूँ',
                  titleEn: '(I want to Sell)',
                  onTap: () => context.go('/merchant'),
                ),
                const SizedBox(height: 24),
                _HomeTile(
                  icon: Icons.shopping_bag,
                  color: AppColors.weaverBlue,
                  titleHi: 'मैं खरीदना चाहता हूँ',
                  titleEn: '(I want to Buy)',
                  onTap: () => context.go('/buyer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String titleHi;
  final String titleEn;
  final VoidCallback onTap;

  const _HomeTile({
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
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 384),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(icon, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(titleHi,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(titleEn, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}