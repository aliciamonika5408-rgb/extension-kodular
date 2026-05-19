import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/formatters.dart';
import '../services/transaction_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Map<String, dynamic> _t;
  final _trackingController = TextEditingController();
  String _shippingStatus = 'dikemas';
  bool _updating = false;
  Map<String, dynamic>? _promoData;
  bool _loadingPromo = false;

  final _shippingOptions = ['dikemas', 'dikirim', 'selesai'];

  @override
  void initState() {
    super.initState();
    _t = widget.transaction;
    _shippingStatus = _t['shipping_status'] ?? 'dikemas';
    _trackingController.text = _t['tracking_number'] ?? '';
    _loadPromoData();
  }

  Future<void> _loadPromoData() async {
    final code = _t['promo_code'];
    if (code == null || code.toString().isEmpty) return;
    setState(() => _loadingPromo = true);
    final promo = await TransactionService.getPromoByCode(code.toString());
    if (mounted) setState(() { _promoData = promo; _loadingPromo = false; });
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _updateShipping() async {
    setState(() => _updating = true);
    try {
      await TransactionService.updateShipping(
        id: _t['id'],
        shippingStatus: _shippingStatus,
        trackingNumber: _trackingController.text.trim().isNotEmpty ? _trackingController.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: LuvColors.success, size: 18),
            const SizedBox(width: 8),
            const Text('Status pengiriman diperbarui'),
          ]),
        ));
        setState(() {
          _t = {..._t, 'shipping_status': _shippingStatus, 'tracking_number': _trackingController.text.trim()};
          _updating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _t['order_id'] ?? '-';
    final customer = _t['customer_username'] ?? _t['customer_email'] ?? '-';
    final email = _t['customer_email'] ?? '-';
    final amount = _t['gross_amount'] ?? 0;
    final status = _t['status'] ?? 'pending';
    final paymentMethod = _t['payment_method'] ?? '-';
    final created = DateTime.tryParse(_t['created_at'] ?? '');
    final items = _t['items'] as List? ?? [];
    final shipping = _t['shipping_address'] as Map<String, dynamic>?;
    final promoCode = _t['promo_code'];

    return Scaffold(
      backgroundColor: LuvColors.background,
      appBar: AppBar(
        backgroundColor: LuvColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: LuvColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Detail Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18, color: LuvColors.textMuted),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: orderId));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order ID disalin')));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Order Header
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: LuvColors.textPrimary)),
                const SizedBox(height: 8),
                Row(children: [
                  StatusBadge.payment(status),
                  const SizedBox(width: 6),
                  StatusBadge.shipping(_t['shipping_status'] ?? 'dikemas'),
                ]),
                const SizedBox(height: 12),
                _infoRow(Icons.person_outline, 'Customer', customer),
                _infoRow(Icons.email_outlined, 'Email', email),
                _infoRow(Icons.payment_outlined, 'Pembayaran', paymentMethod),
                _infoRow(Icons.calendar_today_outlined, 'Tanggal', created != null ? Formatters.dateTimeId(created) : '-'),
                const Divider(height: 24, color: LuvColors.borderLight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL BAYAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: LuvColors.textMuted)),
                    Text(Formatters.currency(amount), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: LuvColors.accent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Separate product items from shipping/ongkir
                ...() {
                  final productItems = items.where((item) {
                    final name = (item['name'] ?? '').toString().toLowerCase();
                    return !name.contains('ongkir') && !name.contains('shipping') && !name.contains('pengiriman');
                  }).toList();
                  final shippingItems = items.where((item) {
                    final name = (item['name'] ?? '').toString().toLowerCase();
                    return name.contains('ongkir') || name.contains('shipping') || name.contains('pengiriman');
                  }).toList();

                  return [
                    Text('PRODUK (${productItems.length})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: LuvColors.accent)),
                    const SizedBox(height: 12),
                    ...productItems.map((item) {
                      final name = item['name'] ?? '-';
                      final size = item['size'] ?? '';
                      final qty = item['quantity'] ?? 1;
                      final price = item['price'] ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)))),
                        child: Row(
                          children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: LuvColors.textPrimary)),
                                if (size.isNotEmpty) Text(size, style: TextStyle(fontSize: 10, color: LuvColors.textMuted)),
                              ],
                            )),
                            Text('x$qty', style: TextStyle(fontSize: 11, color: LuvColors.textTertiary, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 16),
                            Text(price.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: LuvColors.accent)),
                          ],
                        ),
                      );
                    }),
                    // Ongkir section
                    if (shippingItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(height: 1, color: LuvColors.accent.withValues(alpha: 0.1)),
                      const SizedBox(height: 8),
                      ...shippingItems.map((item) {
                        final name = item['name'] ?? 'Ongkir';
                        final price = item['price'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 14, color: LuvColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(child: Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: LuvColors.textSecondary))),
                              Text(price.toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: LuvColors.textSecondary)),
                            ],
                          ),
                        );
                      }),
                    ],
                  ];
                }(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rincian Harga (Price Breakdown)
          _buildPriceBreakdown(items, amount, promoCode),
          const SizedBox(height: 16),

          // Shipping Address
          if (shipping != null)
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ALAMAT PENGIRIMAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: LuvColors.accent)),
                  const SizedBox(height: 12),
                  Text(shipping['name'] ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LuvColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(shipping['phone'] ?? '-', style: TextStyle(fontSize: 12, color: LuvColors.textTertiary)),
                  const SizedBox(height: 4),
                  Text(
                    [shipping['address'], shipping['city'], shipping['province'], shipping['postal_code']].where((s) => s != null && s.toString().isNotEmpty).join(', '),
                    style: TextStyle(fontSize: 12, color: LuvColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Update Shipping
          GlassCard(
            padding: const EdgeInsets.all(20),
            borderColor: LuvColors.accent.withValues(alpha: 0.15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UPDATE PENGIRIMAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: LuvColors.accent)),
                const SizedBox(height: 16),

                // Shipping status
                Text('STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: LuvColors.accent.withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LuvColors.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _shippingStatus,
                      isExpanded: true,
                      dropdownColor: LuvColors.surface,
                      style: const TextStyle(color: LuvColors.textPrimary, fontSize: 13),
                      items: _shippingOptions.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                      onChanged: (v) => setState(() => _shippingStatus = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tracking number
                Text('NOMOR RESI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: LuvColors.accent.withValues(alpha: 0.5))),
                const SizedBox(height: 8),
                TextField(
                  controller: _trackingController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Masukkan nomor resi...',
                    prefixIcon: Icon(Icons.local_shipping_outlined, size: 18, color: LuvColors.textMuted),
                  ),
                ),
                const SizedBox(height: 20),

                GoldButton(
                  label: 'Update Status',
                  onPressed: _updating ? null : _updateShipping,
                  isLoading: _updating,
                  expanded: true,
                  icon: Icons.save_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: LuvColors.textMuted),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 11, color: LuvColors.textMuted, fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 11, color: LuvColors.textSecondary, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(List items, dynamic grossAmount, String? promoCode) {
    // Separate product items from ongkir
    int subtotalProduk = 0;
    int ongkirTotal = 0;

    for (final item in items) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final priceRaw = item['price'];
      int price = 0;
      if (priceRaw is num) {
        price = priceRaw.toInt();
      } else if (priceRaw is String) {
        price = int.tryParse(priceRaw.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;

      if (name.contains('ongkir') || name.contains('shipping') || name.contains('pengiriman')) {
        ongkirTotal += price * qty;
      } else {
        subtotalProduk += price * qty;
      }
    }

    final int totalBayar = (grossAmount as num?)?.toInt() ?? 0;
    final int discountAmount = (subtotalProduk + ongkirTotal) - totalBayar;

    // Determine promo description
    String promoDesc = '';
    String promoTypeLabel = '';
    bool isFreeOngkir = false;

    if (_promoData != null) {
      final discType = _promoData!['discount_type'] ?? 'fixed';
      final discValue = (_promoData!['discount'] as num?)?.toInt() ?? 0;
      final maxDisc = (_promoData!['max_discount'] as num?)?.toInt() ?? 0;

      if (discType == 'percentage') {
        promoTypeLabel = 'Diskon $discValue%';
        if (maxDisc > 0) promoTypeLabel += ' (maks. ${Formatters.currency(maxDisc)})';
      } else {
        promoTypeLabel = 'Potongan ${Formatters.currency(discValue)}';
      }

      // Check if this looks like a free shipping promo
      if (discountAmount > 0 && ongkirTotal > 0 && discountAmount == ongkirTotal) {
        isFreeOngkir = true;
        promoDesc = 'Gratis Ongkir';
      } else if (discountAmount > 0 && ongkirTotal > 0 && discountAmount > subtotalProduk * 0.01) {
        // Could be product + shipping discount
        promoDesc = promoTypeLabel;
      } else {
        promoDesc = promoTypeLabel;
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RINCIAN HARGA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1, color: LuvColors.accent)),
          const SizedBox(height: 14),

          // Subtotal Produk
          _priceRow('Subtotal Produk', Formatters.currency(subtotalProduk), LuvColors.textSecondary),
          const SizedBox(height: 8),

          // Ongkir
          _priceRow(
            'Ongkos Kirim',
            ongkirTotal > 0 ? Formatters.currency(ongkirTotal) : 'Gratis',
            ongkirTotal > 0 ? LuvColors.textSecondary : LuvColors.success,
            icon: Icons.local_shipping_outlined,
          ),

          // Promo Section
          if (promoCode != null && promoCode.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: LuvColors.accent.withValues(alpha: 0.08)),
            const SizedBox(height: 10),

            // Promo Code Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      LuvColors.success.withValues(alpha: 0.12),
                      LuvColors.success.withValues(alpha: 0.04),
                    ]),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: LuvColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.discount_rounded, size: 11, color: LuvColors.success),
                      const SizedBox(width: 4),
                      Text(promoCode, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: LuvColors.success, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (_loadingPromo)
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: LuvColors.accent))
                else if (promoDesc.isNotEmpty)
                  Expanded(
                    child: Text(
                      promoDesc,
                      style: TextStyle(fontSize: 10, color: LuvColors.textMuted, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Free ongkir indicator
            if (isFreeOngkir)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: LuvColors.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: LuvColors.success.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 14, color: LuvColors.success),
                    const SizedBox(width: 6),
                    Text('GRATIS ONGKIR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: LuvColors.success, letterSpacing: 0.5)),
                    const Spacer(),
                    Text('-${Formatters.currency(ongkirTotal)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: LuvColors.success)),
                  ],
                ),
              )
            else if (discountAmount > 0)
              // Discount amount
              _priceRow(
                'Potongan Promo',
                '-${Formatters.currency(discountAmount)}',
                LuvColors.success,
                icon: Icons.arrow_downward_rounded,
                isBold: true,
              ),
          ],

          const SizedBox(height: 10),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 10),

          // Total Bayar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL BAYAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: LuvColors.textMuted)),
              Text(Formatters.currency(totalBayar), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: LuvColors.accent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color valueColor, {IconData? icon, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: LuvColors.textMuted),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(fontSize: 11, color: LuvColors.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
