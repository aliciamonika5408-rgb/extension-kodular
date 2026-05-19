import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../services/settings_service.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

/// Auto-formats numbers with dot thousand separators (e.g. 45000 → 45.000)
class _ThousandSepFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    final formatted = _addDots(digits);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }

  static String _addDots(String digits) {
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// Format a raw value (string or int) into dotted format
  static String format(dynamic value) {
    final s = value?.toString() ?? '';
    final digits = s.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    return _addDots(digits);
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  Map<String, String> _values = {};
  String? _toast;
  String _toastType = 'success';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final data = await SettingsService.getSettings();
      if (mounted) setState(() { _values = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      _showToast('Gagal memuat pengaturan: $e', 'error');
    }
  }

  String _get(String key, [String fallback = '']) => _values[key] ?? fallback;
  void _set(String key, String val) => setState(() => _values[key] = val);

  Future<void> _saveAll() async {
    setState(() { _saving = true; _saved = false; });
    try {
      await SettingsService.saveSettings(_values);
      if (mounted) {
        setState(() { _saving = false; _saved = true; });
        _showToast('Pengaturan berhasil disimpan! ✅', 'success');
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _saved = false);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _showToast('Gagal menyimpan: $e', 'error');
    }
  }

  Future<void> _toggleMaintenance(bool enabled) async {
    _set('maintenance_mode', enabled ? 'true' : 'false');
    try {
      await SettingsService.toggleMaintenance(enabled);
      _showToast(
        enabled
            ? '🔴 Mode Maintenance AKTIF — Website tidak bisa diakses'
            : '🟢 Mode Maintenance NONAKTIF — Website kembali online',
        enabled ? 'warn' : 'success',
      );
    } catch (e) {
      _showToast('Gagal toggle maintenance: $e', 'error');
    }
  }

  void _showToast(String msg, String type) {
    setState(() { _toast = msg; _toastType = type; });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LuvColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar?', style: TextStyle(color: LuvColors.textPrimary)),
        content: const Text('Anda akan keluar dari admin dashboard.', style: TextStyle(color: LuvColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar', style: TextStyle(color: LuvColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMaintenance = _get('maintenance_mode', 'false') == 'true';

    return Scaffold(
      backgroundColor: LuvColors.background,
      body: SafeArea(
        child: _loading
            ? Padding(padding: const EdgeInsets.all(20), child: ShimmerLoading.list(count: 4, itemHeight: 120))
            : Stack(
                children: [
                  RefreshIndicator(
                    color: LuvColors.accent,
                    backgroundColor: LuvColors.surface,
                    onRefresh: _loadSettings,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      children: [
                        // Header
                        Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(colors: [LuvColors.accent.withValues(alpha: 0.15), LuvColors.glassMedium]),
                              border: Border.all(color: LuvColors.accent.withValues(alpha: 0.1)),
                            ),
                            child: const Center(child: Text('⚙️', style: TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Pengaturan', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
                            Text('Konfigurasi global website', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
                          ]),
                        ]),
                        const SizedBox(height: 20),

                        // Maintenance Banner
                        if (isMaintenance) _buildMaintenanceBanner(),

                        // Section 1: Website Info
                        _buildSection(
                          icon: '🌐',
                          title: 'Informasi Website',
                          desc: 'Nama, tagline, dan identitas brand',
                          accent: true,
                          children: [
                            _buildField('Nama Website', 'site_name', 'LUVENCE ID', icon: '🏷️'),
                            _buildField('Tagline', 'site_tagline', 'Luxury Perfume Collection', icon: '✨'),
                            _buildTextArea('Pesan Maintenance', 'maintenance_message', 'Kami sedang melakukan pemeliharaan...', icon: '🛠️'),
                          ],
                        ),

                        // Section 2: Contact
                        _buildSection(
                          icon: '📞',
                          title: 'Informasi Kontak',
                          desc: 'Nomor WhatsApp, email, dan lokasi',
                          children: [
                            _buildField('WhatsApp Admin', 'admin_whatsapp', '6281234567890', icon: '📱', keyboardType: TextInputType.phone),
                            _buildField('Email Kontak', 'contact_email', 'hello@luvence.id', icon: '📧', keyboardType: TextInputType.emailAddress),
                            _buildField('Alamat / Lokasi', 'contact_address', 'Surabaya, Indonesia', icon: '📍'),
                          ],
                        ),

                        // Section 3: Social Media
                        _buildSection(
                          icon: '📲',
                          title: 'Media Sosial',
                          desc: 'Link ke akun sosial media brand',
                          children: [
                            _buildField('Instagram', 'social_instagram', 'https://instagram.com/luvence.id', icon: '📸', keyboardType: TextInputType.url),
                            _buildField('TikTok', 'social_tiktok', 'https://tiktok.com/@luvence', icon: '🎵', keyboardType: TextInputType.url),
                          ],
                        ),

                        // Section 4: Shipping
                        _buildSection(
                          icon: '🚚',
                          title: 'Logistik & Ekspedisi',
                          desc: 'Atur tarif ongkir berdasarkan zona',
                          children: [
                            _buildZoneInfo(),
                            const SizedBox(height: 12),
                            _buildCurrencyField('Dalam Kota (Surabaya)', 'ship_kota', '10000', icon: '🏙️', hint: 'Area Surabaya & sekitarnya'),
                            _buildCurrencyField('Dalam Provinsi (Jawa Timur)', 'ship_prov', '15000', icon: '🗺️', hint: 'Malang, Kediri, Jember, dll'),
                            _buildCurrencyField('Pulau Jawa (Luar Jatim)', 'ship_jawa', '20000', icon: '🛤️', hint: 'Jakarta, Bandung, Semarang, Jogja'),
                            _buildCurrencyField('Sumatera & Bali', 'ship_sumatera_bali', '30000', icon: '🏝️', hint: 'Medan, Palembang, Bali, Lombok'),
                            _buildCurrencyField('Kalimantan & Sulawesi', 'ship_kalimantan_sulawesi', '40000', icon: '🌊', hint: 'Banjarmasin, Makassar, Manado'),
                            _buildCurrencyField('Indonesia Timur', 'ship_luar', '55000', icon: '✈️', hint: 'Papua, Maluku, NTT, dll'),
                          ],
                        ),

                        // Section 5: Maintenance Mode
                        _buildSection(
                          icon: '🔧',
                          title: 'Mode Maintenance',
                          desc: 'Kendalikan akses ke website utama',
                          children: [
                            _buildToggle(
                              'Mode Maintenance',
                              'Ketika aktif, pengunjung akan melihat halaman maintenance.',
                              isMaintenance,
                              (v) => _toggleMaintenance(v),
                              danger: true,
                            ),
                            _buildStatusIndicator(isMaintenance),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Logout Button
                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: LuvColors.errorBg,
                              border: Border.all(color: LuvColors.error.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded, size: 18, color: LuvColors.error),
                                const SizedBox(width: 8),
                                Text('Keluar dari Akun', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LuvColors.error)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                        Center(child: Text('© 2026 LUVENCE ID', style: TextStyle(fontSize: 9, color: LuvColors.textMuted, letterSpacing: 1))),
                      ],
                    ),
                  ),

                  // Toast
                  if (_toast != null) _buildToast(),

                  // Save FAB
                  Positioned(
                    bottom: 16, left: 20, right: 20,
                    child: _buildSaveButton(),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Builders ──────────────────────────────────────────────────────────────

  Widget _buildMaintenanceBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuvColors.errorBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuvColors.error.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Text('🔴', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Mode Maintenance Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: LuvColors.error)),
              const SizedBox(height: 2),
              Text('Website tidak dapat diakses pengunjung saat ini.', style: TextStyle(fontSize: 10, color: LuvColors.error.withValues(alpha: 0.6))),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String icon,
    required String title,
    required String desc,
    bool accent = false,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment(-0.8, -1), end: Alignment(0.8, 1),
                colors: [Color(0x801E2332), Color(0x990A0C14)],
              ),
              border: Border.all(color: LuvColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (accent)
                  Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(colors: [LuvColors.accent, LuvColors.accentDark, Colors.transparent]),
                    ),
                  ),
                Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: LuvColors.accentBg,
                      border: Border.all(color: LuvColors.accent.withValues(alpha: 0.15)),
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
                    Text(desc, style: TextStyle(fontSize: 10, color: LuvColors.textMuted)),
                  ])),
                ]),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String key, String hint, {String? icon, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[Text(icon, style: const TextStyle(fontSize: 11)), const SizedBox(width: 4)],
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: LuvColors.accent.withValues(alpha: 0.5))),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: _get(key)),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          keyboardType: keyboardType,
          onChanged: (v) => _values[key] = v,
          decoration: InputDecoration(hintText: hint),
        ),
      ]),
    );
  }

  Widget _buildTextArea(String label, String key, String hint, {String? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[Text(icon, style: const TextStyle(fontSize: 11)), const SizedBox(width: 4)],
          Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: LuvColors.accent.withValues(alpha: 0.5))),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: _get(key)),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          maxLines: 3,
          onChanged: (v) => _values[key] = v,
          decoration: InputDecoration(hintText: hint),
        ),
      ]),
    );
  }

  Widget _buildCurrencyField(String label, String key, String fallback, {String? icon, String? hint}) {
    final rawVal = _get(key, fallback);
    final displayVal = _ThousandSepFormatter.format(rawVal);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[Text(icon, style: const TextStyle(fontSize: 11)), const SizedBox(width: 4)],
          Expanded(
            child: Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: LuvColors.accent.withValues(alpha: 0.5))),
          ),
        ]),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint, style: TextStyle(fontSize: 9, color: LuvColors.textMuted.withValues(alpha: 0.6))),
        ],
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: displayVal),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          keyboardType: TextInputType.number,
          inputFormatters: [_ThousandSepFormatter()],
          onChanged: (v) => _values[key] = v.replaceAll('.', ''),
          decoration: InputDecoration(
            hintText: _ThousandSepFormatter.format(fallback),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 4),
              child: Text('Rp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LuvColors.textMuted)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
        ),
      ]),
    );
  }

  /// Info box explaining the shipping zones
  Widget _buildZoneInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LuvColors.accentBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LuvColors.accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, size: 14, color: LuvColors.accent),
            const SizedBox(width: 6),
            Text('PANDUAN ZONA ONGKIR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: LuvColors.accent, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 8),
          _zoneGuideRow('🏙️', 'Dalam Kota', 'Surabaya & sekitarnya (Sidoarjo, Gresik)'),
          _zoneGuideRow('🗺️', 'Dalam Provinsi', 'Kota lain di Jawa Timur'),
          _zoneGuideRow('🛤️', 'Pulau Jawa', 'Jabodetabek, Bandung, Semarang, Jogja'),
          _zoneGuideRow('🏝️', 'Sumatera & Bali', 'Pulau terdekat dari Jawa'),
          _zoneGuideRow('🌊', 'Kalim. & Sulawesi', 'Jarak menengah lewat laut'),
          _zoneGuideRow('✈️', 'Indonesia Timur', 'Terjauh: Papua, Maluku, NTT'),
        ],
      ),
    );
  }

  Widget _zoneGuideRow(String emoji, String zone, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 6),
          SizedBox(
            width: 100,
            child: Text(zone, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
          ),
          Expanded(
            child: Text(desc, style: TextStyle(fontSize: 8, color: LuvColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, String desc, bool value, ValueChanged<bool> onChanged, {bool danger = false}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value
              ? (danger ? LuvColors.errorBg : LuvColors.accentBg)
              : Colors.black.withValues(alpha: 0.15),
          border: Border.all(color: value ? (danger ? LuvColors.error.withValues(alpha: 0.15) : LuvColors.accent.withValues(alpha: 0.12)) : Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: value ? (danger ? LuvColors.error : LuvColors.accent) : LuvColors.textPrimary)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 10, color: LuvColors.textMuted, height: 1.5)),
              ]),
            ),
            const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44, height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: value
                    ? LinearGradient(colors: danger ? [LuvColors.error, LuvColors.error] : [LuvColors.accent, LuvColors.accentDark])
                    : null,
                color: value ? null : Colors.white.withValues(alpha: 0.07),
                border: Border.all(color: value ? Colors.transparent : Colors.white.withValues(alpha: 0.06)),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16, height: 16,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? Colors.white : Colors.white.withValues(alpha: 0.3),
                    boxShadow: value ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)] : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isMaintenance) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isMaintenance ? LuvColors.errorBg : LuvColors.successBg,
        border: Border.all(color: isMaintenance ? LuvColors.error.withValues(alpha: 0.1) : LuvColors.success.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMaintenance ? LuvColors.error : LuvColors.success,
            boxShadow: [BoxShadow(color: isMaintenance ? LuvColors.error : LuvColors.success, blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isMaintenance ? 'Website: MAINTENANCE (tidak bisa diakses)' : 'Website: ONLINE (bisa diakses semua orang)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isMaintenance ? LuvColors.error : LuvColors.success),
          ),
        ),
      ]),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saving ? null : _saveAll,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _saved
              ? const LinearGradient(colors: [LuvColors.success, Color(0xFF059669)])
              : const LinearGradient(colors: [LuvColors.accent, LuvColors.accentDark]),
          boxShadow: [
            BoxShadow(
              color: (_saved ? LuvColors.success : LuvColors.accent).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _saving ? '⏳ Menyimpan...' : _saved ? '✓ Tersimpan!' : '💾 Simpan Perubahan',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0B0D14), letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildToast() {
    Color bg, fg;
    switch (_toastType) {
      case 'error': bg = LuvColors.errorBg; fg = LuvColors.error; break;
      case 'warn': bg = LuvColors.warningBg; fg = LuvColors.warning; break;
      default: bg = LuvColors.successBg; fg = LuvColors.success;
    }
    return Positioned(
      top: 8, left: 20, right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: fg.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Text(_toastType == 'error' ? '❌' : _toastType == 'warn' ? '⚠️' : '✅', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(_toast!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg))),
          ]),
        ),
      ),
    );
  }
}
