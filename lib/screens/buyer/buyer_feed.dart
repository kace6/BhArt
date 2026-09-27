import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bhart/services/supabase_service.dart';
import 'package:bhart/theme/app_theme.dart';

class _Product {
  final String id;
  final String? userId;
  final String name;
  final String description;
  final num price;
  final String imageUrl;
  final String material;
  final bool isFallbackImage;
  final String artisanName;

  /// True for the built-in sample items shown when the catalog is empty.
  /// (Don't infer this from the id — real UUIDs can start with 'f' too.)
  final bool isFallback;

  _Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.material,
    required this.isFallbackImage,
    required this.artisanName,
    this.isFallback = false,
  });

  factory _Product.fromRow(Map<String, dynamic> row) {
    final metadata = row['metadata'] as Map<String, dynamic>?;
    final profile = row['profiles'] as Map<String, dynamic>?;
    return _Product(
      id: row['id'].toString(),
      userId: row['user_id']?.toString(),
      name: row['name'] ?? '',
      description: row['description'] ?? '',
      price: row['price'] ?? 0,
      imageUrl: row['image_url'] ?? '',
      material: row['material'] ?? '',
      isFallbackImage: metadata?['is_fallback_image'] == true,
      artisanName: profile?['display_name'] ?? 'Artisan',
    );
  }
}

const _categories = ['All', 'Terracotta', 'Jewelry', 'Textiles', 'Bamboo', 'Leather', 'Wood', 'Metal', 'Other'];

final _fallbackItems = [
  _Product(
    id: 'sample-1',
    userId: null,
    isFallback: true,
    name: 'Silver Filigree Earrings',
    description: 'Intricately designed silver earrings handcrafted by artisans in Odisha.',
    price: 1200,
    imageUrl: 'https://images.unsplash.com/photo-1535632066927-ab7c9ab60908?w=500&auto=format&fit=crop&q=60',
    material: 'Silver Jewelry',
    isFallbackImage: false,
    artisanName: 'Odisha Silver Co-op',
  ),
  _Product(
    id: 'sample-2',
    userId: null,
    isFallback: true,
    name: 'Woven Bamboo Basket',
    description: 'Durable and eco-friendly storage basket made from Assam bamboo.',
    price: 450,
    imageUrl: 'https://images.unsplash.com/photo-1601614050212-32a265147814?w=500&auto=format&fit=crop&q=60',
    material: 'Bamboo',
    isFallbackImage: false,
    artisanName: 'Assam Weavers',
  ),
  _Product(
    id: 'sample-3',
    userId: null,
    isFallback: true,
    name: 'Hand-painted Terracotta Vase',
    description: 'Traditional Warli art painted on a fired clay vase.',
    price: 850,
    imageUrl: 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=500&auto=format&fit=crop&q=60',
    material: 'Terracotta',
    isFallbackImage: false,
    artisanName: 'Ramu Kaka',
  ),
];

/// Port of buyer/page.tsx.
class BuyerFeed extends StatefulWidget {
  const BuyerFeed({super.key});

  @override
  State<BuyerFeed> createState() => _BuyerFeedState();
}

class _BuyerFeedState extends State<BuyerFeed> {
  final _searchController = TextEditingController();
  List<_Product> _products = [];
  bool _loading = true;
  bool _loadFailed = false;
  String _activeCategory = 'All';
  String _query = '';
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final rows = await SupabaseService.fetchProducts();
      if (!mounted) return;
      setState(() => _products = rows.map(_Product.fromRow).toList());
    } catch (_) {
      if (!mounted) return;
      // Don't silently swap in sample items on failure — that looks like real data.
      setState(() {
        _products = [];
        _loadFailed = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteProduct(_Product product) async {
    if (product.isFallback) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SupabaseService.deleteProduct(product.id);
      if (!mounted) return;
      setState(() => _products.removeWhere((p) => p.id == product.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete item: $e')));
      }
    }
  }

  void _addToCart(_Product product) {
    setState(() => _cartCount++);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
      ));
  }

  // Sample items are only for an empty-but-healthy catalog.
  List<_Product> get _displayProducts => (_products.isNotEmpty || _loadFailed) ? _products : _fallbackItems;

  List<_Product> get _filtered {
    final knownCats = _categories.where((c) => c != 'All' && c != 'Other').map((c) => c.toLowerCase()).toList();
    return _displayProducts.where((p) {
      final mat = p.material.toLowerCase();

      final categoryOk = switch (_activeCategory) {
        'All' => true,
        'Other' => !knownCats.any((c) => mat.contains(c)),
        _ => mat.contains(_activeCategory.toLowerCase()),
      };
      if (!categoryOk) return false;

      if (_query.isEmpty) return true;
      final haystack = '${p.name} ${p.material} ${p.description} ${p.artisanName}'.toLowerCase();
      return haystack.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.weaverBlue,
        elevation: 1,
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => context.go('/')),
        title: const Text('BhArt Market'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Badge(
                isLabelVisible: _cartCount > 0,
                label: Text('$_cartCount'),
                child: const Icon(Icons.shopping_cart),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  hintText: 'Search handicrafts...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final active = cat == _activeCategory;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: active,
                      onSelected: (_) => setState(() => _activeCategory = cat),
                      selectedColor: AppColors.terracotta,
                      labelStyle: TextStyle(color: active ? Colors.white : AppColors.gray500, fontWeight: FontWeight.w500),
                      backgroundColor: Colors.white,
                      shape: StadiumBorder(side: BorderSide(color: active ? AppColors.terracotta : const Color(0xFFE5E7EB))),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
              else if (_loadFailed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Text("Couldn't load items. Check your connection and try again.",
                            textAlign: TextAlign.center, style: TextStyle(color: AppColors.gray500)),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _fetchProducts, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      _query.isEmpty ? 'No items found in this category.' : 'No items match your search.',
                      style: const TextStyle(color: AppColors.gray400),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final product = _filtered[i];
                    // Only the artisan who published an item sees the delete button.
                    final canDelete = !product.isFallback && product.userId != null && product.userId == currentUserId;
                    return _ProductCard(
                      product: product,
                      canDelete: canDelete,
                      onDelete: _deleteProduct,
                      onAddToCart: _addToCart,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _Product product;
  final bool canDelete;
  final void Function(_Product product) onDelete;
  final void Function(_Product product) onAddToCart;

  const _ProductCard({
    required this.product,
    required this.canDelete,
    required this.onDelete,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.gray100, child: _buildImage()),
                if (canDelete)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withAlpha(204),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.gray400),
                        onPressed: () => onDelete(product),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.gray900)),
                    ),
                    Text('₹${product.price}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.terracotta)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 10, color: AppColors.gray500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('By ${product.artisanName}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => onAddToCart(product),
                    style: TextButton.styleFrom(backgroundColor: AppColors.gray50, foregroundColor: AppColors.weaverBlue),
                    child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    // Newly published items use a Storage URL. Older rows may still hold a
    // base64 data-URL, so keep supporting that too.
    if (product.imageUrl.startsWith('data:image')) {
      final base64Part = product.imageUrl.split(',').last;
      try {
        return Image.memory(base64Decode(base64Part), fit: product.isFallbackImage ? BoxFit.contain : BoxFit.cover);
      } catch (_) {
        return const Icon(Icons.image, color: AppColors.gray400);
      }
    }
    if (product.imageUrl.isEmpty) return const Icon(Icons.image, color: AppColors.gray400);
    return Image.network(
      product.imageUrl,
      fit: product.isFallbackImage ? BoxFit.contain : BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.image, color: AppColors.gray400),
    );
  }
}