import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/colors.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/transactions/screens/transactions_screen.dart';
import '../features/products/screens/products_screen.dart';
import '../features/users/screens/users_screen.dart';
import '../features/promos/screens/promos_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import '../features/notifications/services/notification_service.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  int _currentIndex = 0;
  int _newTxCount = 0;
  StreamSubscription? _txSub;

  // Toast state
  String? _toastMessage;
  String? _toastSub;
  Timer? _toastTimer;

  final _pages = const [
    DashboardScreen(),
    TransactionsScreen(),
    ProductsScreen(),
    UsersScreen(),
    PromosScreen(),
    SettingsScreen(),
  ];

  final _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Transaksi'),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Produk'),
    _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'User'),
    _NavItem(icon: Icons.discount_outlined, activeIcon: Icons.discount_rounded, label: 'Promo'),
    _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Pengaturan'),
  ];

  @override
  void initState() {
    super.initState();
    _startRealtimeListener();
  }

  @override
  void dispose() {
    _txSub?.cancel();
    _toastTimer?.cancel();
    RealtimeNotificationService.stop();
    super.dispose();
  }

  void _startRealtimeListener() async {
    await RealtimeNotificationService.initialize();
    RealtimeNotificationService.start();
    _txSub = RealtimeNotificationService.onNewTransaction.listen((tx) {
      if (!mounted) return;

      try {
        // Vibrate
        HapticFeedback.heavyImpact();

        // Increment badge (only if not on Transaksi tab)
        if (_currentIndex != 1) {
          setState(() => _newTxCount++);
        }

        // Show toast
        final orderId = (tx['order_id'] ?? 'Pesanan Baru').toString();
        final customer = (tx['customer_username'] ?? tx['customer_email'] ?? '').toString();
        final amount = tx['gross_amount'];

        // Safe items parsing
        List itemsList = [];
        final rawItems = tx['items'];
        if (rawItems is List) {
          itemsList = rawItems;
        } else if (rawItems is String) {
          try { itemsList = jsonDecode(rawItems) as List; } catch (_) {}
        }

        // Get product names
        String productInfo = '';
        if (itemsList.isNotEmpty) {
          final names = itemsList.map((item) {
            if (item is Map) {
              return (item['name'] ?? item['product_name'] ?? '').toString();
            }
            return '';
          }).where((s) => s.isNotEmpty).toList();
          if (names.isNotEmpty) {
            productInfo = names.length > 2
                ? '${names.take(2).join(", ")} +${names.length - 2} lainnya'
                : names.join(", ");
          }
        }

        String amountStr = '';
        if (amount != null) {
          final n = int.tryParse(amount.toString()) ?? 0;
          amountStr = 'Rp ${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
        }

        final subtitle = [
          if (customer.isNotEmpty) customer,
          if (productInfo.isNotEmpty) productInfo,
          if (amountStr.isNotEmpty) amountStr,
        ].join(' • ');

        _showToast('🛒 Pesanan Baru Masuk!', subtitle.isNotEmpty ? subtitle : orderId);
      } catch (_) {
        _showToast('🛒 Pesanan Baru Masuk!', tx['order_id']?.toString() ?? 'Lihat detail');
      }
    });
  }



  void _showToast(String msg, String sub) {
    _toastTimer?.cancel();
    setState(() { _toastMessage = msg; _toastSub = sub; });
    _toastTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() { _toastMessage = null; _toastSub = null; });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFF080A10),
      ),
      child: Scaffold(
        backgroundColor: LuvColors.background,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
            // Toast overlay
            if (_toastMessage != null) _buildNotifToast(),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildNotifToast() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16, right: 16,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, -20 * (1 - v)), child: child),
        ),
        child: GestureDetector(
          onTap: () {
            // Navigate to transactions
            setState(() { _currentIndex = 1; _newTxCount = 0; _toastMessage = null; _toastSub = null; });
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2332), Color(0xFF0F1520)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LuvColors.accent.withValues(alpha: 0.25)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8)),
                  BoxShadow(color: LuvColors.accent.withValues(alpha: 0.08), blurRadius: 30),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [LuvColors.accent.withValues(alpha: 0.2), LuvColors.accent.withValues(alpha: 0.05)]),
                      border: Border.all(color: LuvColors.accent.withValues(alpha: 0.15)),
                    ),
                    child: const Center(child: Text('💰', style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_toastMessage!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LuvColors.accent)),
                    if (_toastSub != null) ...[
                      const SizedBox(height: 2),
                      Text(_toastSub!, style: TextStyle(fontSize: 11, color: LuvColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ])),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: LuvColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LuvColors.accent.withValues(alpha: 0.2)),
                    ),
                    child: const Text('Lihat', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: LuvColors.accent)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF080A10),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = _currentIndex == i;
              final showBadge = i == 1 && _newTxCount > 0;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _currentIndex = i;
                      if (i == 1) _newTxCount = 0; // Clear badge on tap
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? LuvColors.accent.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                selected ? item.activeIcon : item.icon,
                                size: 20,
                                color: selected ? LuvColors.accent : LuvColors.textMuted,
                              ),
                            ),
                            // Red notification badge
                            if (showBadge)
                              Positioned(
                                right: 2, top: 0,
                                child: Container(
                                  width: 16, height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: LuvColors.error,
                                    border: Border.all(color: const Color(0xFF080A10), width: 2),
                                    boxShadow: [BoxShadow(color: LuvColors.error.withValues(alpha: 0.5), blurRadius: 6)],
                                  ),
                                  child: Center(
                                    child: Text('$_newTxCount', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? LuvColors.accent : LuvColors.textMuted,
                            letterSpacing: selected ? 0.3 : 0,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
