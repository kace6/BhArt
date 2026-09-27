import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bhart/models/parsed_product.dart';
import 'package:bhart/theme/app_theme.dart';

class CatalogCard extends StatefulWidget {
  final ParsedProduct product;
  final Uint8List imageBytes;
  final bool isImageFallback;
  final int? fairPrice;
  final void Function(int price) onPublish;
  final VoidCallback? onEditAudio;
  final bool isPublishing;

  const CatalogCard({
    super.key,
    required this.product,
    required this.imageBytes,
    required this.isImageFallback,
    required this.fairPrice,
    required this.onPublish,
    required this.isPublishing,
    this.onEditAudio,
  });

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: _initialPriceText());
  }

  @override
  void didUpdateWidget(covariant CatalogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // This State is reused across steps (photo -> catalog -> voice-edit ->
    // catalog), so a new price from a voice edit was never reaching the
    // field: initState only ran once, the first time the card appeared.
    // Re-seed the field whenever a genuinely new product/price arrives.
    if (oldWidget.product != widget.product || oldWidget.fairPrice != widget.fairPrice) {
      _priceController.text = _initialPriceText();
    }
  }

  // userSuggestedPrice can be a double (e.g. 150.0). Round it to a whole
  // rupee amount so the field never shows "150.0", which int.tryParse
  // rejects (that used to publish the item at ₹0).
  String _initialPriceText() {
    final initial = widget.product.userSuggestedPrice?.round() ?? widget.fairPrice;
    return initial?.toString() ?? '';
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _handlePublishTap() {
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('कृपया सही कीमत डालें (Please enter a valid price)')));
      return;
    }
    widget.onPublish(price);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Fixed 400px caused overflow on phones narrower than ~430dp. This now
      // grows to fill the available width and only caps out at 400 on wide
      // screens/tablets.
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: widget.isImageFallback ? const Color(0xFFFFF3E0) : AppColors.gray100,
                  child: Image.memory(
                    widget.imageBytes,
                    fit: widget.isImageFallback ? BoxFit.contain : BoxFit.cover,
                  ),
                ),
                if (widget.isImageFallback)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('AI Studio Background', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.product.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.weaverBlue)),
                if (widget.product.nameHi.isNotEmpty)
                  Text(widget.product.nameHi,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.terracotta)),
                const SizedBox(height: 4),
                Text('${widget.product.material} • Qty: ${widget.product.quantity}',
                    style: const TextStyle(color: AppColors.gray500, fontSize: 13)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    border: Border.all(color: AppColors.gray100),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('आपकी कीमत (Your Price)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray400)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('₹', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.weaverBlue)),
                          Expanded(
                            child: TextField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.weaverBlue),
                              decoration: const InputDecoration(border: InputBorder.none, isDense: true, filled: false),
                            ),
                          ),
                        ],
                      ),
                      if (widget.fairPrice != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.trending_up, size: 16, color: AppColors.green600),
                              const SizedBox(width: 8),
                              Text('Suggested Fair Price: ₹${widget.fairPrice}',
                                  style: const TextStyle(color: AppColors.green600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Hindi Description',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray400)),
                Text(widget.product.descriptionHi, style: const TextStyle(fontSize: 13, color: AppColors.weaverBlue)),
                const SizedBox(height: 12),
                const Text('English Description',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gray400)),
                Text(widget.product.descriptionEn, style: const TextStyle(fontSize: 13, color: AppColors.weaverBlue)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (widget.onEditAudio != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Material(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(AppRadius.button),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                            onTap: widget.onEditAudio,
                            child: const Padding(
                              padding: EdgeInsets.all(16),
                              child: Icon(Icons.mic, color: AppColors.weaverBlue),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.isPublishing ? null : _handlePublishTap,
                        child: widget.isPublishing
                            ? const Text('प्रकाशित हो रहा है...')
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle),
                                  SizedBox(width: 8),
                                  Text('बाज़ार में प्रकाशित करें'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}