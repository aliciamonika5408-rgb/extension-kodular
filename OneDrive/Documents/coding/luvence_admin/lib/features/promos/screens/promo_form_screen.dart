import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../services/promo_service.dart';

/// Auto-formats numbers with dot thousand separators (e.g. 100.000)
class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Strip all non-digits
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));

    // Format with dots
    final formatted = _addDots(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _addDots(String digits) {
    final buffer = StringBuffer();
    final len = digits.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Format a number for display
  static String format(dynamic value) {
    final n = int.tryParse(value.toString()) ?? 0;
    if (n == 0) return '';
    return _addDots(n.toString());
  }

  /// Parse a formatted string back to int
  static int parse(String formatted) {
    return int.tryParse(formatted.replaceAll('.', '')) ?? 0;
  }
}

class PromoFormScreen extends StatefulWidget {
  final Map<String, dynamic>? promo;
  const PromoFormScreen({super.key, this.promo});

  @override
  State<PromoFormScreen> createState() => _PromoFormScreenState();
}

class _PromoFormScreenState extends State<PromoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool get _isEdit => widget.promo != null;

  late TextEditingController _codeCtrl;
  late TextEditingController _discountCtrl;
  late TextEditingController _minTxCtrl;
  late TextEditingController _maxDiscountCtrl;
  late TextEditingController _maxUsageCtrl;
  String _discountType = 'fixed'; // 'fixed', 'percentage', 'free_shipping'
  bool _isActive = true;
  bool _oncePerUser = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final p = widget.promo;
    _codeCtrl = TextEditingController(text: p?['code'] ?? '');
    _discountType = p?['discount_type'] ?? 'fixed';
    // Format Rp fields with thousand separators; percentage stays raw
    _discountCtrl = TextEditingController(
      text: _discountType == 'percentage'
          ? (p?['discount'] ?? '').toString()
          : _ThousandSeparatorFormatter.format(p?['discount']),
    );
    _minTxCtrl = TextEditingController(text: _ThousandSeparatorFormatter.format(p?['min_transaction']));
    _maxDiscountCtrl = TextEditingController(text: _ThousandSeparatorFormatter.format(p?['max_discount']));
    _maxUsageCtrl = TextEditingController(text: _ThousandSeparatorFormatter.format(p?['max_usage']));
    _isActive = p?['is_active'] ?? true;
    _oncePerUser = p?['once_per_user'] ?? false;
    _startDate = DateTime.tryParse(p?['start_date'] ?? '');
    _endDate = DateTime.tryParse(p?['end_date'] ?? '');
  }

  @override
  void dispose() {
    _codeCtrl.dispose(); _discountCtrl.dispose(); _minTxCtrl.dispose();
    _maxDiscountCtrl.dispose(); _maxUsageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: LuvColors.accent, surface: LuvColors.surface),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => isStart ? _startDate = date : _endDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final data = {
        'code': _codeCtrl.text.trim().toUpperCase(),
        'discount': _discountType == 'free_shipping'
            ? 0
            : _discountType == 'percentage'
                ? (int.tryParse(_discountCtrl.text) ?? 0)
                : _ThousandSeparatorFormatter.parse(_discountCtrl.text),
        'discount_type': _discountType,
        'min_transaction': _ThousandSeparatorFormatter.parse(_minTxCtrl.text),
        'max_discount': ['percentage', 'free_shipping'].contains(_discountType)
            ? _ThousandSeparatorFormatter.parse(_maxDiscountCtrl.text)
            : 0,
        'max_usage': _ThousandSeparatorFormatter.parse(_maxUsageCtrl.text),
        'once_per_user': _oncePerUser,
        'is_active': _isActive,
        'start_date': (_startDate ?? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).toIso8601String(),
        if (_endDate != null) 'end_date': _endDate!.toIso8601String(),
      };

      if (_isEdit) {
        await PromoService.updatePromo(widget.promo!['id'], data);
      } else {
        await PromoService.createPromo(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Promo diperbarui' : 'Promo dibuat')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuvColors.background,
      appBar: AppBar(
        backgroundColor: LuvColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: LuvColors.accent), onPressed: () => Navigator.pop(context)),
        title: Text(_isEdit ? 'Edit Promo' : 'Buat Promo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('KODE PROMO'),
                  TextFormField(
                    controller: _codeCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2),
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'LUVENCE50'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  _label('TIPE DISKON'),
                  Row(children: [
                    _typeChip('💰 Nominal', 'fixed', Icons.money_rounded),
                    const SizedBox(width: 8),
                    _typeChip('📊 Persen', 'percentage', Icons.percent_rounded),
                    const SizedBox(width: 8),
                    _typeChip('🚚 Ongkir', 'free_shipping', Icons.local_shipping_rounded),
                  ]),
                  const SizedBox(height: 16),

                  // Discount input — hidden for free_shipping
                  if (_discountType == 'free_shipping') ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: LuvColors.success.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: LuvColors.success.withValues(alpha: 0.12)),
                      ),
                      child: Row(children: [
                        Icon(Icons.local_shipping_rounded, size: 18, color: LuvColors.success),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          'Ongkos kirim akan 100% digratiskan',
                          style: TextStyle(fontSize: 12, color: LuvColors.success, fontWeight: FontWeight.w600),
                        )),
                      ]),
                    ),
                  ] else ...[
                    _label(_discountType == 'percentage' ? 'DISKON (%)' : 'DISKON (Rp)'),
                    TextFormField(
                      controller: _discountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: _discountType == 'percentage'
                          ? [FilteringTextInputFormatter.digitsOnly]
                          : [_ThousandSeparatorFormatter()],
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(hintText: _discountType == 'percentage' ? '10' : '50.000'),
                      validator: (v) => (_discountType != 'free_shipping' && (v == null || v.trim().isEmpty)) ? 'Wajib diisi' : null,
                    ),
                  ],
                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _label('MIN. TRANSAKSI'),
                      TextFormField(controller: _minTxCtrl, keyboardType: TextInputType.number, inputFormatters: [_ThousandSeparatorFormatter()], style: const TextStyle(color: Colors.white, fontSize: 13), decoration: const InputDecoration(hintText: '100.000')),
                    ])),
                    const SizedBox(width: 12),
                    if (['percentage', 'free_shipping'].contains(_discountType))
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _label('MAX. DISKON'),
                        TextFormField(controller: _maxDiscountCtrl, keyboardType: TextInputType.number, inputFormatters: [_ThousandSeparatorFormatter()], style: const TextStyle(color: Colors.white, fontSize: 13), decoration: const InputDecoration(hintText: '50.000')),
                      ])),
                  ]),
                  const SizedBox(height: 16),

                  _label('MAX. PENGGUNAAN'),
                  TextFormField(controller: _maxUsageCtrl, keyboardType: TextInputType.number, inputFormatters: [_ThousandSeparatorFormatter()], style: const TextStyle(color: Colors.white, fontSize: 13), decoration: const InputDecoration(hintText: '0 = unlimited')),
                  const SizedBox(height: 16),

                  // Dates
                  Row(children: [
                    Expanded(child: _dateButton('Mulai', _startDate, () => _pickDate(true))),
                    const SizedBox(width: 12),
                    Expanded(child: _dateButton('Berakhir', _endDate, () => _pickDate(false))),
                  ]),
                  const SizedBox(height: 16),

                  // Toggles
                  _toggleRow('Sekali per User', _oncePerUser, (v) => setState(() => _oncePerUser = v)),
                  _toggleRow('Promo Aktif', _isActive, (v) => setState(() => _isActive = v)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            GoldButton(label: _isEdit ? 'Update Promo' : 'Buat Promo', onPressed: _saving ? null : _save, isLoading: _saving, expanded: true, icon: Icons.save_outlined),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: LuvColors.accent.withValues(alpha: 0.5))),
  );

  Widget _typeChip(String label, String key, IconData icon) {
    final selected = _discountType == key;
    final isShipping = key == 'free_shipping';
    final chipColor = isShipping ? LuvColors.success : LuvColors.accent;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _discountType = key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? chipColor.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? chipColor.withValues(alpha: 0.3) : LuvColors.borderLight),
          ),
          child: Center(
            child: Text(label, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: selected ? chipColor : LuvColors.textMuted,
            )),
          ),
        ),
      ),
    );
  }

  Widget _dateButton(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(12), border: Border.all(color: LuvColors.borderLight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, color: LuvColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(date != null ? '${date.day}/${date.month}/${date.year}' : 'Pilih tanggal', style: TextStyle(fontSize: 12, color: date != null ? LuvColors.textPrimary : LuvColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, color: LuvColors.textSecondary, fontWeight: FontWeight.w600)),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}
