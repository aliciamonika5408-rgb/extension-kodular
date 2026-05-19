import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/formatters.dart';

class RecentOrders extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const RecentOrders({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text('🛒 ', style: TextStyle(fontSize: 16)),
                Text('PESANAN TERBARU', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: LuvColors.accent, letterSpacing: 1)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: LuvColors.accentBg, borderRadius: BorderRadius.circular(10)),
                child: Text('${transactions.length} ORDER', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: LuvColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Belum ada pesanan', style: TextStyle(fontSize: 12, color: LuvColors.textMuted)),
            ))
          else
            ...transactions.asMap().entries.map((entry) {
              final i = entry.key;
              final t = entry.value;
              final orderId = t['order_id'] ?? '-';
              final customer = t['customer_username'] ?? t['customer_email'] ?? '-';
              final amount = t['gross_amount'] ?? 0;
              final status = t['status'] ?? 'pending';
              final shipping = t['shipping_status'] ?? 'dikemas';

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  border: i < transactions.length - 1
                      ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)))
                      : null,
                ),
                child: Row(
                  children: [
                    // Index
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: LuvColors.glassMedium,
                      ),
                      child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: LuvColors.textMuted))),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(orderId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: LuvColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(customer, style: TextStyle(fontSize: 10, color: LuvColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Amount + Status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(Formatters.currency(amount), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: LuvColors.accent)),
                        const SizedBox(height: 4),
                        Row(children: [
                          StatusBadge.payment(status),
                          const SizedBox(width: 4),
                          StatusBadge.shipping(shipping),
                        ]),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
