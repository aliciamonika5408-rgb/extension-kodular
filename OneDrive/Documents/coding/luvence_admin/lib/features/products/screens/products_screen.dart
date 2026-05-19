import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../services/product_service.dart';
import 'product_form_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filtered = [];
  String _search = '';
  String _filter = 'all'; // all, active, inactive, low_stock
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await ProductService.getProducts();
      if (mounted) setState(() { _products = data; _applyFilter(); _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    var list = List<Map<String, dynamic>>.from(_products);
    if (_filter == 'active') list = list.where((p) => p['is_active'] == true).toList();
    if (_filter == 'inactive') list = list.where((p) => p['is_active'] != true).toList();
    if (_filter == 'low_stock') {
      list = list.where((p) {
        final sizes = p['sizes'] as List?;
        if (sizes == null || sizes.isEmpty) return false;
        return sizes.any((s) => (s['stock'] ?? 0) <= 3);
      }).toList();
    }
    if (_search.isNotEmpty) {
      final s = _search.toLowerCase();
      list = list.where((p) => (p['name'] ?? '').toString().toLowerCase().contains(s)).toList();
    }
    _filtered = list;
  }

  /// Count total variants with low/zero stock
  int get _lowStockCount {
    int count = 0;
    for (final p in _products) {
      final sizes = p['sizes'] as List?;
      if (sizes == null) continue;
      for (final s in sizes) {
        if ((s['stock'] ?? 0) <= 3) count++;
      }
    }
    return count;
  }

  Future<void> _deleteProduct(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuvColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: LuvColors.error, size: 22),
          SizedBox(width: 8),
          Text('Hapus Produk?', style: TextStyle(fontSize: 16)),
        ]),
        content: const Text('Produk yang dihapus tidak bisa dikembalikan. Pastikan tidak ada transaksi terkait.', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: LuvColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ProductService.deleteProduct(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil dihapus'), backgroundColor: LuvColors.success),
        );
      }
      _loadData();
    }
  }

  /// Get stock info summary for a product
  _StockInfo _getStockInfo(Map<String, dynamic> p) {
    final sizes = p['sizes'] as List?;
    if (sizes == null || sizes.isEmpty) return _StockInfo(total: 0, outOfStock: 0, lowStock: 0, variants: []);

    int total = 0, outOfStock = 0, lowStock = 0;
    final variants = <_VariantStock>[];

    for (final s in sizes) {
      final stock = (s['stock'] ?? 0) as int;
      final volume = s['volume'] ?? '?';
      total += stock;
      if (stock == 0) outOfStock++;
      else if (stock <= 3) lowStock++;
      variants.add(_VariantStock(volume: volume.toString(), stock: stock));
    }

    return _StockInfo(total: total, outOfStock: outOfStock, lowStock: lowStock, variants: variants);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuvColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));
          _loadData();
        },
        child: const Icon(Icons.add, size: 26),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('🧴', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Produk', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
                      Text('Kelola katalog parfum', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
                    ],
                  ),
                  const Spacer(),
                  if (_lowStockCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: LuvColors.errorBg, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.warning_amber_rounded, size: 12, color: LuvColors.error),
                        const SizedBox(width: 4),
                        Text('$_lowStockCount STOK ⚠️', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: LuvColors.error)),
                      ]),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: LuvColors.accentBg, borderRadius: BorderRadius.circular(10)),
                    child: Text('${_products.length} PRODUK', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: LuvColors.accent)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(hintText: 'Cari produk...', prefixIcon: Icon(Icons.search, size: 18, color: LuvColors.textMuted)),
                onChanged: (v) { setState(() { _search = v; _applyFilter(); }); },
              ),
            ),
            const SizedBox(height: 12),

            // Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('Semua', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Aktif', 'active'),
                    const SizedBox(width: 8),
                    _filterChip('Nonaktif', 'inactive'),
                    const SizedBox(width: 8),
                    _filterChip('⚠️ Stok Rendah', 'low_stock', alert: _lowStockCount > 0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Grid
            Expanded(
              child: _loading
                  ? Padding(padding: const EdgeInsets.all(20), child: ShimmerLoading.list(itemHeight: 200))
                  : _filtered.isEmpty
                      ? const EmptyState(icon: '🧴', title: 'Tidak ada produk', subtitle: 'Tambahkan produk baru untuk memulai')
                      : RefreshIndicator(
                          color: LuvColors.accent,
                          backgroundColor: LuvColors.surface,
                          onRefresh: _loadData,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.52,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildProductCard(_filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String key, {bool alert = false}) {
    final selected = _filter == key;
    return GestureDetector(
      onTap: () { setState(() { _filter = key; _applyFilter(); }); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (alert ? LuvColors.errorBg : LuvColors.accentBg)
              : LuvColors.glassLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? (alert ? LuvColors.error.withValues(alpha: 0.3) : LuvColors.accent.withValues(alpha: 0.3))
                : LuvColors.borderLight,
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: selected ? (alert ? LuvColors.error : LuvColors.accent) : LuvColors.textMuted,
        )),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final image = p['image'] ?? '';
    final name = p['name'] ?? '-';
    final price = p['price'] ?? '-';
    final isActive = p['is_active'] == true;
    final stockInfo = _getStockInfo(p);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)));
        _loadData();
      },
      onLongPress: () => _showActions(p),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LuvColors.cardGradient,
          border: Border.all(color: stockInfo.outOfStock > 0 ? LuvColors.error.withValues(alpha: 0.2) : LuvColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with stock overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: image.toString().startsWith('http')
                        ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover, placeholder: (_, __) => Container(color: LuvColors.surface), errorWidget: (_, __, ___) => _imagePlaceholder())
                        : _imagePlaceholder(),
                  ),
                ),
                // Stock alert overlay
                if (stockInfo.outOfStock > 0)
                  Positioned(top: 8, left: 8, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: LuvColors.error.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.warning_rounded, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('${stockInfo.outOfStock} HABIS', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  ))
                else if (stockInfo.lowStock > 0)
                  Positioned(top: 8, left: 8, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.inventory_2_outlined, size: 10, color: Colors.white),
                      const SizedBox(width: 3),
                      Text('STOK TIPIS', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  )),
                // Delete button
                Positioned(top: 8, right: 8, child: GestureDetector(
                  onTap: () => _deleteProduct(p['id'] as int),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 14, color: LuvColors.error),
                  ),
                )),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [StatusBadge.active(isActive)]),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: LuvColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(price.toString(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: LuvColors.accent)),
                    const Spacer(),
                    // Stock per variant
                    if (stockInfo.variants.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STOK VARIAN', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: LuvColors.textMuted, letterSpacing: 0.5)),
                            const SizedBox(height: 3),
                            Wrap(spacing: 4, runSpacing: 3, children: stockInfo.variants.map((v) {
                              final isOut = v.stock == 0;
                              final isLow = v.stock > 0 && v.stock <= 3;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOut
                                      ? LuvColors.error.withValues(alpha: 0.12)
                                      : isLow
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                          : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: isOut
                                      ? LuvColors.error.withValues(alpha: 0.2)
                                      : isLow
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                                          : Colors.white.withValues(alpha: 0.06)),
                                ),
                                child: Text(
                                  '${v.volume}: ${v.stock}',
                                  style: TextStyle(
                                    fontSize: 8, fontWeight: FontWeight.w700,
                                    color: isOut ? LuvColors.error : isLow ? const Color(0xFFF59E0B) : LuvColors.textMuted,
                                  ),
                                ),
                              );
                            }).toList()),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(color: LuvColors.surface, child: const Center(child: Icon(Icons.image_outlined, color: LuvColors.textMuted, size: 32)));
  }

  void _showActions(Map<String, dynamic> p) {
    final id = p['id'] as int;
    final isActive = p['is_active'] == true;
    showModalBottomSheet(
      context: context,
      backgroundColor: LuvColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: LuvColors.textMuted, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: LuvColors.accent),
              title: const Text('Edit Produk', style: TextStyle(color: LuvColors.textPrimary)),
              onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: p))).then((_) => _loadData()); },
            ),
            ListTile(
              leading: Icon(isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: LuvColors.warning),
              title: Text(isActive ? 'Nonaktifkan' : 'Aktifkan', style: const TextStyle(color: LuvColors.textPrimary)),
              onTap: () async { Navigator.pop(ctx); await ProductService.toggleActive(id, !isActive); _loadData(); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: LuvColors.error),
              title: const Text('Hapus Produk', style: TextStyle(color: LuvColors.error)),
              onTap: () { Navigator.pop(ctx); _deleteProduct(id); },
            ),
          ],
        ),
      ),
    );
  }
}

class _StockInfo {
  final int total;
  final int outOfStock;
  final int lowStock;
  final List<_VariantStock> variants;
  _StockInfo({required this.total, required this.outOfStock, required this.lowStock, required this.variants});
}

class _VariantStock {
  final String volume;
  final int stock;
  _VariantStock({required this.volume, required this.stock});
}
