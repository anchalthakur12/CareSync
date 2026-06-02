import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/health_log.dart';
import '../services/api_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<HealthLog> _logs = [];
  bool _loading = true;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getLogs();
      if (mounted) {
        setState(() {
          _logs = data.map((l) => HealthLog.fromJson(l as Map<String, dynamic>)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<HealthLog> get _filtered {
    if (_filter == null) return _logs;
    return _logs.where((l) => l.status == _filter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'taken': return AppColors.green;
      case 'missed': return AppColors.red;
      case 'skipped': return AppColors.orange;
      default: return AppColors.textMuted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'taken': return Icons.check_circle;
      case 'missed': return Icons.cancel;
      case 'skipped': return Icons.skip_next;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final takenCount = _logs.where((l) => l.isTaken).length;
    final missedCount = _logs.where((l) => l.isMissed).length;
    final skippedCount = _logs.where((l) => l.isSkipped).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.teal,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSummaryCards(takenCount, missedCount, skippedCount),
                          const SizedBox(height: 20),
                          _buildFilterRow(),
                        ],
                      ),
                    ),
                  ),
                  _filtered.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history, color: AppColors.border, size: 56),
                                const SizedBox(height: 12),
                                Text('No logs found', style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 16)),
                              ],
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _buildLogItem(_filtered[i], i == _filtered.length - 1),
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards(int taken, int missed, int skipped) {
    return Row(
      children: [
        Expanded(child: _summaryCard('Taken', taken, Icons.check_circle, AppColors.green)),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('Missed', missed, Icons.cancel, AppColors.red)),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard('Skipped', skipped, Icons.skip_next, AppColors.orange)),
      ],
    );
  }

  Widget _summaryCard(String label, int count, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => setState(() => _filter = _filter == label.toLowerCase() ? null : label.toLowerCase()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _filter == label.toLowerCase() ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _filter == label.toLowerCase() ? color : AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: _filter == label.toLowerCase() ? Colors.white : color, size: 22),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _filter == label.toLowerCase() ? Colors.white : AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _filter == label.toLowerCase() ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Text(
          'Health Log History',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const Spacer(),
        if (_filter != null)
          TextButton.icon(
            onPressed: () => setState(() => _filter = null),
            icon: const Icon(Icons.clear, size: 16),
            label: Text('Clear', style: GoogleFonts.poppins(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AppColors.teal),
          ),
      ],
    );
  }

  Widget _buildLogItem(HealthLog log, bool isLast) {
    final color = _statusColor(log.status);
    final icon = _statusIcon(log.status);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.medicineName,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(log.logDate, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      log.status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
