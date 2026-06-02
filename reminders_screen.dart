

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getReminders();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _logDose(int medId, String status) async {
    try {
      await ApiService.logDose(medicineId: medId, status: status);
      _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'taken' ? 'Dose marked as taken!' : 'Dose marked as missed',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: status == 'taken' ? AppColors.green : AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.teal,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Could not load reminders',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text('Retry', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final schedule = (_data?['schedule'] as List?) ?? [];
 
    final notifications = (_data?['notifications'] as List?) ?? [];

    final summary = (_data?['summary'] as Map?) ?? {};
    final today = _data?['today'] as String? ?? '';

    final pending = summary['pending'] as int? ?? 0;
    final taken = summary['taken'] as int? ?? 0;
    final missed = summary['missed'] as int? ?? 0;
    final total = summary['total'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDateBanner(today, pending, taken, missed, total),
        const SizedBox(height: 16),

        if (pending > 0) _buildUrgentBanner(pending),

        if (schedule.isEmpty)
          _buildEmptySchedule()
        else ...[
          _buildSectionHeader(Icons.schedule_outlined, "Today's Medicine Schedule", AppColors.navy),
          const SizedBox(height: 10),
          ...schedule.map((s) => _buildScheduleCard(s as Map<String, dynamic>)),
        ],

        const SizedBox(height: 16),
        _buildSectionHeader(Icons.notifications_outlined, 'Medicine Notifications', AppColors.orange),
        const SizedBox(height: 10),

        if (notifications.isEmpty)
          _buildNoNotifications()
        else
          ...notifications.take(10).map((n) => _buildNotificationCard(n as Map<String, dynamic>)),

        const SizedBox(height: 16),
        _buildTipsCard(),
      ],
    );
  }

  Widget _buildDateBanner(String today, int pending, int taken, int missed, int total) {
    final now = DateTime.now();
    final weekday = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][now.weekday - 1];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '$weekday, ${months[now.month - 1]} ${now.day}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medicine Reminders',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (total > 0)
            Row(
              children: [
                _summaryPill(taken.toString(), 'Taken', AppColors.greenLight, AppColors.green),
                const SizedBox(width: 10),
                _summaryPill(pending.toString(), 'Pending', AppColors.orangeLight, AppColors.orange),
                const SizedBox(width: 10),
                _summaryPill(missed.toString(), 'Missed', AppColors.redLight, AppColors.red),
              ],
            )
          else
            Text(
              'No medicines scheduled for today',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _summaryPill(String count, String label, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.poppins(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(color: fg, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgentBanner(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orangeLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.orange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm, color: AppColors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count medicine${count == 1 ? '' : 's'} still pending today. Don\'t forget to log your doses!',
              style: GoogleFonts.poppins(
                color: AppColors.orange,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.medication_outlined, size: 52, color: AppColors.teal.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'No medicines added yet',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your medicines in the Medicines tab to see your daily reminders here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> item) {
    final status = item['status'] as String? ?? 'pending';
    final name = item['name'] as String? ?? '';
    final dosage = item['dosage'] as String? ?? '';
    final time = _formatMedicineTime(item['time']?.toString() ?? '');
    final id = item['id'] as int? ?? 0;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    Color statusBg;

    switch (status) {
      case 'taken':
        statusColor = AppColors.green;
        statusBg = AppColors.greenLight;
        statusIcon = Icons.check_circle;
        statusLabel = 'Taken';
        break;
      case 'missed':
        statusColor = AppColors.red;
        statusBg = AppColors.redLight;
        statusIcon = Icons.cancel;
        statusLabel = 'Missed';
        break;
      default:
        statusColor = AppColors.navy;
        statusBg = AppColors.purpleLight;
        statusIcon = Icons.alarm;
        statusLabel = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: status == 'pending'
              ? AppColors.navy.withOpacity(0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.medication, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          dosage,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _logDose(id, 'taken'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.green.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, color: AppColors.green, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Mark Taken',
                            style: GoogleFonts.poppins(
                              color: AppColors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _logDose(id, 'missed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.redLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.red.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.close, color: AppColors.red, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Missed',
                            style: GoogleFonts.poppins(
                              color: AppColors.red,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoNotifications() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none, color: AppColors.textMuted, size: 28),
          const SizedBox(width: 14),
          Text(
            'No medicine reminders right now',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    final title = notif['title'] as String? ?? '';
    final message = notif['message'] as String? ?? '';
    final type = (notif['notif_type'] ?? notif['type'] ?? 'reminder').toString();
    final isRead = notif['is_read'] as bool? ?? false;

    Color color;
    IconData icon;
    Color bg;

    switch (type) {
      case 'reminder':
        color = AppColors.teal;
        icon = Icons.medication_outlined;
        bg = AppColors.tealLight;
        break;
      case 'missed_dose':
        color = AppColors.red;
        icon = Icons.medication_outlined;
        bg = AppColors.redLight;
        break;
      case 'warning':
        color = AppColors.orange;
        icon = Icons.warning_amber_outlined;
        bg = AppColors.orangeLight;
        break;
      case 'success':
        color = AppColors.green;
        icon = Icons.check_circle_outline;
        bg = AppColors.greenLight;
        break;
      default:
        color = AppColors.blue;
        icon = Icons.info_outline;
        bg = AppColors.blueLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : bg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? AppColors.border : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          if (!isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      'Take medicines at the same time every day to build a routine.',
      'Keep your medicines visible — place them near your toothbrush or breakfast.',
      'Use your phone\'s built-in alarm as a backup reminder.',
      'Never skip a dose without consulting your doctor first.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purpleLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: AppColors.purple, size: 18),
              const SizedBox(width: 8),
              Text(
                'Adherence Tips',
                style: GoogleFonts.poppins(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
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

  DateTime? _parseMedicineTime(String rawTime) {
    final text = rawTime.trim();
    if (text.isEmpty) return null;

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$',
      caseSensitive: false,
    ).firstMatch(text);

    if (match == null) return null;

    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final period = match.group(3)?.toUpperCase();

    if (hour == null || minute == null) return null;

    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _formatMedicineTime(String rawTime) {
    final scheduled = _parseMedicineTime(rawTime);
    if (scheduled == null) return rawTime;

    final hour12 = scheduled.hour == 0
        ? 12
        : scheduled.hour > 12
            ? scheduled.hour - 12
            : scheduled.hour;

    final minute = scheduled.minute.toString().padLeft(2, '0');
    final period = scheduled.hour >= 12 ? 'PM' : 'AM';

    return '$hour12:$minute $period';
  }
}