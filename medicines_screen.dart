import '../services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';   

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => MedicinesScreenState();
}



class MedicinesScreenState extends State<MedicinesScreen> {
  void showAddDialog() => _showAddDialog();

  List<Medicine> _medicines = [];
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
    final data = await ApiService.getMedicines();

    if (mounted) {
      final meds = data
          .map((m) => Medicine.fromJson(m as Map<String, dynamic>))
          .toList();

      setState(() {
        _medicines = meds;
        _loading = false;
      });

      await NotificationService.refreshStockAlerts(meds);
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

  Future<void> _deleteMedicine(Medicine med) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Medicine',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove "${med.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteMedicine(med.id);
      await _load();
    }
  }

  Future<void> _logDose(Medicine med, String status) async {
    try {
      await ApiService.logDose(medicineId: med.id, status: status);

      if (status == 'missed') {
        await ApiService.markMissed(med.id, med.name);
      }
      await _load();
      await NotificationService.refreshStockAlerts(_medicines);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged as $status!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: status == 'taken' ? AppColors.green : AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error logging dose',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _timeOfDayTo24h(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final totalPillsCtrl = TextEditingController();
    final pillsPerDoseCtrl = TextEditingController(text: '1');
    final conditionCtrl = TextEditingController();

    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    final formKey = GlobalKey<FormState>();
    bool saving = false;
    String? errorMsg;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx2).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: AppColors.tealGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Add Medicine',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _inputField(
                        nameCtrl,
                        'Medicine Name *',
                        Icons.medication_outlined,
                        validator: (v) =>
                            v!.trim().isNotEmpty ? null : 'Please enter medicine name',
                      ),
                      const SizedBox(height: 12),

                      _inputField(
                        dosageCtrl,
                        'Dosage (e.g. 500mg) *',
                        Icons.science_outlined,
                        validator: (v) =>
                            v!.trim().isNotEmpty ? null : 'Please enter dosage',
                      ),
                      const SizedBox(height: 12),

                      _inputField(
                        totalPillsCtrl,
                        'Total Pills in Bottle *',
                        Icons.inventory_2_outlined,
                        validator: (v) =>
                            int.tryParse(v!.trim()) != null ? null : 'Enter pill count',
                      ),
                      const SizedBox(height: 12),

                      _inputField(
                        pillsPerDoseCtrl,
                        'Pills Per Dose',
                        Icons.medication_liquid_outlined,
                        validator: (v) =>
                            int.tryParse(v!.trim()) != null ? null : 'Enter pills per dose',
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Time',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx2,
                            initialTime: selectedTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.teal,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Color(0xFF2D3748),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (picked != null) {
                            setModalState(() => selectedTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: AppColors.teal,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _formatTimeOfDay(selectedTime),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _inputField(
                        conditionCtrl,
                        'Condition / Notes (optional)',
                        Icons.note_outlined,
                      ),

                      const SizedBox(height: 12),

                      if (errorMsg != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Color(0xFFE74C3C),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMsg!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFFE74C3C),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (errorMsg != null) const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                setModalState(() {
                                  saving = true;
                                  errorMsg = null;
                                });

                                try {
                                  await ApiService.addMedicine(
                                    name: nameCtrl.text.trim(),
                                    dosage: dosageCtrl.text.trim(),
                                    time: _timeOfDayTo24h(selectedTime),
                                    condition: conditionCtrl.text.trim(),
                                    totalPills: int.tryParse(totalPillsCtrl.text.trim()),
                                    pillsPerDose:
                                        int.tryParse(pillsPerDoseCtrl.text.trim()) ?? 1,
                                  );


                                 
                                  await _load();

                                  final updated = await ApiService.getMedicines();
                                  final meds = updated
                                      .map((m) => Medicine.fromJson(m as Map<String, dynamic>))
                                      .toList();

                                  await NotificationService.scheduleAllReminders(meds);

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Medicine added successfully!',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: AppColors.teal,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }

                                  await _load();
                                } catch (e) {
                                  setModalState(() {
                                    saving = false;
                                    errorMsg =
                                        e.toString().replaceAll('Exception: ', '');
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Add Medicine',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.textMuted,
          size: 20,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.teal,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Color _timeColor(String time) {
    final parts = time.split(':');

    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 8;
      if (hour >= 5 && hour < 12) return AppColors.orange;
      if (hour >= 12 && hour < 17) return AppColors.teal;
      if (hour >= 17 && hour < 21) return AppColors.blue;
      return AppColors.navy;
    }

    switch (time) {
      case 'morning':
        return AppColors.orange;
      case 'afternoon':
        return AppColors.teal;
      case 'evening':
        return AppColors.blue;
      case 'night':
        return AppColors.navy;
      default:
        return AppColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isWide
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(
                'Add Medicine',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            )
          : null,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.teal),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: AppColors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.teal,
                  child: _medicines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                color: AppColors.border,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No medicines yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the button below to add your first medicine',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _medicines.length,
                          itemBuilder: (ctx, i) =>
                              _buildMedicineCard(_medicines[i]),
                        ),
                ),
    );
  }

  Widget _buildMedicineCard(Medicine med) {
    final tColor = _timeColor(med.time);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: AppColors.teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        med.dosage,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          _tag(Icons.access_time, med.timeLabel, tColor),
                          const SizedBox(width: 8),
                          if (med.condition.isNotEmpty)
                            _tag(
                              Icons.medical_information,
                              med.condition,
                              AppColors.blue,
                            ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      if (med.remainingPills != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: med.lowStock
                                ? AppColors.red.withOpacity(0.12)
                                : AppColors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: med.lowStock
                                  ? AppColors.red.withOpacity(0.4)
                                  : AppColors.green.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                med.lowStock
                                    ? Icons.warning_amber_rounded
                                    : Icons.inventory_2_outlined,
                                size: 14,
                                color: med.lowStock
                                    ? AppColors.red
                                    : AppColors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                med.lowStock
                                    ? 'Low stock: ${med.remainingPills} pills left'
                                    : '${med.remainingPills} pills left',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: med.lowStock
                                      ? AppColors.red
                                      : AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                PopupMenuButton<String>(
                  onSelected: (v) => _deleteMedicine(med),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: AppColors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remove',
                            style: GoogleFonts.poppins(
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _logDose(med, 'taken'),
                    icon: const Icon(
                      Icons.check_circle,
                      color: AppColors.green,
                      size: 18,
                    ),
                    label: Text(
                      'Taken',
                      style: GoogleFonts.poppins(
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.border,
                ),

                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _logDose(med, 'missed'),
                    icon: const Icon(
                      Icons.cancel,
                      color: AppColors.red,
                      size: 18,
                    ),
                    label: Text(
                      'Missed',
                      style: GoogleFonts.poppins(
                        color: AppColors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}