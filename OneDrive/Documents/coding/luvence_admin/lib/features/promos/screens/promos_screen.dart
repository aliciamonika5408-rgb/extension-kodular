import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/formatters.dart';
import '../services/promo_service.dart';
import 'promo_form_screen.dart';

class PromosScreen extends StatefulWidget {
  const PromosScreen({super.key});

  @override
  State<PromosScreen> createState() => _PromosScreenState();
}

class _PromosScreenState extends State<PromosScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _promos = [];
  Map<String, int> _usageStats = {};
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PromoService.getPromos(),
        PromoService.getUsageStats(),
      ]);
      final promos = results[0] as List<Map<String, dynamic>>;
      final usage = results[1] as Map<String, int>;

      // Auto-deactivate promos that exceeded max usage
      for (final p in promos) {
        final maxUsage = p['max_usage'] ?? 0;
        if (maxUsage > 0 && p['is_active'] == true) {
          final code = (p['code'] as String).toLowerCase();
          final usedCount = usage[code] ?? 0;
          if (usedCount >= maxUsage) {
            // Auto-deactivate — quota exhausted
            await PromoService.toggleActive(p['id'], false);
            p['is_active'] = false;
          }
        }
      }

      if (mounted) setState(() { _promos = promos; _usageStats = usage; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _getUsedCount(String code) => _usageStats[code.toLowerCase()] ?? 0;

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    if (_filter == 'active') {
      return _promos.where((p) {
        if (p['is_active'] != true) return false;
        final endDate = DateTime.tryParse(p['end_date'] ?? '');
        if (endDate != null && endDate.isBefore(now)) return false;
        return true;
      }).toList();
    }
    if (_filter == 'inactive') {
      return _promos.where((p) {
        if (p['is_active'] != true) return true;
        final endDate = DateTime.tryParse(p['end_date'] ?? '');
        if (endDate != null && endDate.isBefore(now)) return true;
        return false;
      }).toList();
    }
    return _promos;
  }

  Future<void> _deletePromo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuvColors.surface,
        title: const Text('Hapus Promo?'),
        content: const Text('Promo yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: LuvColors.error))),
        ],
      ),
    );
    if (confirm == true) { await PromoService.deletePromo(id); _loadData(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuvColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoFormScreen()));
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
                  const Text('🎁', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Promo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
                    Text('Kelola kode promo & diskon', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: LuvColors.successBg, borderRadius: BorderRadius.circular(10)),
                    child: Text('${_promos.where((p) {
                      if (p['is_active'] != true) return false;
                      final ed = DateTime.tryParse(p['end_date'] ?? '');
                      return ed == null || ed.isAfter(DateTime.now());
                    }).length} AKTIF', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: LuvColors.success)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _chip('Semua', 'all'), const SizedBox(width: 8),
                _chip('Aktif', 'active'), const SizedBox(width: 8),
                _chip('Nonaktif', 'inactive'),
              ]),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _loading
                  ? Padding(padding: const EdgeInsets.all(20), child: ShimmerLoading.list())
                  : _filtered.isEmpty
                      ? const EmptyState(icon: '🎁', title: 'Tidak ada promo', subtitle: 'Buat promo baru untuk menarik pelanggan')
                      : RefreshIndicator(
                          color: LuvColors.accent,
                          backgroundColor: LuvColors.surface,
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildPromoCard(_filtered[i], i),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String key) {
    final selected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? LuvColors.accentBg : LuvColors.glassLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? LuvColors.accent.withValues(alpha: 0.3) : LuvColors.borderLight),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? LuvColors.accent : LuvColors.textMuted)),
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> p, int index) {
    final code = p['code'] ?? '-';
    final discount = p['discount'] ?? 0;
    final type = p['discount_type'] ?? 'fixed';
    final isActive = p['is_active'] == true;
    final minTx = p['min_transaction'] ?? 0;
    final maxDiscount = p['max_discount'] ?? 0;
    final maxUsage = p['max_usage'] ?? 0;
    final oncePerUser = p['once_per_user'] == true;
    final endDate = DateTime.tryParse(p['end_date'] ?? '');
    final isExpired = endDate != null && endDate.isBefore(DateTime.now());
    final usedCount = _getUsedCount(code);
    final isQuotaExhausted = maxUsage > 0 && usedCount >= maxUsage;

    // Determine status
    String statusLabel;
    Color statusColor;
    Color statusBg;
    if (isQuotaExhausted) {
      statusLabel = 'KUOTA HABIS';
      statusColor = const Color(0xFFF59E0B); // amber
      statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
    } else if (isExpired) {
      statusLabel = 'EXPIRED';
      statusColor = LuvColors.error;
      statusBg = LuvColors.errorBg;
    } else if (isActive) {
      statusLabel = 'AKTIF';
      statusColor = LuvColors.success;
      statusBg = LuvColors.successBg;
    } else {
      statusLabel = 'OFF';
      statusColor = LuvColors.textMuted;
      statusBg = LuvColors.glassLight;
    }

    // Type-specific styling
    Color typeColor;
    String typeLabel;
    String typeEmoji;
    String discountText;

    switch (type) {
      case 'free_shipping':
        typeColor = LuvColors.success;
        typeLabel = 'GRATIS ONGKIR';
        typeEmoji = '🚚';
        discountText = 'Gratis Ongkir';
        break;
      case 'percentage':
        typeColor = const Color(0xFF818CF8);
        typeLabel = 'PERSENTASE';
        typeEmoji = '📊';
        discountText = 'Diskon $discount%';
        break;
      default:
        typeColor = LuvColors.success;
        typeLabel = 'NOMINAL';
        typeEmoji = '💰';
        discountText = 'Diskon ${Formatters.currency(discount)}';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LuvColors.cardGradient,
          border: Border.all(color: isActive && !isQuotaExhausted ? typeColor.withValues(alpha: 0.15) : LuvColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Code + Status
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: LuvColors.accentBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: LuvColors.accent.withValues(alpha: 0.2)),
                          ),
                          child: Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: LuvColors.accent, letterSpacing: 1), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(statusLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: statusColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeColor.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(typeEmoji, style: const TextStyle(fontSize: 10)),
                        const SizedBox(width: 4),
                        Text(typeLabel, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: typeColor, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Discount Text
                  Text(discountText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
                  const SizedBox(height: 10),

                  // Usage Stats Bar
                  if (maxUsage > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pemakaian', style: TextStyle(fontSize: 9, color: LuvColors.textMuted, fontWeight: FontWeight.w600)),
                              Text(
                                '$usedCount / $maxUsage dipakai',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isQuotaExhausted ? const Color(0xFFF59E0B) : LuvColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: maxUsage > 0 ? (usedCount / maxUsage).clamp(0.0, 1.0) : 0,
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation(
                                isQuotaExhausted ? const Color(0xFFF59E0B) : LuvColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isQuotaExhausted ? '⚠️ Kuota telah habis' : 'Sisa ${maxUsage - usedCount} kuota',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isQuotaExhausted ? const Color(0xFFF59E0B) : LuvColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ] else if (usedCount > 0) ...[
                    // No quota limit but show usage count
                    _tag('Dipakai ${usedCount}× (unlimited)'),
                    const SizedBox(height: 8),
                  ],

                  // Tags
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    if (minTx > 0) _tag('Min. ${Formatters.currency(minTx)}'),
                    if (maxDiscount > 0 && ['percentage', 'free_shipping'].contains(type)) _tag('Max. ${Formatters.currency(maxDiscount)}'),
                    if (oncePerUser) _tag('1× per user'),
                    if (endDate != null) _tag('s/d ${Formatters.dateShort(endDate)}'),
                  ]),
                ],
              ),
            ),
            // Actions
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => PromoFormScreen(promo: p)));
                        _loadData();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.03)))),
                        child: const Center(child: Text('✏️ Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: LuvColors.textTertiary))),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _deletePromo(p['id']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Center(child: Text('🗑️ Hapus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: LuvColors.error))),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: LuvColors.glassMedium, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 9, color: LuvColors.textTertiary, fontWeight: FontWeight.w600)),
    );
  }
}
