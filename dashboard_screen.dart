import '../widgets/low_stock_assistant.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../models/medicine.dart';
import '../widgets/low_stock_assistant.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../services/notification_service.dart';
import '../models/medicine.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllMedicines;
  const DashboardScreen({super.key, this.onViewAllMedicines});
  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}
class DashboardScreenState extends State<DashboardScreen> {

  int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
  void refresh() => _load();
  Map<String, dynamic>? _data;
  List<dynamic> _reminders = [];
  List<Medicine> _medicines = [];
  bool _loading = true;
  String? _error;
  static const _teal = Color(0xFF3BBFB2);
  static const _bgColor = Color(0xFFF4F7FB);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getDashboard();
      List<dynamic> reminders = [];
            try {
              final remData = await ApiService.getReminders();
              reminders = (remData['schedule'] as List?)
                  ?? (remData['reminders'] as List?)
                  ?? (remData['data'] as List?)
                  ?? [];
            } catch (_) {}
            List<Medicine> meds = [];
            try {
              final medData = await ApiService.getMedicines();
              meds = medData
                  .map((m) => Medicine.fromJson(m as Map<String, dynamic>))
                  .toList();


              print("Medicines count: ${meds.length}");
              for (var m in meds) {
                print("${m.name} → ${m.remainingPills}");
              }

            } catch (_) {}
            if (mounted) setState(() {
              _data = data;
              _reminders = reminders;
              _medicines = meds;
              _loading = false;
            });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF3BBFB2)));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Color(0xFFE57373), size: 48),
        const SizedBox(height: 16),
        Text('Failed to load dashboard', style: GoogleFonts.poppins(fontSize: 15)),
        const SizedBox(height: 8),
        TextButton(onPressed: _load, child: Text('Retry', style: GoogleFonts.poppins(color: _teal, fontWeight: FontWeight.w600))),
      ]));
    }

    final userName = context.watch<AuthProvider>().user?.name ?? '';
    final riskLevel = (_data?['risk_level'] ?? 'Low').toString();
    final riskMsg = (_data?['risk_msg'] ?? '').toString();
    final adherence = _toDouble(_data?['adherence'] ?? _data?['adherence_rate'] ?? 0);
    final total = _toInt(_data?['total'] ?? _data?['total_medicines'] ?? _data?['medicines_count'] ?? 0);
    final taken = _toInt(_data?['today_taken'] ?? _data?['taken'] ?? 0);
    final missed = _toInt(_data?['today_missed'] ?? _data?['missed'] ?? 0);

    return Container(
      color: _bgColor,
      child: RefreshIndicator(
        onRefresh: _load,
        color: _teal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeroBanner(adherence, userName),
                            Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  LowStockAssistant(medicines: _medicines),


                  _buildStatsGrid(total, taken, missed, adherence),
                const SizedBox(height: 16),
                _buildAdherenceCard(adherence),
                const SizedBox(height: 16),
                _buildRiskCard(riskLevel, riskMsg),
                const SizedBox(height: 16),
                _buildScheduleCard(),
                const SizedBox(height: 24),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(double adherence, String userName) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1FA8A0), Color(0xFF3BBFB2), Color(0xFF4ECDC0)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(userName.isNotEmpty ? '$greeting, $userName!' : '$greeting!',
              style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.92), fontSize: 13)),
          const SizedBox(height: 4),
          Text('Stay on track today',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 14),
              const SizedBox(width: 5),
                            Flexible(
                child: Text('${adherence.toStringAsFixed(0)}% Adherence This Month',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ])),
        const SizedBox(width: 6),
        SizedBox(width: 100, height: 100, child: CustomPaint(painter: _ClipboardPainter())),
      ]),
    );
  }

  Widget _buildStatsGrid(int total, int taken, int missed, double adherence) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
      children: [
        _statCard(value: '$total', label: 'Medicines', sublabel: 'Total Medicines',
            icon: Icons.medical_services, iconBg: const Color(0xFFDDEEFA), iconColor: const Color(0xFF4A90D9), bgColor: Colors.white),
        _statCard(value: '$taken', label: 'Taken Today', sublabel: 'On Track',
            icon: Icons.check_circle, iconBg: const Color(0xFFDFF6EC), iconColor: const Color(0xFF27AE60), bgColor: const Color(0xFFF4FDF9), isCircle: true),
        _statCard(value: '$missed', label: 'Missed Today', sublabel: 'Take them soon',
            icon: Icons.cancel, iconBg: const Color(0xFFFFE8E8), iconColor: const Color(0xFFE74C3C), bgColor: const Color(0xFFFFF8F8), isCircle: true),
        _statCard(value: '${adherence.toStringAsFixed(0)}%', label: 'Adherence', sublabel: 'This Month',
            icon: Icons.bar_chart_rounded, iconBg: const Color(0xFFEAEEFA), iconColor: const Color(0xFF7B8EC8), bgColor: const Color(0xFFF7F8FD)),
      ],
    );
  }

  Widget _statCard({
    required String value, required String label, required String sublabel,
    required IconData icon, required Color iconBg, required Color iconColor,
    required Color bgColor, bool isCircle = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2A3A4A), height: 1.1)),
        ]),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2A3A4A))),
        Text(sublabel, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9DB2C8))),
      ]),
    );
  }

  Widget _buildAdherenceCard(double rate) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Monthly Adherence', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF2A3A4A))),
        const SizedBox(height: 20),
        Row(children: [
          SizedBox(
            width: 130, height: 130,
            child: CustomPaint(
              painter: _CircleChartPainter(rate / 100),
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${rate.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: _adherenceColor(rate))),
                Text('Adherence', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9DB2C8))),
              ])),
            ),
          ),
          const SizedBox(width: 28),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _legendItem('Excellent', '> 90%', const Color(0xFF27AE60)),
            const SizedBox(height: 14),
            _legendItem('Good', '70 - 90%', _teal),
            const SizedBox(height: 14),
            _legendItem('Fair', '50 - 70%', const Color(0xFFF39C12)),
            const SizedBox(height: 14),
            _legendItem('Poor', '< 50%', const Color(0xFFE74C3C)),
          ])),
        ]),
      ]),
    );
  }

  Widget _legendItem(String label, String range, Color color) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2A3A4A))),
        Text(range, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9DB2C8))),
      ]),
    ]);
  }

  Color _adherenceColor(double rate) {
    if (rate >= 90) return const Color(0xFF27AE60);
    if (rate >= 70) return _teal;
    if (rate >= 50) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }



  Widget _buildRiskCard(String riskLevel, String riskMsg) {
  final color = _riskColor(riskLevel);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.health_and_safety, color: color, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$riskLevel Risk',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                riskMsg.isNotEmpty ? riskMsg : 'Risk is calculated from your medicine adherence.',
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9DB2C8)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Color _riskColor(String riskLevel) {
  final value = riskLevel.toLowerCase();
  if (value == 'low') return const Color(0xFF27AE60);
  if (value == 'medium') return const Color(0xFFF39C12);
  return const Color(0xFFE74C3C);
}

  Widget _buildScheduleCard() {
    final todayReminders = _reminders.where((r) {
      final s = r['status']?.toString() ?? '';
      return s == 'pending' || s == 'taken' || s == 'missed';
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(
            child: Text("Today's Schedule",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF2A3A4A)),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onViewAllMedicines,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('View All', style: GoogleFonts.poppins(fontSize: 13, color: _teal, fontWeight: FontWeight.w500)),
              const Icon(Icons.chevron_right, color: _teal, size: 18),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        if (todayReminders.isEmpty)
          _buildEmptySchedule()
        else
          ListView.separated(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: todayReminders.length > 5 ? 5 : todayReminders.length,
            separatorBuilder: (_, __) => const Divider(height: 24, color: Color(0xFFF0F4F8)),
            itemBuilder: (ctx, i) => _scheduleItem(todayReminders[i] as Map<String, dynamic>),
          ),
      ]),
    );
  }

  Widget _buildEmptySchedule() {
    final medicines = (_data?['today_medicines'] as List?) ?? [];
    if (medicines.isNotEmpty) {
      return ListView.separated(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: medicines.length > 5 ? 5 : medicines.length,
        separatorBuilder: (_, __) => const Divider(height: 24, color: Color(0xFFF0F4F8)),
        itemBuilder: (ctx, i) => _simpleMedItem(medicines[i] as Map<String, dynamic>),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(child: Column(children: [
        const Icon(Icons.calendar_today_outlined, color: Color(0xFF9DB2C8), size: 36),
        const SizedBox(height: 8),
        Text('No medicines scheduled for today', style: GoogleFonts.poppins(color: const Color(0xFF9DB2C8), fontSize: 13)),
      ])),
    );
  }

  Widget _scheduleItem(Map<String, dynamic> reminder) {
    final name = reminder['medicine_name']?.toString() ?? reminder['name']?.toString() ?? 'Medicine';
    final time = reminder['scheduled_time']?.toString() ?? reminder['time']?.toString() ?? '';
    final instructions = reminder['instructions']?.toString() ?? reminder['dosage']?.toString() ?? '';
    final isTaken = reminder['status']?.toString() == 'taken';
    return Row(children: [
      _pillIcon(isTaken),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF2A3A4A))),
        Text(instructions, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9DB2C8))),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(time, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600,
            color: isTaken ? const Color(0xFF27AE60) : const Color(0xFF2A3A4A))),
        const SizedBox(height: 4),
        Icon(isTaken ? Icons.check_circle_outline : Icons.access_time,
            color: isTaken ? const Color(0xFF27AE60) : const Color(0xFF9DB2C8), size: 18),
      ]),
    ]);
  }

  Widget _simpleMedItem(Map<String, dynamic> med) {
    final name = med['name']?.toString() ?? '';
    final dosage = med['dosage']?.toString() ?? '';
    final time = med['time']?.toString() ?? '';
    return Row(children: [
      _pillIcon(false),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF2A3A4A))),
        Text(dosage, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9DB2C8))),
      ])),
      if (time.isNotEmpty)
        Row(children: [
          Text(time, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2A3A4A))),
          const SizedBox(width: 6),
          const Icon(Icons.access_time, color: Color(0xFF9DB2C8), size: 18),
        ]),
    ]);
  }

  Widget _pillIcon(bool isTaken) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(14)),
      child: CustomPaint(painter: _PillPainter(isTaken)),
    );
  }
}

class _PillPainter extends CustomPainter {
  final bool isTaken;
  _PillPainter(this.isTaken);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.6;
    final h = size.height * 0.28;
    final r = h / 2;
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(cx - w / 2, cy - r, cx, cy + r,
          topLeft: Radius.circular(r), bottomLeft: Radius.circular(r)),
      Paint()..color = isTaken ? const Color(0xFF27AE60) : const Color(0xFFE8845A),
    );
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(cx, cy - r, cx + w / 2, cy + r,
          topRight: Radius.circular(r), bottomRight: Radius.circular(r)),
      Paint()..color = isTaken ? const Color(0xFF52CFB5) : const Color(0xFFF4A77E),
    );
  }

  @override
  bool shouldRepaint(_PillPainter old) => old.isTaken != isTaken;
}

class _CircleChartPainter extends CustomPainter {
  final double value;
  _CircleChartPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    canvas.drawCircle(center, radius,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 14..color = const Color(0xFFE8F0F8));
    Color arcColor;
    if (value >= 0.9) arcColor = const Color(0xFF27AE60);
    else if (value >= 0.7) arcColor = const Color(0xFF3BBFB2);
    else if (value >= 0.5) arcColor = const Color(0xFFF39C12);
    else arcColor = const Color(0xFFE74C3C);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * value, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round..color = arcColor,
    );
  }

  @override
  bool shouldRepaint(_CircleChartPainter old) => old.value != value;
}

class _ClipboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.14, w * 0.78, h * 0.82), const Radius.circular(12)),
        Paint()..color = Colors.black.withOpacity(0.18));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.06, h * 0.08, w * 0.78, h * 0.82), const Radius.circular(12)),
        Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.0, w * 0.34, h * 0.18), const Radius.circular(8)),
        Paint()..color = const Color(0xFF2DB9B0));
    final cp = Paint()..color = const Color(0xFF3BBFB2)..strokeWidth = 3.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.32, h * 0.5), Offset(w * 0.60, h * 0.5), cp);
    canvas.drawLine(Offset(w * 0.46, h * 0.36), Offset(w * 0.46, h * 0.64), cp);
    canvas.drawCircle(Offset(w * 0.77, h * 0.77), w * 0.16, Paint()..color = const Color(0xFF27AE60));
    final path = Path()..moveTo(w * 0.69, h * 0.77)..lineTo(w * 0.75, h * 0.83)..lineTo(w * 0.85, h * 0.70);
    canvas.drawPath(path, Paint()..color = Colors.white..strokeWidth = 2.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}