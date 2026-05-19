import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/services/transaction_service.dart';
import '../services/user_service.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String myRole;
  const UserDetailScreen({super.key, required this.user, this.myRole = 'admin'});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late Map<String, dynamic> _user;
  List<Map<String, dynamic>> _transactions = [];
  bool _loadingTx = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _user = Map.from(widget.user);
    _loadTransactions();
  }

  /// Permission logic:
  /// owner/developer → can edit anyone & change roles
  /// admin → can only edit 'user' role accounts, cannot change roles
  bool get _canEdit {
    final targetRole = (_user['role'] ?? 'user').toString();
    if (widget.myRole == 'owner' || widget.myRole == 'developer') return true;
    if (widget.myRole == 'admin' && targetRole == 'user') return true;
    return false;
  }

  bool get _canChangeRole {
    return widget.myRole == 'owner' || widget.myRole == 'developer';
  }

  List<String> get _availableRoles {
    if (widget.myRole == 'owner') return ['user', 'admin', 'developer', 'owner'];
    if (widget.myRole == 'developer') return ['user', 'admin', 'developer'];
    return [];
  }

  Future<void> _loadTransactions() async {
    try {
      final userId = _user['id'];
      if (userId != null) {
        final data = await TransactionService.getTransactions();
        if (mounted) setState(() {
          _transactions = data.where((t) => t['user_id'] == userId).toList();
          _loadingTx = false;
        });
      } else {
        if (mounted) setState(() => _loadingTx = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTx = false);
    }
  }

  Future<void> _changeRole(String newRole) async {
    final userId = _user['id']?.toString();
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuvColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Role?', style: TextStyle(color: LuvColors.textPrimary, fontSize: 16)),
        content: Text(
          'Ubah role ${_user['full_name'] ?? _user['email']} menjadi "${newRole.toUpperCase()}"?',
          style: TextStyle(color: LuvColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Ubah', style: TextStyle(color: LuvColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await UserService.updateRole(userId, newRole);
      HapticFeedback.mediumImpact();
      setState(() { _user['role'] = newRole; _saving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Role berhasil diubah ke ${newRole.toUpperCase()}'),
          backgroundColor: LuvColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal ubah role: $e'),
          backgroundColor: LuvColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: (_user['full_name'] ?? '').toString());
    final emailCtrl = TextEditingController(text: (_user['email'] ?? '').toString());
    final usernameCtrl = TextEditingController(text: (_user['username'] ?? '').toString());
    final phoneCtrl = TextEditingController(text: (_user['phone'] ?? '').toString());
    final passwordCtrl = TextEditingController();

    // Address fields
    final address = _user['address'] as Map<String, dynamic>? ?? {};
    final provinceCtrl = TextEditingController(text: (address['province'] ?? '').toString());
    final cityCtrl = TextEditingController(text: (address['city'] ?? '').toString());
    final districtCtrl = TextEditingController(text: (address['district'] ?? '').toString());
    final villageCtrl = TextEditingController(text: (address['village'] ?? '').toString());
    final addressCtrl = TextEditingController(text: (address['detail'] ?? '').toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool obscurePass = true;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1520),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0x30D4A574))),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Edit Profil', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Ubah data pengguna ini', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // ── Informasi Akun ──
                    _editSectionLabel('INFORMASI AKUN'),
                    const SizedBox(height: 8),
                    _editField('Nama Lengkap', nameCtrl, Icons.person_outline),
                    const SizedBox(height: 10),
                    _editField('Email', emailCtrl, Icons.email_outlined, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 10),
                    _editField('Username', usernameCtrl, Icons.alternate_email),
                    const SizedBox(height: 10),
                    _editField('No. WhatsApp', phoneCtrl, Icons.phone_outlined, keyboard: TextInputType.phone),
                    const SizedBox(height: 10),
                    // Password with eye toggle
                    _editField(
                      'Password Baru (kosongkan jika tidak diubah)',
                      passwordCtrl,
                      Icons.lock_outline,
                      obscure: obscurePass,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 20,
                          color: LuvColors.accent.withValues(alpha: 0.5),
                        ),
                        onPressed: () => setModalState(() => obscurePass = !obscurePass),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Alamat ──
                    _editSectionLabel('ALAMAT PENGIRIMAN'),
                    const SizedBox(height: 8),
                    _editField('Provinsi', provinceCtrl, Icons.map_outlined),
                    const SizedBox(height: 10),
                    _editField('Kota/Kabupaten', cityCtrl, Icons.location_city_outlined),
                    const SizedBox(height: 10),
                    _editField('Kecamatan', districtCtrl, Icons.holiday_village_outlined),
                    const SizedBox(height: 10),
                    _editField('Kelurahan', villageCtrl, Icons.home_outlined),
                    const SizedBox(height: 10),
                    _editField('Alamat Lengkap', addressCtrl, Icons.pin_drop_outlined, maxLines: 2),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _saving = true);
                try {
                  final updates = <String, dynamic>{};
                  if (nameCtrl.text.isNotEmpty) updates['full_name'] = nameCtrl.text;
                  if (emailCtrl.text.isNotEmpty) updates['email'] = emailCtrl.text;
                  if (usernameCtrl.text.isNotEmpty) updates['username'] = usernameCtrl.text;
                  if (phoneCtrl.text.isNotEmpty) updates['phone'] = phoneCtrl.text;

                  // Build address object
                  final newAddress = <String, dynamic>{};
                  if (provinceCtrl.text.isNotEmpty) newAddress['province'] = provinceCtrl.text;
                  if (cityCtrl.text.isNotEmpty) newAddress['city'] = cityCtrl.text;
                  if (districtCtrl.text.isNotEmpty) newAddress['district'] = districtCtrl.text;
                  if (villageCtrl.text.isNotEmpty) newAddress['village'] = villageCtrl.text;
                  if (addressCtrl.text.isNotEmpty) newAddress['detail'] = addressCtrl.text;
                  if (newAddress.isNotEmpty) updates['address'] = newAddress;

                  // Handle password change
                  if (passwordCtrl.text.isNotEmpty && passwordCtrl.text.length >= 6) {
                    await UserService.updatePassword(_user['id'].toString(), passwordCtrl.text);
                  }

                  if (updates.isNotEmpty) {
                    await UserService.updateUser(_user['id'].toString(), updates);
                    setState(() { _user.addAll(updates); _saving = false; });
                    HapticFeedback.mediumImpact();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Profil berhasil diperbarui ✅'),
                        backgroundColor: LuvColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));
                    }
                  } else {
                    setState(() => _saving = false);
                  }
                } catch (e) {
                  setState(() => _saving = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: LuvColors.error, behavior: SnackBarBehavior.floating));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LuvColors.accent,
                foregroundColor: const Color(0xFF0B0D14),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ),
        ]),
          ),
        );
      },
    );
  }

  Widget _editSectionLabel(String label) {
    return Row(children: [
      Container(width: 3, height: 14, decoration: BoxDecoration(color: LuvColors.accent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: LuvColors.accent.withValues(alpha: 0.6))),
    ]);
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboard, bool obscure = false, int maxLines = 1, Widget? suffixIcon}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: LuvColors.textMuted),
        prefixIcon: Icon(icon, size: 18, color: LuvColors.accent.withValues(alpha: 0.5)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: LuvColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: LuvColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: LuvColors.accent.withValues(alpha: 0.4))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (_user['full_name'] ?? _user['username'] ?? 'Unnamed').toString();
    final email = (_user['email'] ?? '-').toString();
    final phone = (_user['phone'] ?? '').toString();
    final role = (_user['role'] ?? 'user').toString();
    final username = (_user['username'] ?? '-').toString();
    final created = DateTime.tryParse((_user['created_at'] ?? '').toString());
    final address = _user['address'] as Map<String, dynamic>?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: LuvColors.background,
      appBar: AppBar(
        backgroundColor: LuvColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: LuvColors.accent), onPressed: () => Navigator.pop(context)),
        title: const Text('Detail Pengguna', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20, color: LuvColors.accent),
              onPressed: _saving ? null : _showEditDialog,
            ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator(color: LuvColors.accent, strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                // ── Profile Card ──
                GlassCard(
                  padding: const EdgeInsets.all(28),
                  child: Column(children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [_roleColor(role).withValues(alpha: 0.2), LuvColors.glassMedium]),
                        border: Border.all(color: _roleColor(role).withValues(alpha: 0.3), width: 2.5),
                        boxShadow: [BoxShadow(color: _roleColor(role).withValues(alpha: 0.15), blurRadius: 20)],
                      ),
                      child: Center(child: Text(initial, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _roleColor(role)))),
                    ),
                    const SizedBox(height: 16),
                    Text(name, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: LuvColors.textPrimary), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text('@$username', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LuvColors.accent, letterSpacing: 0.5)),
                    const SizedBox(height: 12),

                    // Role badge — tappable if can change role
                    GestureDetector(
                      onTap: _canChangeRole ? () => _showRolePicker(role) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: _roleColor(role).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _roleColor(role).withValues(alpha: 0.2)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_roleIcon(role), size: 12, color: _roleColor(role)),
                          const SizedBox(width: 6),
                          Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _roleColor(role), letterSpacing: 1.2)),
                          if (_canChangeRole) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.edit_rounded, size: 10, color: _roleColor(role).withValues(alpha: 0.5)),
                          ],
                        ]),
                      ),
                    ),
                    if (_canChangeRole)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('Ketuk untuk ubah role', style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
                      ),
                    const SizedBox(height: 6),
                    if (created != null)
                      Text('Bergabung ${Formatters.dateId(created)}', style: TextStyle(fontSize: 10, color: LuvColors.textMuted)),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Info Pribadi ──
                _buildSection(icon: '👤', title: 'Informasi Pribadi', children: [
                  _infoTile(Icons.person_outline_rounded, 'NAMA LENGKAP', name),
                  _infoTile(Icons.email_outlined, 'EMAIL', email),
                  _infoTile(Icons.alternate_email, 'USERNAME', '@$username'),
                  _infoTile(Icons.phone_outlined, 'WHATSAPP', phone.isNotEmpty ? phone : 'Belum diisi'),
                ]),
                const SizedBox(height: 16),

                // ── Alamat ──
                _buildSection(icon: '📦', title: 'Detail Pengiriman', children: [
                  if (address != null && address.isNotEmpty) ...[
                    _infoTile(Icons.map_outlined, 'PROVINSI', _addr(address, 'province')),
                    _infoTile(Icons.location_city_outlined, 'KOTA', _addr(address, 'city')),
                    _infoTile(Icons.holiday_village_outlined, 'KECAMATAN', _addr(address, 'district')),
                    _infoTile(Icons.home_outlined, 'KELURAHAN', _addr(address, 'village')),
                    if ((address['detail'] ?? '').toString().isNotEmpty)
                      _infoTile(Icons.pin_drop_outlined, 'ALAMAT', address['detail'].toString()),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: LuvColors.warningBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Text('📭', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Text('Alamat belum diisi', style: TextStyle(fontSize: 12, color: LuvColors.warning)),
                      ]),
                    ),
                ]),
                const SizedBox(height: 16),

                // ── Transaksi ──
                _buildSection(icon: '🧾', title: 'Riwayat Transaksi (${_transactions.length})', children: [
                  if (_loadingTx)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2, color: LuvColors.accent)))
                  else if (_transactions.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Belum ada transaksi', style: TextStyle(fontSize: 12, color: LuvColors.textMuted))))
                  else
                    ..._transactions.map((t) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black.withValues(alpha: 0.15)),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['order_id'] ?? '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: LuvColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text(Formatters.dateShort(DateTime.tryParse(t['created_at'] ?? '')), style: TextStyle(fontSize: 10, color: LuvColors.textMuted)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(Formatters.currency(t['gross_amount']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: LuvColors.accent)),
                          const SizedBox(height: 3),
                          StatusBadge.payment(t['status'] ?? 'pending'),
                        ]),
                      ]),
                    )),
                ]),
              ],
            ),
    );
  }

  void _showRolePicker(String currentRole) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1520),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Pilih Role', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
          const SizedBox(height: 16),
          ..._availableRoles.map((r) => GestureDetector(
            onTap: () { Navigator.pop(ctx); if (r != currentRole) _changeRole(r); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: r == currentRole ? _roleColor(r).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                border: Border.all(color: r == currentRole ? _roleColor(r).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.04)),
              ),
              child: Row(children: [
                Icon(_roleIcon(r), size: 18, color: _roleColor(r)),
                const SizedBox(width: 12),
                Expanded(child: Text(r.toUpperCase(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _roleColor(r), letterSpacing: 0.8))),
                if (r == currentRole) Icon(Icons.check_circle_rounded, size: 18, color: _roleColor(r)),
              ]),
            ),
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Helpers ──
  String _addr(Map<String, dynamic> a, String k) => (a[k] ?? '').toString().isNotEmpty ? a[k].toString() : 'Belum diisi';

  Color _roleColor(String r) {
    switch (r) { case 'owner': return const Color(0xFFE879F9); case 'developer': return const Color(0xFF22D3EE); case 'admin': return LuvColors.error; default: return LuvColors.accent; }
  }

  IconData _roleIcon(String r) {
    switch (r) { case 'owner': return Icons.stars_rounded; case 'developer': return Icons.code_rounded; case 'admin': return Icons.shield_rounded; default: return Icons.person_rounded; }
  }

  Widget _buildSection({required String icon, required String title, required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(begin: Alignment(-0.8, -1), end: Alignment(0.8, 1), colors: [Color(0x801E2332), Color(0x990A0C14)]),
            border: Border.all(color: LuvColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
            ]),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.black.withValues(alpha: 0.15)),
      child: Row(children: [
        Icon(icon, size: 15, color: LuvColors.accent.withValues(alpha: 0.4)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: LuvColors.accent.withValues(alpha: 0.35))),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: value == 'Belum diisi' ? LuvColors.textMuted : LuvColors.textPrimary)),
        ])),
      ]),
    );
  }
}
