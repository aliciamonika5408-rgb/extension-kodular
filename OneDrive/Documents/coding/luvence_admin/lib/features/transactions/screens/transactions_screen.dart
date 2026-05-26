import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/formatters.dart';
import '../services/transaction_service.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with TickerProviderStateMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _transactions = [];
  String _filter = 'all';
  String _search = '';
  final _searchController = TextEditingController();
  late AnimationController _headerAnim;

  final _filters = [
    {'key': 'all', 'label': 'Semua', 'icon': '📋'},
    {'key': 'need_ship', 'label': 'Perlu Dikirim', 'icon': '📦'},
    {'key': 'success', 'label': 'Berhasil', 'icon': '✅'},
    {'key': 'pending', 'label': 'Menunggu', 'icon': '⏳'},
    {'key': 'failed', 'label': 'Gagal', 'icon': '❌'},
  ];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final data = await TransactionService.getTransactions(
        statusFilter: _filter,
        search: _search,
      );
      if (mounted) setState(() { _transactions = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuvColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Premium Header ──
            FadeTransition(
              opacity: _headerAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(colors: [LuvColors.accent.withValues(alpha: 0.15), LuvColors.glassMedium]),
                        border: Border.all(color: LuvColors.accent.withValues(alpha: 0.1)),
                      ),
                      child: const Center(child: Text('📦', style: TextStyle(fontSize: 20))),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transaksi', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
                        Text('Kelola pesanan & pengiriman', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
                      ],
                    ),
                    const Spacer(),
                    // Live count badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: LuvColors.accentBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: LuvColors.accent.withValues(alpha: 0.15)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: LuvColors.accent, boxShadow: [BoxShadow(color: LuvColors.accent.withValues(alpha: 0.5), blurRadius: 6)])),
                        const SizedBox(width: 6),
                        Text('${_transactions.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: LuvColors.accent)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Search Bar with glass effect ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari order ID, email, username...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: LuvColors.textMuted),
                      suffixIcon: _search.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _search = '');
                                _loadData();
                              },
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                width: 24, height: 24,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
                                child: const Icon(Icons.close_rounded, size: 14, color: LuvColors.textMuted),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: LuvColors.glassLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: LuvColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: LuvColors.borderLight)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: LuvColors.accent.withValues(alpha: 0.3))),
                    ),
                    onSubmitted: (v) { setState(() => _search = v); _loadData(); },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Filter Chips ──
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final selected = _filter == f['key'];
                  return GestureDetector(
                    onTap: () { setState(() => _filter = f['key']!); _loadData(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(colors: [LuvColors.accent.withValues(alpha: 0.15), LuvColors.accent.withValues(alpha: 0.05)])
                            : null,
                        color: selected ? null : LuvColors.glassLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? LuvColors.accent.withValues(alpha: 0.35) : LuvColors.borderLight,
                          width: selected ? 1.5 : 1,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: LuvColors.accent.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(f['icon']!, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Text(f['label']!, style: TextStyle(
                            fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? LuvColors.accent : LuvColors.textMuted,
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Transaction List ──
            Expanded(
              child: _loading
                  ? Padding(padding: const EdgeInsets.all(20), child: ShimmerLoading.list())
                  : _transactions.isEmpty
                      ? const EmptyState(icon: '📭', title: 'Tidak ada transaksi', subtitle: 'Belum ada transaksi yang sesuai filter')
                      : RefreshIndicator(
                          color: LuvColors.accent,
                          backgroundColor: LuvColors.surface,
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            itemCount: _transactions.length,
                            itemBuilder: (_, i) => _buildTransactionCard(_transactions[i], i),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> t, int index) {
    final orderId = (t['order_id'] ?? '-').toString();
    final customer = (t['customer_username'] ?? t['customer_email'] ?? '-').toString();
    final amount = t['gross_amount'] ?? 0;
    final status = (t['status'] ?? 'pending').toString();
    final shipping = (t['shipping_status'] ?? 'dikemas').toString();
    final created = DateTime.tryParse((t['created_at'] ?? '').toString());
    final items = t['items'] as List? ?? [];
    final productItems = items.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      return !name.contains('ongkir') && !name.contains('shipping') && !name.contains('pengiriman');
    }).toList();

    // Status-specific accent color
    Color statusAccent;
    switch (status) {
      case 'success': statusAccent = LuvColors.success; break;
      case 'failed': statusAccent = LuvColors.error; break;
      default: statusAccent = LuvColors.warning;
    }

    // Avatar initial
    final initial = customer.isNotEmpty ? customer[0].toUpperCase() : '?';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 35)),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: _TapScaleCard(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transaction: t),
          ));
          _loadData();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment(-0.8, -1),
              end: Alignment(0.8, 1),
              colors: [Color(0x9912152C), Color(0x4D0C0E1C)],
            ),
            border: Border.all(
              color: Color(0x0FFFFFFF),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Status accent line at left with glow
              Positioned(
                left: 0, top: 10, bottom: 10,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        statusAccent.withValues(alpha: 0.8),
                        statusAccent.withValues(alpha: 0.2),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusAccent.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Order ID & Time
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 13, color: LuvColors.accent.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            orderId,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: LuvColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                          ),
                          child: Text(
                            created != null ? Formatters.timeAgo(created) : '-',
                            style: TextStyle(fontSize: 9, color: LuvColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Customer Avatar & Info
                    Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                statusAccent.withValues(alpha: 0.25),
                                statusAccent.withValues(alpha: 0.06),
                              ],
                            ),
                            border: Border.all(
                              color: statusAccent.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: statusAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LuvColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${productItems.length} produk',
                                style: TextStyle(fontSize: 10, color: LuvColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white.withValues(alpha: 0.12)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Divider
                    Container(height: 0.5, color: Colors.white.withValues(alpha: 0.05)),
                    const SizedBox(height: 12),

                    // Row 3: Amount & Status Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Gold gradient amount text
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [LuvColors.accentLight, LuvColors.accent],
                          ).createShader(bounds),
                          child: Text(
                            Formatters.currency(amount),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Row(children: [
                          StatusBadge.payment(status),
                          const SizedBox(width: 6),
                          StatusBadge.shipping(shipping),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight tap-scale wrapper
class _TapScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapScaleCard({required this.child, required this.onTap});

  @override
  State<_TapScaleCard> createState() => _TapScaleCardState();
}

class _TapScaleCardState extends State<_TapScaleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
