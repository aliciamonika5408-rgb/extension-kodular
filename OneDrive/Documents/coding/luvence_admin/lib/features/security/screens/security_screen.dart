import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
  DateTime? _lastRefresh;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-refresh every 60 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        SecurityService.getStats(),
        SecurityService.getLogs(limit: 50),
        SecurityService.getBlockedIps(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, int>;
          _logs = results[1] as List<Map<String, dynamic>>;
          _blocks = results[2] as List<Map<String, dynamic>>;
          _loading = false;
          _lastRefresh = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint('Security load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_filter == 'all') return _logs;
    if (_filter == 'high') {
      return _logs.where((l) => l['severity'] == 'HIGH' || l['severity'] == 'CRITICAL').toList();
    }
    if (_filter == 'critical') {
      return _logs.where((l) => l['severity'] == 'CRITICAL').toList();
    }
    if (_filter == 'today') {
      final todayStart = DateTime.now();
      final start = DateTime(todayStart.year, todayStart.month, todayStart.day);
      return _logs.where((l) {
        final t = DateTime.tryParse(l['timestamp'] ?? '');
        return t != null && t.isAfter(start);
      }).toList();
    }
    return _logs.where((l) => l['attack_type'] == _filter).toList();
  }

  // ── Security Health Score ────────────────────────────────────────────────
  int get _healthScore {
    final critical = _stats['critical'] ?? 0;
    final blocked = _stats['blocked'] ?? 0;
    final high = _stats['high'] ?? 0;
    final last24h = _stats['last24h'] ?? 0;

    int score = 100;
    if (critical > 0) score -= (critical * 10).clamp(0, 40);
    if (high > 5) score -= ((high - 5) * 2).clamp(0, 20);
    if (blocked > 3) score -= 10;
    if (last24h > 50) score -= 15;
    return score.clamp(0, 100);
  }

  Color get _healthColor {
    final s = _healthScore;
    if (s >= 80) return LuvColors.success;
    if (s >= 60) return const Color(0xFFF59E0B);
    return LuvColors.error;
  }

  String get _healthLabel {
    final s = _healthScore;
    if (s >= 80) return 'Aman';
    if (s >= 60) return 'Waspada';
    return 'Berbahaya';
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
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildHealthCard(),
                    const SizedBox(height: 16),
                    _buildStats(),
                    const SizedBox(height: 16),
                    if (_blocks.isNotEmpty) ...[
                      _buildBlockedIps(),
                      const SizedBox(height: 16),
                    ],
                    _buildFilters(),
                    const SizedBox(height: 12),
                    _buildAttackLog(),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final refreshStr = _lastRefresh != null
        ? 'Diperbarui ${_relativeTime(_lastRefresh!)}'
        : 'Memuat data...';

    return Row(children: [
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
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Security Monitor', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
          Text(refreshStr, style: TextStyle(fontSize: 10, color: LuvColors.textMuted)),
        ]),
      ),
      GestureDetector(
        onTap: _loadData,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LuvColors.borderLight),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.refresh_rounded, size: 14, color: LuvColors.accent),
            SizedBox(width: 4),
            Text('Refresh', style: TextStyle(fontSize: 10, color: LuvColors.accent, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]);
  }

  // ── Health Card ──────────────────────────────────────────────────────────
  Widget _buildHealthCard() {
    final score = _healthScore;
    final color = _healthColor;
    final label = _healthLabel;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(children: [
        // Score circle
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 64, height: 64,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            Text('%', style: TextStyle(fontSize: 8, color: color.withValues(alpha: 0.7))),
          ]),
        ]),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]),
            ),
            const SizedBox(width: 6),
            Text('Status: $label', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ]),
          const SizedBox(height: 6),
          Text('${_stats['last24h'] ?? 0} event dalam 24 jam terakhir', style: TextStyle(fontSize: 11, color: LuvColors.textSecondary)),
          const SizedBox(height: 4),
          Text('${_stats['blocked'] ?? 0} IP aktif terblokir', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Text(label.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.8)),
          ),
          const SizedBox(height: 6),
          Text('Security\nScore', style: TextStyle(fontSize: 9, color: LuvColors.textMuted), textAlign: TextAlign.right),
        ]),
      ]),
    );
  }

  // ── Stats Grid ───────────────────────────────────────────────────────────
  Widget _buildStats() {
    final items = [
      {'icon': '📋', 'label': 'Total Events', 'value': _stats['total'] ?? 0, 'color': LuvColors.accent},
      {'icon': '⏰', 'label': '24 Jam Ini', 'value': _stats['last24h'] ?? 0, 'color': const Color(0xFF60A5FA)},
      {'icon': '⚠️', 'label': 'High+Critical', 'value': _stats['high'] ?? 0, 'color': const Color(0xFFF59E0B)},
      {'icon': '💀', 'label': 'Critical', 'value': _stats['critical'] ?? 0, 'color': LuvColors.error},
      {'icon': '🚫', 'label': 'IP Blocked', 'value': _stats['blocked'] ?? 0, 'color': const Color(0xFFE879F9)},
    ];

    return SizedBox(
      height: 95,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final item = items[i];
          final color = item['color'] as Color;
          final value = item['value'] as int;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 350 + (i * 70)),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child)),
            child: Container(
              width: 115,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.08), LuvColors.cardGradient.colors.last],
                ),
                border: Border.all(color: color.withValues(alpha: 0.18)),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(item['icon'] as String, style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: color,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 5)],
                      ),
                    ),
                  ]),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: value),
                    duration: Duration(milliseconds: 600 + (i * 100)),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Text('$v', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
                  ),
                  Text(item['label'] as String, style: TextStyle(fontSize: 8, color: LuvColors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Blocked IPs ──────────────────────────────────────────────────────────
  Widget _buildBlockedIps() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: LuvColors.errorBg, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.block_rounded, size: 16, color: LuvColors.error),
          ),
          const SizedBox(width: 10),
          Text('IP Terblokir (${_blocks.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: LuvColors.textPrimary)),
          const Spacer(),
          Text('aktif sekarang', style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
        ]),
        const SizedBox(height: 12),
        ..._blocks.take(5).map((b) {
          final expiresAt = DateTime.tryParse(b['expires_at'] ?? '');
          final timeLeft = expiresAt != null
              ? expiresAt.difference(DateTime.now())
              : Duration.zero;
          final expStr = timeLeft.isNegative
              ? 'Expired'
              : timeLeft.inHours > 0
                  ? '${timeLeft.inHours}j ${timeLeft.inMinutes.remainder(60)}m tersisa'
                  : '${timeLeft.inMinutes}m tersisa';

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
                Row(children: [
                  const Icon(Icons.gps_fixed_rounded, size: 11, color: LuvColors.error),
                  const SizedBox(width: 4),
                  Text(b['ip'] ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: LuvColors.error, fontFamily: 'monospace')),
                ]),
                const SizedBox(height: 3),
                Text(b['reason'] ?? '', style: TextStyle(fontSize: 9, color: LuvColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.timer_outlined, size: 9, color: const Color(0xFFF59E0B).withValues(alpha: 0.7)),
                  const SizedBox(width: 3),
                  Text(expStr, style: const TextStyle(fontSize: 9, color: Color(0xFFF59E0B))),
                ]),
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
      ]),
    );
  }

  Future<void> _unblock(String ip) async {
    try {
      HapticFeedback.mediumImpact();
      await SecurityService.unblockIp(ip);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ IP $ip berhasil di-unblock'),
          backgroundColor: LuvColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal unblock: $e'),
          backgroundColor: LuvColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Filter Chips ─────────────────────────────────────────────────────────
  Widget _buildFilters() {
    final todayCount = _logs.where((l) {
      final t = DateTime.tryParse(l['timestamp'] ?? '');
      if (t == null) return false;
      final s = DateTime.now();
      return t.isAfter(DateTime(s.year, s.month, s.day));
    }).length;

    final highCount = _logs.where((l) =>
        l['severity'] == 'HIGH' || l['severity'] == 'CRITICAL').length;

    final filters = [
      {'label': '🔍 Semua', 'key': 'all', 'count': _logs.length},
      {'label': '📅 Hari Ini', 'key': 'today', 'count': todayCount},
      {'label': '🔴 High+', 'key': 'high', 'count': highCount},
      {'label': '⚫ Critical', 'key': 'critical', 'count': _stats['critical'] ?? 0},
      {'label': '💉 XSS', 'key': 'XSS', 'count': null},
      {'label': '🗄️ SQLi', 'key': 'SQL_INJECTION', 'count': null},
      {'label': '🤖 Bot', 'key': 'BOT_PROBE', 'count': null},
      {'label': '⚡ Rate', 'key': 'RATE_LIMIT_EXCEEDED', 'count': null},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final selected = _filter == f['key'];
          final count = f['count'] as int?;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? LuvColors.accentBg : LuvColors.glassLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? LuvColors.accent.withValues(alpha: 0.3) : LuvColors.borderLight),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(f['label'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: selected ? LuvColors.accent : LuvColors.textMuted)),
                  if (count != null && count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: selected ? LuvColors.accent : LuvColors.glassMedium,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('$count', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: selected ? const Color(0xFF0B0D14) : LuvColors.textMuted)),
                    ),
                  ],
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Attack Log ───────────────────────────────────────────────────────────
  Widget _buildAttackLog() {
    final logs = _filteredLogs;
    if (logs.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const Text('✅', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          const Text('Bersih!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LuvColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Tidak ada event keamanan ditemukan', style: TextStyle(fontSize: 11, color: LuvColors.textMuted)),
        ]),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📋', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          const Text('Attack Log', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: LuvColors.textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: LuvColors.glassMedium, borderRadius: BorderRadius.circular(6)),
            child: Text('${logs.length}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: LuvColors.textMuted)),
          ),
          const Spacer(),
          Text('Tap untuk detail', style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
        ]),
        const SizedBox(height: 12),
        ...logs.take(25).toList().asMap().entries.map((e) => _buildLogRow(e.value, e.key)),
      ]),
    );
  }

  static const _typeEmoji = {
    'XSS': '💉', 'SQL_INJECTION': '🗄️', 'COMMAND_INJECTION': '💻',
    'PATH_TRAVERSAL': '📂', 'RATE_LIMIT_EXCEEDED': '⚡', 'BOT_PROBE': '🤖',
    'SUSPICIOUS_PAYLOAD': '⚠️', 'DOM_INJECTION': '🌐',
    'MANUAL_UNBLOCK': '🔓', 'MANUAL_BLOCK': '🔒',
  };

  static const _sevColor = {
    'LOW': Color(0xFF6B7280), 'MEDIUM': Color(0xFFF59E0B),
    'HIGH': Color(0xFFEF4444), 'CRITICAL': Color(0xFFDC2626),
  };

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
  }

  String _formatTimestamp(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return '-';
    return _relativeTime(dt);
  }

  String _formatTimestampFull(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  Widget _buildLogRow(Map<String, dynamic> log, int index) {
    final severity = (log['severity'] ?? 'LOW').toString();
    final color = _sevColor[severity] ?? const Color(0xFF6B7280);
    final type = (log['attack_type'] ?? 'UNKNOWN').toString();
    final emoji = _typeEmoji[type] ?? '🔍';
    final ip = (log['ip'] ?? '-').toString();
    final timeRel = _formatTimestamp(log['timestamp']?.toString());
    final timeFull = _formatTimestampFull(log['timestamp']?.toString());
    final action = (log['action_taken'] ?? 'LOG').toString();
    final isExpanded = _expandedLog == index;

    return GestureDetector(
      onTap: () => setState(() => _expandedLog = isExpanded ? null : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isExpanded ? color.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.02),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Severity left bar
            Container(
              width: 3, height: 36,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: color.withValues(alpha: 0.7),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)],
              ),
            ),
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(type.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 2),
              Row(children: [
                Text(ip, style: TextStyle(fontSize: 9, color: LuvColors.textMuted, fontFamily: 'monospace')),
                Text(' • ', style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
                Text(timeRel, style: TextStyle(fontSize: 9, color: LuvColors.textMuted)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(severity, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: action == 'BLOCK' ? LuvColors.error.withValues(alpha: 0.1) : LuvColors.glassMedium,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(action, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: action == 'BLOCK' ? LuvColors.error : LuvColors.textMuted)),
              ),
            ]),
          ]),
          // Expanded detail panel
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
                _detailRow('Waktu', timeFull),
                if (log['url'] != null) _detailRow('URL', log['url'].toString()),
                if (log['method'] != null) _detailRow('Method', log['method'].toString()),
                if (log['country'] != null) _detailRow('Lokasi', '${log['country']} ${log['city'] ?? ''}'),
                if (log['source'] != null) _detailRow('Source', log['source'].toString()),
                if (log['detection_reason'] != null) _detailRow('Deteksi', log['detection_reason'].toString()),
                if (log['user_agent'] != null) ...[
                  const SizedBox(height: 4),
                  Text('USER AGENT', style: TextStyle(fontSize: 7, color: LuvColors.accent.withValues(alpha: 0.4), fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(log['user_agent'].toString(), style: TextStyle(fontSize: 8, color: LuvColors.textMuted, fontFamily: 'monospace'), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                if (log['payload_summary'] != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: LuvColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: LuvColors.error.withValues(alpha: 0.1)),
                    ),
                    child: Text(log['payload_summary'].toString(), style: const TextStyle(fontSize: 9, color: LuvColors.error, fontFamily: 'monospace'), maxLines: 4, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ]),
            ),
          ],
        ]),
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
