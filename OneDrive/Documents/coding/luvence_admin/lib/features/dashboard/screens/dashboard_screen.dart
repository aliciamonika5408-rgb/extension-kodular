import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/transactions/services/transaction_service.dart';
import '../../../features/products/services/product_service.dart';
import '../../../features/users/services/user_service.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/recent_orders.dart';
import '../widgets/category_donut.dart';
import '../../products/screens/product_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic> _revenueStats = {};
  Map<String, dynamic>? _profile;
  String _role = 'admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ProductService.getProducts(),
        UserService.getUsers(),
        TransactionService.getTransactions(limit: 10),
        TransactionService.getRevenueStats(),
        AuthService.getProfile(),
      ]);
      if (mounted) {
        setState(() {
          _products = results[0] as List<Map<String, dynamic>>;
          _users = results[1] as List<Map<String, dynamic>>;
          _transactions = results[2] as List<Map<String, dynamic>>;
          _revenueStats = results[3] as Map<String, dynamic>;
          _profile = results[4] as Map<String, dynamic>?;
          _role = (_profile?['role'] as String?) ?? 'admin';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = Formatters.getTimeGreeting();
    final displayName = _profile?['full_name'] ?? _profile?['username'] ?? 'Admin';

    return Scaffold(
      backgroundColor: LuvColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: LuvColors.accent,
          backgroundColor: LuvColors.surface,
          onRefresh: _loadData,
          child: _loading
              ? _buildShimmer()
              : _error != null
                  ? _buildError()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        // Header Banner
                        _buildHeader(greeting, displayName),
                        const SizedBox(height: 20),

                        // Stat Cards
                        _buildStatCards(),
                        const SizedBox(height: 20),

                        // Stock Alerts
                        if (_stockAlerts.isNotEmpty) ...[
                          _buildStockAlerts(),
                          const SizedBox(height: 16),
                        ],

                        // Revenue
                        _buildRevenue(),
                        const SizedBox(height: 16),

                        // Recent Orders + Category Donut
                        RecentOrders(transactions: _transactions.take(5).toList()),
                        const SizedBox(height: 16),
                        CategoryDonut(products: _products),
                        const SizedBox(height: 16),

                        // Quote
                        _buildQuote(),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.cloud_off_rounded, size: 64, color: LuvColors.textMuted),
        const SizedBox(height: 20),
        Text('Gagal Memuat Data', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
        const SizedBox(height: 8),
        Text(_error ?? '', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: LuvColors.textMuted)),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: LuvColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String greeting, String displayName) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      gradientColors: [const Color(0x0FD4A574), const Color(0x088B5CF6)],
      child: Stack(
        children: [
          Positioned(top: -30, right: -10,
            child: Container(width: 120, height: 120, decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [LuvColors.accent.withValues(alpha: 0.06), Colors.transparent]),
            )),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('✦ $greeting ✦', style: TextStyle(fontSize: 10, letterSpacing: 3, color: LuvColors.accent, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  _buildRoleBadge(_role),
                ],
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: '$displayName, ', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic, color: LuvColors.textPrimary)),
                  TextSpan(text: 'Welcome Back', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
                ]),
              ),
              const SizedBox(height: 8),
              Text('LUVENCE ID • ${Formatters.fullDateId(DateTime.now())}', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  /// Collect all variants with stock issues
  List<Map<String, dynamic>> get _stockAlerts {
    final alerts = <Map<String, dynamic>>[];
    for (final p in _products) {
      final sizes = p['sizes'] as List?;
      if (sizes == null) continue;
      for (final s in sizes) {
        final stock = (s['stock'] ?? 0) as int;
        if (stock <= 3) {
          alerts.add({
            'product': p['name'] ?? '-',
            'image': p['image'] ?? '',
            'volume': s['volume'] ?? '?',
            'stock': stock,
            'productData': p,
          });
        }
      }
    }
    // Sort: out-of-stock first, then by stock ascending
    alerts.sort((a, b) => (a['stock'] as int).compareTo(b['stock'] as int));
    return alerts;
  }

  Widget _buildStatCards() {
    final outOfStockVariants = _stockAlerts.where((a) => a['stock'] == 0).length;
    final lowStockVariants = _stockAlerts.where((a) => a['stock'] > 0).length;

    final stats = [
      {'label': 'Total Produk', 'value': '${_products.length}', 'icon': Icons.inventory_2_outlined, 'color': LuvColors.accent},
      {'label': 'Produk Aktif', 'value': '${_products.where((p) => p['is_active'] == true).length}', 'icon': Icons.check_circle_outline, 'color': LuvColors.success},
      {'label': 'Total User', 'value': '${_users.length}', 'icon': Icons.people_outline, 'color': LuvColors.info},
      {'label': 'Stok Habis', 'value': '$outOfStockVariants', 'icon': Icons.error_outline_rounded, 'color': LuvColors.error},
      {'label': 'Stok Tipis', 'value': '$lowStockVariants', 'icon': Icons.warning_amber_rounded, 'color': LuvColors.warning},
    ];

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => StatCard(
          label: stats[i]['label'] as String,
          value: stats[i]['value'] as String,
          icon: stats[i]['icon'] as IconData,
          color: stats[i]['color'] as Color,
          index: i,
        ),
      ),
    );
  }

  Widget _buildRevenue() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text('📊 ', style: TextStyle(fontSize: 16)),
                Text('PENDAPATAN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: LuvColors.accent, letterSpacing: 1)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: LuvColors.accentBg, borderRadius: BorderRadius.circular(10)),
                child: Text(Formatters.currency(_revenueStats['total'] ?? 0), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: LuvColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Revenue stats in equal columns with dividers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(child: _revenueStat('Hari ini', _revenueStats['today'] ?? 0)),
                  VerticalDivider(width: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.06)),
                  Expanded(child: _revenueStat('7 Hari', _revenueStats['week'] ?? 0)),
                  VerticalDivider(width: 1, thickness: 1, color: Colors.white.withValues(alpha: 0.06)),
                  Expanded(child: _revenueStat('30 Hari', _revenueStats['month'] ?? 0)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: RevenueChart(dailyRevenue: (_revenueStats['daily'] as Map<String, int>?) ?? {}),
          ),
        ],
      ),
    );
  }

  Widget _revenueStat(String label, dynamic rawValue) {
    final value = (rawValue is int) ? rawValue : (int.tryParse(rawValue.toString()) ?? 0);
    // Shorten large numbers: 14.000.000 → 14jt, 2.720.000 → 2,7jt
    String display;
    if (value >= 1000000) {
      final millions = value / 1000000;
      display = 'Rp ${millions % 1 == 0 ? millions.toInt().toString() : millions.toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      display = 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    } else {
      display = Formatters.currency(value);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: LuvColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(display, style: const TextStyle(fontSize: 13, color: LuvColors.textPrimary, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color badgeColor;
    IconData badgeIcon;
    switch (role.toLowerCase()) {
      case 'developer':
        badgeColor = const Color(0xFF22D3EE); // cyan — same as Users screen
        badgeIcon = Icons.code_rounded;
        break;
      case 'owner':
        badgeColor = const Color(0xFFE879F9); // pink — same as Users screen
        badgeIcon = Icons.stars_rounded;
        break;
      case 'admin':
        badgeColor = LuvColors.error; // red — same as Users screen
        badgeIcon = Icons.shield_rounded;
        break;
      default: // user
        badgeColor = LuvColors.textMuted;
        badgeIcon = Icons.person_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 9, color: badgeColor),
          const SizedBox(width: 4),
          Text(role.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: badgeColor, letterSpacing: 0.8)),
        ],
      ),
    );
  }

  Widget _buildStockAlerts() {
    final outOfStock = _stockAlerts.where((a) => a['stock'] == 0).toList();
    final lowStock = _stockAlerts.where((a) => a['stock'] > 0).toList();

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: LuvColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notification_important_rounded, size: 16, color: LuvColors.error),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('PERINGATAN STOK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: LuvColors.textPrimary, letterSpacing: 1))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: LuvColors.errorBg, borderRadius: BorderRadius.circular(6)),
              child: Text('${_stockAlerts.length} ITEM', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: LuvColors.error)),
            ),
          ]),
          const SizedBox(height: 12),

          // Out of stock items
          if (outOfStock.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: LuvColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('🚨 HABIS (${outOfStock.length})', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: LuvColors.error, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 6),
            ...outOfStock.take(5).map((a) => _stockAlertRow(a, isOut: true)),
            if (outOfStock.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('  +${outOfStock.length - 5} lainnya...', style: TextStyle(fontSize: 10, color: LuvColors.textMuted, fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 10),
          ],

          // Low stock items
          if (lowStock.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('⚠️ STOK TIPIS (${lowStock.length})', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B), letterSpacing: 0.5)),
            ),
            const SizedBox(height: 6),
            ...lowStock.take(5).map((a) => _stockAlertRow(a, isOut: false)),
            if (lowStock.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('  +${lowStock.length - 5} lainnya...', style: TextStyle(fontSize: 10, color: LuvColors.textMuted, fontStyle: FontStyle.italic)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _stockAlertRow(Map<String, dynamic> alert, {required bool isOut}) {
    final stock = alert['stock'] as int;
    final productData = alert['productData'] as Map<String, dynamic>?;
    return GestureDetector(
      onTap: productData != null ? () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: productData)));
        _loadData();
      } : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            // Mini image
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 28, height: 28,
                child: (alert['image'] as String).startsWith('http')
                    ? CachedNetworkImage(imageUrl: alert['image'], fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: LuvColors.surface))
                    : Container(color: LuvColors.surface),
              ),
            ),
            const SizedBox(width: 8),
            // Product name + volume
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert['product'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: LuvColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(alert['volume'] as String, style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
                ],
              ),
            ),
            // Stock badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isOut ? LuvColors.error.withValues(alpha: 0.1) : const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isOut ? LuvColors.error.withValues(alpha: 0.2) : const Color(0xFFF59E0B).withValues(alpha: 0.2)),
              ),
              child: Text(
                isOut ? 'HABIS' : 'Sisa $stock',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isOut ? LuvColors.error : const Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: LuvColors.textMuted.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuote() {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Text('🌹', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(
            '"Parfum adalah seni tak kasat mata yang membekas di hati setiap orang."',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(fontSize: 13, fontStyle: FontStyle.italic, color: LuvColors.textSecondary, height: 1.7),
          ),
          const SizedBox(height: 10),
          Text('— LUVENCE ID', style: TextStyle(fontSize: 10, color: LuvColors.accent.withValues(alpha: 0.5), fontWeight: FontWeight.w600, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ShimmerLoading.card(height: 160),
        const SizedBox(height: 16),
        ShimmerLoading.statRow(),
        const SizedBox(height: 16),
        ShimmerLoading.card(height: 260),
        const SizedBox(height: 16),
        ShimmerLoading.card(height: 200),
      ],
    );
  }
}
