import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/services/auth_service.dart';
import '../services/user_service.dart';
import 'user_detail_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  String _search = '';
  String _roleFilter = 'all';
  String _myRole = 'admin';
  String? _myId;
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
      final role = await AuthService.getRole();
      final myId = await AuthService.getCurrentUserId();
      final data = await UserService.getUsers();
      if (mounted) setState(() {
        _users = data;
        _myRole = role;
        _myId = myId;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    var list = List<Map<String, dynamic>>.from(_users);
    if (_roleFilter != 'all') list = list.where((u) => u['role'] == _roleFilter).toList();
    if (_search.isNotEmpty) {
      final s = _search.toLowerCase();
      list = list.where((u) {
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final username = (u['username'] ?? '').toString().toLowerCase();
        return name.contains(s) || email.contains(s) || username.contains(s);
      }).toList();
    }
    _filtered = list;
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner': return const Color(0xFFE879F9);
      case 'developer': return const Color(0xFF22D3EE);
      case 'admin': return LuvColors.error;
      default: return LuvColors.textMuted;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'owner': return Icons.stars_rounded;
      case 'developer': return Icons.code_rounded;
      case 'admin': return Icons.shield_rounded;
      default: return Icons.person_rounded;
    }
  }

  int _countRole(String role) => _users.where((u) => u['role'] == role).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuvColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
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
                    child: const Center(child: Text('👥', style: TextStyle(fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Pengguna', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
                    Text('Daftar customer & admin', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: LuvColors.infoBg, borderRadius: BorderRadius.circular(10)),
                    child: Text('${_users.length} USER', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: LuvColors.info)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Role Stats Row ──
            if (!_loading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _miniStat('👤', 'User', _countRole('user'), LuvColors.textMuted),
                    const SizedBox(width: 8),
                    _miniStat('🛡️', 'Admin', _countRole('admin'), LuvColors.error),
                    const SizedBox(width: 8),
                    _miniStat('💻', 'Dev', _countRole('developer'), const Color(0xFF22D3EE)),
                    const SizedBox(width: 8),
                    _miniStat('⭐', 'Owner', _countRole('owner'), const Color(0xFFE879F9)),
                  ],
                ),
              ),
            if (!_loading) const SizedBox(height: 14),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(hintText: 'Cari nama, email, username...', prefixIcon: Icon(Icons.search, size: 18, color: LuvColors.textMuted)),
                onChanged: (v) { setState(() { _search = v; _applyFilter(); }); },
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter Chips ──
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _chip('Semua', 'all'),
                  const SizedBox(width: 8),
                  _chip('User', 'user'),
                  const SizedBox(width: 8),
                  _chip('Admin', 'admin'),
                  const SizedBox(width: 8),
                  _chip('Developer', 'developer'),
                  const SizedBox(width: 8),
                  _chip('Owner', 'owner'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── User List ──
            Expanded(
              child: _loading
                  ? Padding(padding: const EdgeInsets.all(20), child: ShimmerLoading.list())
                  : _filtered.isEmpty
                      ? const EmptyState(icon: '👤', title: 'Tidak ada pengguna', subtitle: 'Belum ada pengguna yang sesuai filter')
                      : RefreshIndicator(
                          color: LuvColors.accent,
                          backgroundColor: LuvColors.surface,
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              try {
                                return _buildUserCard(_filtered[i], i);
                              } catch (e) {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String emoji, String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.6))),
        ]),
      ),
    );
  }

  Widget _chip(String label, String key) {
    final selected = _roleFilter == key;
    return GestureDetector(
      onTap: () { setState(() { _roleFilter = key; _applyFilter(); }); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: [LuvColors.accent.withValues(alpha: 0.15), LuvColors.accent.withValues(alpha: 0.05)]) : null,
          color: selected ? null : LuvColors.glassLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? LuvColors.accent.withValues(alpha: 0.3) : LuvColors.borderLight),
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? LuvColors.accent : LuvColors.textMuted))),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u, int index) {
    final name = (u['full_name'] ?? u['username'] ?? 'Unnamed').toString();
    final email = (u['email'] ?? '-').toString();
    final role = (u['role'] ?? 'user').toString();
    final created = DateTime.tryParse((u['created_at'] ?? '').toString());
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final color = _roleColor(role);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child)),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => UserDetailScreen(user: u, myRole: _myRole, myId: _myId),
          ));
          _loadData(); // Refresh after returning
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LuvColors.cardGradient,
            border: Border.all(color: LuvColors.border),
          ),
          child: Stack(
            children: [
              // Role accent line
              Positioned(
                left: 0, top: 10, bottom: 10,
                child: Container(width: 3, decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: color.withValues(alpha: 0.4))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    // Avatar with role color
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [color.withValues(alpha: 0.15), LuvColors.glassMedium]),
                        border: Border.all(color: color.withValues(alpha: 0.25)),
                      ),
                      child: Center(child: Text(initial, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: LuvColors.textPrimary)),
                        const SizedBox(height: 3),
                        Text(email, style: TextStyle(fontSize: 11, color: LuvColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    )),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withValues(alpha: 0.15)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_roleIcon(role), size: 10, color: color),
                            const SizedBox(width: 4),
                            Text(role.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Text(created != null ? Formatters.dateShort(created) : '-', style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
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
