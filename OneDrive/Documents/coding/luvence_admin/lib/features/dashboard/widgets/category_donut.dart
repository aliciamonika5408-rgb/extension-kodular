import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';

class CategoryDonut extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const CategoryDonut({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final activeCount = products.where((p) => p['is_active'] == true).length;
    final inactiveCount = products.where((p) => p['is_active'] != true).length;
    final outOfStock = products.where((p) {
      final sizes = p['sizes'] as List?;
      return sizes != null && sizes.any((s) => (s['stock'] ?? 1) == 0);
    }).length;
    final inStock = products.where((p) {
      final sizes = p['sizes'] as List?;
      return sizes == null || sizes.every((s) => (s['stock'] ?? 1) > 0);
    }).length;

    final categories = <_Cat>[
      if (activeCount > 0) _Cat('Produk Aktif', activeCount, LuvColors.success),
      if (inactiveCount > 0) _Cat('Nonaktif', inactiveCount, LuvColors.error),
      if (inStock > 0) _Cat('Stok Tersedia', inStock, LuvColors.accent),
      if (outOfStock > 0) _Cat('Stok Habis', outOfStock, LuvColors.warning),
    ];
    final total = categories.fold<int>(0, (a, c) => a + c.count);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📊 ', style: TextStyle(fontSize: 16)),
            Text('RINGKASAN KATEGORI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: LuvColors.accent, letterSpacing: 1)),
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              // Donut
              SizedBox(
                width: 120, height: 120,
                child: CustomPaint(
                  painter: _DonutPainter(categories, total),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${products.length}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: LuvColors.textPrimary)),
                        Text('Produk', style: TextStyle(fontSize: 8, color: LuvColors.textMuted, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  children: categories.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: c.color)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(c.name, style: TextStyle(fontSize: 11, color: LuvColors.textSecondary, fontWeight: FontWeight.w500))),
                        Text('${total > 0 ? (c.count / total * 100).round() : 0}%', style: TextStyle(fontSize: 11, color: LuvColors.textMuted, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cat {
  final String name;
  final int count;
  final Color color;
  _Cat(this.name, this.count, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_Cat> categories;
  final int total;
  _DonutPainter(this.categories, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;
    var startAngle = -pi / 2;

    for (final cat in categories) {
      final sweep = total > 0 ? (cat.count / total) * 2 * pi : 0.0;
      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
