import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../services/security_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _loading = true;
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _logs = [];
  List<Map<String, dynamic>> _blocks = [];
  String _filter = 'all';
  int? _expandedLog;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SecurityService.getStats(),
        SecurityService.getLogs(limit: 30),
        SecurityService.getBlockedIps(),
      ]);
      if (mounted) setState(() {
        _stats = results[0] as Map<String, int>;
        _logs = results[1] as List<Map<String, dynamic>>;
        _blocks = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Security load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_filter == 'all') return _logs;
    if (_filter == 'high') return _logs.where((l) => l['severity'] == 'HIGH' || l['severity'] == 'CRITICAL').toList();
    if (_filter == 'critical') return _logs.where((l) => l['severity'] == 'CRITICAL').toList();
    return _logs.where((l) => l['attack_type'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuvColors.background,
      body: SafeArea(
        child: _loading
            ? Padding(padding: const EdgeInsets.all(20), child: ShimmerLoading.list(count: 4, itemHeight: 100))
            : RefreshIndicator(
                color: LuvColors.accent,
                backgroundColor: LuvColors.surface,
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Header
                    Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(colors: [const Color(0xFF60A5FA).withValues(alpha: 0.15), LuvColors.glassMedium]),
                          border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.2)),
                        ),
                        child: const Center(child: Text('🛡️', style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Security Monitor', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
                        Text('Deteksi serangan & kelola keamanan', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
                      ]),
                    ]),
                    const SizedBox(height: 20),

                    // Stats
                    _buildStats(),
                    const SizedBox(height: 16),

                    // Blocked IPs
                    if (_blocks.isNotEmpty) ...[
                      _buildBlockedIps(),
                      const SizedBox(height: 16),
                    ],

                    // Filters
                    _buildFilters(),
                    const SizedBox(height: 12),

                    // Attack Log
                    _buildAttackLog(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStats() {
    final items = [
      {'icon': '📋', 'label': 'Total Events', 'value': _stats['total'] ?? 0, 'color': LuvColors.accent},
      {'icon': '📅', 'label': 'Hari Ini', 'value': _stats['today'] ?? 0, 'color': const Color(0xFF60A5FA)},
      {'icon': '🔴', 'label': 'Critical', 'value': _stats['critical'] ?? 0, 'color': LuvColors.error},
      {'icon': '🚫', 'label': 'Blocked IP', 'value': _stats['blocked'] ?? 0, 'color': const Color(0xFFF59E0B)},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          final color = item['color'] as Color;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + (i * 80)),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child)),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LuvColors.cardGradient,
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(item['icon'] as String, style: const TextStyle(fontSize: 14)),
                    const Spacer(),
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]),
                    ),
                  ]),
                  Text('${item['value']}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
                  Text(item['label'] as String, style: TextStyle(fontSize: 8, color: LuvColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockedIps() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: LuvColors.errorBg, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.block_rounded, size: 16, color: LuvColors.error),
            ),
            const SizedBox(width: 10),
            Text('IP Terblokir (${_blocks.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: LuvColors.textPrimary)),
          ]),
          const SizedBox(height: 12),
          ..._blocks.take(5).map((b) {
            final expiresAt = DateTime.tryParse(b['expires_at'] ?? '');
            final minutesLeft = expiresAt != null ? expiresAt.difference(DateTime.now()).inMinutes : 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LuvColors.error.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LuvColors.error.withValues(alpha: 0.08)),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b['ip'] ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: LuvColors.error, fontFamily: 'monospace')),
                  const SizedBox(height: 2),
                  Text(b['reason'] ?? '', style: TextStyle(fontSize: 9, color: LuvColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('⏱ Expires in ${minutesLeft}m', style: TextStyle(fontSize: 9, color: const Color(0xFFF59E0B))),
                ])),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _unblock(b['ip']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LuvColors.accent.withValues(alpha: 0.2)),
                    ),
                    child: const Text('Unblock', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: LuvColors.accent)),
                  ),
                ),
              ]),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _unblock(String ip) async {
    try {
      await SecurityService.unblockIp(ip);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('IP $ip berhasil di-unblock'), backgroundColor: LuvColors.success),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal unblock: $e'), backgroundColor: LuvColors.error),
        );
      }
    }
  }

  Widget _buildFilters() {
    final filters = [
      {'label': '🔍 Semua', 'key': 'all'},
      {'label': '🔴 High+', 'key': 'high'},
      {'label': '⚫ Critical', 'key': 'critical'},
      {'label': '💉 XSS', 'key': 'XSS'},
      {'label': '🗄️ SQLi', 'key': 'SQL_INJECTION'},
      {'label': '🤖 Bot', 'key': 'BOT_PROBE'},
      {'label': '⚡ Rate', 'key': 'RATE_LIMIT_EXCEEDED'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final selected = _filter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f['key']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? LuvColors.accentBg : LuvColors.glassLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? LuvColors.accent.withValues(alpha: 0.3) : LuvColors.borderLight),
                ),
                child: Text(f['label']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? LuvColors.accent : LuvColors.textMuted)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAttackLog() {
    final logs = _filteredLogs;
    if (logs.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const Text('✅', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          const Text('Aman!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Tidak ada event keamanan ditemukan', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
        ]),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📋', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Text('Attack Log', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: LuvColors.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: LuvColors.glassMedium, borderRadius: BorderRadius.circular(6)),
              child: Text('${logs.length}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: LuvColors.textMuted)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _loadData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: LuvColors.borderLight)),
                child: const Text('🔄 Refresh', style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...logs.take(20).toList().asMap().entries.map((e) => _buildLogRow(e.value, e.key)),
        ],
      ),
    );
  }

  static const _typeEmoji = {
    'XSS': '💉', 'SQL_INJECTION': '🗄️', 'COMMAND_INJECTION': '💻',
    'PATH_TRAVERSAL': '📂', 'RATE_LIMIT_EXCEEDED': '⚡', 'BOT_PROBE': '🤖',
    'SUSPICIOUS_PAYLOAD': '⚠️', 'DOM_INJECTION': '🌐', 'MANUAL_UNBLOCK': '🔓',
  };

  static const _sevColor = {
    'LOW': Color(0xFF6B7280), 'MEDIUM': Color(0xFFF59E0B),
    'HIGH': Color(0xFFEF4444), 'CRITICAL': Color(0xFFDC2626),
  };

  Widget _buildLogRow(Map<String, dynamic> log, int index) {
    final severity = log['severity'] ?? 'LOW';
    final color = _sevColor[severity] ?? const Color(0xFF6B7280);
    final type = log['attack_type'] ?? 'UNKNOWN';
    final emoji = _typeEmoji[type] ?? '🔍';
    final ip = log['ip'] ?? '-';
    final time = DateTime.tryParse(log['timestamp'] ?? '');
    final timeStr = time != null ? '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : '-';
    final action = log['action_taken'] ?? 'LOG';
    final isExpanded = _expandedLog == index;

    return GestureDetector(
      onTap: () => setState(() => _expandedLog = isExpanded ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isExpanded ? color.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isExpanded ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.02)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main row
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(type.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text('$ip • $timeStr', style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
              ])),
              // Severity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Text(severity, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 6),
              // Action badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: action == 'BLOCK' ? LuvColors.error.withValues(alpha: 0.1) : LuvColors.glassMedium,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(action, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: action == 'BLOCK' ? LuvColors.error : LuvColors.textMuted)),
              ),
            ]),
            // Expanded details
            if (isExpanded) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (log['url'] != null) _detailRow('URL', log['url']),
                  if (log['method'] != null) _detailRow('Method', log['method']),
                  if (log['country'] != null) _detailRow('Country', '${log['country']} ${log['city'] ?? ''}'),
                  if (log['source'] != null) _detailRow('Source', log['source']),
                  if (log['detection_reason'] != null) _detailRow('Detection', log['detection_reason']),
                  if (log['user_agent'] != null) ...[
                    const SizedBox(height: 4),
                    Text('USER AGENT', style: TextStyle(fontSize: 7, color: LuvColors.accent.withValues(alpha: 0.4), fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 2),
                    Text(log['user_agent'], style: TextStyle(fontSize: 8, color: LuvColors.textMuted, fontFamily: 'monospace'), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (log['payload_summary'] != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LuvColors.error.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: LuvColors.error.withValues(alpha: 0.1)),
                      ),
                      child: Text(log['payload_summary'], style: const TextStyle(fontSize: 9, color: LuvColors.error, fontFamily: 'monospace'), maxLines: 4, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 65,
          child: Text(label.toUpperCase(), style: TextStyle(fontSize: 7, color: LuvColors.accent.withValues(alpha: 0.4), fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        ),
        Expanded(child: Text(value, style: TextStyle(fontSize: 9, color: LuvColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
