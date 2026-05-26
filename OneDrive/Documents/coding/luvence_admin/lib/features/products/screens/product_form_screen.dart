import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../services/product_service.dart';

/// Auto-formats numbers with dot thousand separators (e.g. 100.000)
class _ThousandFormatter extends TextInputFormatter {
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

  static String format(dynamic value) {
    final s = value?.toString() ?? '';
    final digits = s.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    return _addDots(digits);
  }
}

/// Auto-formats with "Rp " prefix + dots (e.g. Rp 1.350.000)
class _RpFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    final formatted = 'Rp ${_ThousandFormatter._addDots(digits)}';
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }

  static String format(dynamic value) {
    final s = value?.toString() ?? '';
    final digits = s.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return s; // keep original if no digits (e.g. "Rp 1.350.000")
    return 'Rp ${_ThousandFormatter._addDots(digits)}';
  }
}

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool get _isEdit => widget.product != null;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _originCtrl;
  late TextEditingController _badgeCtrl;
  late TextEditingController _longevityCtrl;
  late TextEditingController _sillageCtrl;
  bool _isActive = true;
  String _imageUrl = '';
  File? _imageFile;

  List<Map<String, dynamic>> _sizes = [];
  List<String> _notes = [];
  Map<String, List<String>> _pyramidNotes = {'top': [], 'heart': [], 'base': []};

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?['name'] ?? '');
    _descCtrl = TextEditingController(text: p?['description'] ?? '');
    _priceCtrl = TextEditingController(text: _RpFormatter.format(p?['price'] ?? ''));
    _typeCtrl = TextEditingController(text: p?['type'] ?? 'Eau de Parfum');
    _originCtrl = TextEditingController(text: p?['origin'] ?? 'France');
    _badgeCtrl = TextEditingController(text: p?['badge'] ?? '');
    _longevityCtrl = TextEditingController(text: p?['longevity'] ?? '');
    _sillageCtrl = TextEditingController(text: p?['sillage'] ?? '');
    _isActive = p?['is_active'] ?? true;
    _imageUrl = p?['image'] ?? '';

    if (p?['sizes'] != null) _sizes = List<Map<String, dynamic>>.from(p!['sizes']);
    if (p?['notes'] != null) _notes = List<String>.from(p!['notes']);
    if (p?['pyramid_notes'] != null) {
      final pn = p!['pyramid_notes'] as Map<String, dynamic>;
      _pyramidNotes = {
        'top': List<String>.from(pn['top'] ?? []),
        'heart': List<String>.from(pn['heart'] ?? []),
        'base': List<String>.from(pn['base'] ?? []),
      };
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _typeCtrl.dispose(); _originCtrl.dispose(); _badgeCtrl.dispose();
    _longevityCtrl.dispose(); _sillageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 90);
    if (picked != null) {
      final file = File(picked.path);
      final sizeBytes = await file.length();
      if (sizeBytes > ProductService.maxFileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File terlalu besar (${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB). Maksimal 5 MB.'),
              backgroundColor: LuvColors.error,
            ),
          );
        }
        return;
      }
      setState(() => _imageFile = file);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String imageUrl = _imageUrl;
      if (_imageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}';
        imageUrl = await ProductService.uploadImage(_imageFile!, fileName);
      }

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'type': _typeCtrl.text.trim(),
        'origin': _originCtrl.text.trim(),
        'badge': _badgeCtrl.text.trim().isEmpty ? null : _badgeCtrl.text.trim(),
        'longevity': _longevityCtrl.text.trim(),
        'sillage': _sillageCtrl.text.trim(),
        'image': imageUrl,
        'is_active': _isActive,
        'sizes': _sizes,
        'notes': _notes,
        'pyramid_notes': _pyramidNotes,
      };

      if (_isEdit) {
        await ProductService.updateProduct(widget.product!['id'], data);
      } else {
        await ProductService.createProduct(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEdit ? 'Produk diperbarui' : 'Produk ditambahkan')));
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
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // Image
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180, width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: LuvColors.surface,
                        border: Border.all(color: LuvColors.borderLight, style: BorderStyle.solid),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_imageFile!, fit: BoxFit.cover))
                          : _imageUrl.startsWith('http')
                              ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(_imageUrl, fit: BoxFit.cover))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 36, color: LuvColors.textMuted),
                                    const SizedBox(height: 8),
                                    Text('Tap untuk pilih gambar', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
                                  ],
                                ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Basic Info
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('INFO DASAR'),
                  const SizedBox(height: 12),
                  _field('Nama Produk', _nameCtrl, required: true),
                  _field('Harga (contoh: Rp 1.350.000)', _priceCtrl, formatters: [_RpFormatter()]),
                  _field('Deskripsi', _descCtrl, maxLines: 4),
                  Row(children: [
                    Expanded(child: _field('Tipe', _typeCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Asal', _originCtrl)),
                  ]),
                  Row(children: [
                    Expanded(child: _field('Longevity', _longevityCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _field('Sillage', _sillageCtrl)),
                  ]),
                  _field('Badge (opsional)', _badgeCtrl),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Produk Aktif', style: TextStyle(fontSize: 12, color: LuvColors.textSecondary, fontWeight: FontWeight.w600)),
                      Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Sizes
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('UKURAN & STOK'),
                  const SizedBox(height: 12),
                  ..._sizes.asMap().entries.map((e) => _sizeRow(e.key, e.value)),
                  const SizedBox(height: 8),
                  GoldButton(label: 'Tambah Ukuran', style: GoldButtonStyle.secondary, icon: Icons.add, expanded: true,
                    onPressed: () => setState(() => _sizes.add({'volume': '', 'price': '', 'stock': 100, 'scale': 1.0}))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('NOTES'),
                  const SizedBox(height: 12),
                  _tagInput(_notes, (v) => setState(() => _notes = v), 'Tambah note...'),
                  const SizedBox(height: 16),
                  _sectionTitle('PYRAMID NOTES'),
                  const SizedBox(height: 12),
                  Text('Top Notes', style: TextStyle(fontSize: 10, color: LuvColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _tagInput(_pyramidNotes['top']!, (v) => setState(() => _pyramidNotes['top'] = v), 'Top note...'),
                  const SizedBox(height: 10),
                  Text('Heart Notes', style: TextStyle(fontSize: 10, color: LuvColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _tagInput(_pyramidNotes['heart']!, (v) => setState(() => _pyramidNotes['heart'] = v), 'Heart note...'),
                  const SizedBox(height: 10),
                  Text('Base Notes', style: TextStyle(fontSize: 10, color: LuvColors.textMuted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _tagInput(_pyramidNotes['base']!, (v) => setState(() => _pyramidNotes['base'] = v), 'Base note...'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            GoldButton(label: _isEdit ? 'Update Produk' : 'Simpan Produk', onPressed: _saving ? null : _save, isLoading: _saving, expanded: true, icon: Icons.save_outlined),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: LuvColors.accent));

  Widget _field(String hint, TextEditingController ctrl, {bool required = false, int maxLines = 1, List<TextInputFormatter>? formatters, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl, maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(hintText: hint),
        inputFormatters: formatters,
        keyboardType: keyboardType ?? (formatters != null ? TextInputType.number : null),
        validator: required ? (v) => v == null || v.trim().isEmpty ? 'Wajib diisi' : null : null,
      ),
    );
  }

  Widget _sizeRow(int i, Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: LuvColors.borderLight)),
      child: Row(
        children: [
          Expanded(child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(hintText: 'Volume', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            controller: TextEditingController(text: s['volume']?.toString() ?? ''),
            onChanged: (v) => _sizes[i]['volume'] = v,
          )),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(hintText: 'Harga', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            keyboardType: TextInputType.number,
            inputFormatters: [_RpFormatter()],
            controller: TextEditingController(text: _RpFormatter.format(s['price']?.toString() ?? '')),
            onChanged: (v) => _sizes[i]['price'] = v,
          )),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: const InputDecoration(hintText: 'Stok', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: (s['stock'] ?? 0).toString()),
            onChanged: (v) => _sizes[i]['stock'] = int.tryParse(v) ?? 0,
          )),
          IconButton(icon: const Icon(Icons.close, size: 16, color: LuvColors.error), onPressed: () => setState(() => _sizes.removeAt(i))),
        ],
      ),
    );
  }

  Widget _tagInput(List<String> tags, Function(List<String>) onChanged, String hint) {
    final ctrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty) Wrap(
          spacing: 6, runSpacing: 6,
          children: tags.asMap().entries.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: LuvColors.accentBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: LuvColors.accent.withValues(alpha: 0.15))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.value, style: const TextStyle(fontSize: 11, color: LuvColors.accent, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                GestureDetector(onTap: () { final l = List<String>.from(tags); l.removeAt(e.key); onChanged(l); },
                  child: Icon(Icons.close, size: 12, color: LuvColors.accent.withValues(alpha: 0.5))),
              ],
            ),
          )).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: TextField(
              controller: ctrl, style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(hintText: hint, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              onSubmitted: (v) { if (v.trim().isNotEmpty) { onChanged([...tags, v.trim()]); ctrl.clear(); } },
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () { if (ctrl.text.trim().isNotEmpty) { onChanged([...tags, ctrl.text.trim()]); ctrl.clear(); } },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: LuvColors.accent.withValues(alpha: 0.2))),
                child: const Icon(Icons.add, size: 16, color: LuvColors.accent),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
