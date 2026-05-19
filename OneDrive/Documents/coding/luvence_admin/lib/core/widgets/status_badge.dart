import 'package:flutter/material.dart';
import '../constants/colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  /// Payment status badge (synced with web admin DB values)
  factory StatusBadge.payment(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'settlement':
      case 'capture':
        return const StatusBadge(label: 'BERHASIL', color: LuvColors.success, bgColor: LuvColors.successBg);
      case 'pending':
        return const StatusBadge(label: 'MENUNGGU', color: LuvColors.warning, bgColor: LuvColors.warningBg);
      case 'failed':
      case 'cancel':
      case 'deny':
      case 'failure':
        return const StatusBadge(label: 'GAGAL', color: LuvColors.error, bgColor: LuvColors.errorBg);
      case 'expire':
      case 'expired':
        return const StatusBadge(label: 'EXPIRED', color: LuvColors.textTertiary, bgColor: LuvColors.glassLight);
      default:
        return StatusBadge(label: status.toUpperCase(), color: LuvColors.textTertiary, bgColor: LuvColors.glassLight);
    }
  }

  /// Shipping status badge (synced with web admin)
  factory StatusBadge.shipping(String status) {
    switch (status.toLowerCase()) {
      case 'dikemas':
        return const StatusBadge(label: 'DIKEMAS', color: LuvColors.warning, bgColor: LuvColors.warningBg);
      case 'shipped':
      case 'dikirim':
        return const StatusBadge(label: 'DIKIRIM', color: LuvColors.info, bgColor: LuvColors.infoBg);
      case 'delivered':
      case 'selesai':
        return const StatusBadge(label: 'SELESAI', color: LuvColors.success, bgColor: LuvColors.successBg);
      default:
        return StatusBadge(label: status.toUpperCase(), color: LuvColors.textTertiary, bgColor: LuvColors.glassLight);
    }
  }

  /// Product active/inactive badge
  factory StatusBadge.active(bool isActive) {
    return isActive
        ? const StatusBadge(label: 'LIVE', color: LuvColors.success, bgColor: LuvColors.successBg)
        : const StatusBadge(label: 'OFF', color: LuvColors.error, bgColor: LuvColors.errorBg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
