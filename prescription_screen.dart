import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  List<Map<String, dynamic>> _prescriptions = [];
  bool _loading = true;
  bool _uploading = false;
  int? _runningOcrId;
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getPrescriptions();
      if (mounted) {
        setState(() {
          _prescriptions = List<Map<String, dynamic>>.from(data['prescriptions'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() => _uploading = true);
    try {
      await ApiService.uploadPrescription(fileName: file.name, bytes: file.bytes!);
      _load();
      if (mounted) _showSnack('Prescription uploaded!', AppColors.green);
    } catch (_) {
      if (mounted) _showSnack('Upload failed. Please try again.', AppColors.red);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _runOcr(int id) async {
    setState(() => _runningOcrId = id);
    try {
      final result = await ApiService.runOcr(id);
      _load();
      if (mounted) {
        final detected = (result['detected'] as List?) ?? [];
        if (detected.isEmpty) {
          _showSnack('No medicines detected. Try a clearer image.', AppColors.orange);
        } else {
          _showSnack('Detected ${detected.length} medicine(s)!', AppColors.green);
        }
      }
    } catch (_) {
      if (mounted) _showSnack('OCR failed. Please try again.', AppColors.red);
    } finally {
      if (mounted) setState(() => _runningOcrId = null);
    }
  }

  Future<void> _deletePrescription(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Delete Prescription', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this prescription?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deletingId = id);
    try {
      await ApiService.deletePrescription(id);
      _load();
      if (mounted) _showSnack('Prescription deleted.', AppColors.textSecondary);
    } catch (_) {
      if (mounted) _showSnack('Delete failed.', AppColors.red);
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  void _showAddMedicineSheet(String detectedLine) {
    final parts = detectedLine.split(' | ');
    final rawName = parts.isNotEmpty ? parts[0].trim() : '';
    final nameMatch = RegExp(
      r'^([A-Za-z][A-Za-z0-9\s/\-+]+?)(?:\s+(\d[\d./]*\s*(?:mg|mcg|ml|g|iu|units?|%)))?$',
      caseSensitive: false,
    ).firstMatch(rawName);
    final medName = nameMatch?.group(1)?.trim() ?? rawName;
    final medDosage = nameMatch?.group(2)?.trim() ?? '';
    final medFreq = parts.length > 1 ? parts[1].trim() : '';
    final medDuration = parts.length > 2 ? parts[2].trim() : '';

    final nameCtrl = TextEditingController(text: medName);
    final dosageCtrl = TextEditingController(text: medDosage);
    final timeCtrl = TextEditingController(text: '08:00');
    final condCtrl = TextEditingController(
      text: [medFreq, medDuration].where((s) => s.isNotEmpty).join(' · '),
    );
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.medication, color: AppColors.teal, size: 20),
                const SizedBox(width: 8),
                Text('Add to Medicines', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy)),
              ]),
              const SizedBox(height: 16),
              _sheetField('Medicine Name', nameCtrl, Icons.local_pharmacy_outlined),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _sheetField('Dosage (e.g. 500mg)', dosageCtrl, Icons.straighten)),
                const SizedBox(width: 10),
                Expanded(child: _sheetField('Time (HH:mm)', timeCtrl, Icons.access_time)),
              ]),
              const SizedBox(height: 10),
              _sheetField('Frequency / Notes', condCtrl, Icons.notes),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setSheetState(() => saving = true);
                          try {
                            await ApiService.addMedicine(
                              name: nameCtrl.text.trim(),
                              dosage: dosageCtrl.text.trim(),
                              time: timeCtrl.text.trim(),
                              condition: condCtrl.text.trim(),
                              totalPills: null,
                              pillsPerDose: 1,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) _showSnack('${nameCtrl.text.trim()} added!', AppColors.green);
                          } catch (e) {
                            setSheetState(() => saving = false);
                            if (ctx.mounted) _showSnack(e.toString(), AppColors.red);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Add Medicine', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.poppins(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        prefixIcon: Icon(icon, size: 18, color: AppColors.teal),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.teal),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.teal,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildUploadCard(),
        const SizedBox(height: 16),
        _buildSectionHeader(Icons.description_outlined, 'My Prescriptions', AppColors.navy),
        const SizedBox(height: 10),
        if (_prescriptions.isEmpty)
          _buildEmpty()
        else
          ..._prescriptions.map(_buildPrescriptionCard),
      ],
    );
  }

  Widget _buildUploadCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.navyGradient, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.document_scanner, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prescription Scanner', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Upload & extract medicines via OCR', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              ],
            )),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.info_outline, color: Colors.white60, size: 14),
            const SizedBox(width: 6),
            Text('Supports JPG, PNG, PDF  ·  Max 10 MB', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: _uploading
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text('Uploading...', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                    ]),
                  )
                : GestureDetector(
                    onTap: _pickAndUpload,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.upload_file, color: AppColors.navy, size: 20),
                        const SizedBox(width: 10),
                        Text('Choose File & Upload', style: GoogleFonts.poppins(color: AppColors.navy, fontWeight: FontWeight.w600, fontSize: 14)),
                      ]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 16),
      ),
      const SizedBox(width: 10),
      Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
    ]);
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Icon(Icons.description_outlined, size: 52, color: AppColors.teal.withOpacity(0.4)),
        const SizedBox(height: 12),
        Text('No prescriptions yet', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Upload a prescription image and we\'ll scan it for medicines automatically.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
      ]),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> presc) {
    final id = presc['id'] as int? ?? 0;
    final name = presc['file_name'] as String? ?? 'Prescription';
    final notes = presc['notes'] as String? ?? '';
    final uploaded = presc['uploaded_at'] as String? ?? '';
    final detected = presc['detected_medicines'] as String?;
    final hasOcr = detected != null && detected.isNotEmpty;
    final isRunning = _runningOcrId == id;
    final isDeleting = _deletingId == id;

    final detectedLines = hasOcr
        ? detected!.split('\n').where((l) => l.trim().isNotEmpty).toList()
        : <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: hasOcr ? AppColors.greenLight : AppColors.blueLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasOcr ? Icons.check_circle_outline : Icons.description_outlined,
                color: hasOcr ? AppColors.green : AppColors.blue, size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (notes.isNotEmpty)
                  Text(notes, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(uploaded.length > 10 ? uploaded.substring(0, 10) : uploaded,
                    style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: hasOcr ? AppColors.greenLight : AppColors.orangeLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(hasOcr ? 'Scanned' : 'Pending',
                  style: GoogleFonts.poppins(fontSize: 10, color: hasOcr ? AppColors.green : AppColors.orange, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isDeleting ? null : () => _deletePrescription(id),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: isDeleting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.red, strokeWidth: 2))
                    : const Icon(Icons.delete_outline, color: AppColors.red, size: 18),
              ),
            ),
          ]),
        ),
        if (hasOcr && detectedLines.isNotEmpty) ...[
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Row(children: [
              const Icon(Icons.medication_outlined, color: AppColors.teal, size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text('Detected Medicines', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal))),
              GestureDetector(
                onTap: isRunning ? null : () => _runOcr(id),
                child: isRunning
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.refresh, color: AppColors.teal, size: 14),
                        const SizedBox(width: 3),
                        Text('Re-scan', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w600)),
                      ]),
              ),
            ]),
          ),
          ...detectedLines.take(10).map((line) {
            final parts = line.trim().split(' | ');
            return Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.tealLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.teal.withOpacity(0.15)),
              ),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parts[0], style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    if (parts.length > 1)
                      Text(parts.sublist(1).join('  ·  '),
                          style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                  ],
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showAddMedicineSheet(line.trim()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add, color: Colors.white, size: 14),
                      const SizedBox(width: 3),
                      Text('Add', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            );
          }),
          const SizedBox(height: 8),
        ],
        if (!hasOcr) ...[
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: GestureDetector(
              onTap: isRunning ? null : () => _runOcr(id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isRunning ? AppColors.border : AppColors.tealLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.teal.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: isRunning
                      ? [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text('Running OCR...', style: GoogleFonts.poppins(color: AppColors.teal, fontSize: 13)),
                        ]
                      : [
                          const Icon(Icons.document_scanner, color: AppColors.teal, size: 18),
                          const SizedBox(width: 8),
                          Text('Scan for Medicines', style: GoogleFonts.poppins(color: AppColors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}