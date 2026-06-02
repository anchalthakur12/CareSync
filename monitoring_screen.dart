
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  static const _teal = Color(0xFF3BBFB2);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final patientCode = user?.patientCode as String?;
    final isPatient = (user?.role ?? '').toLowerCase() == 'patient';
    return Container(
      color: const Color(0xFFF4F7FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPatient) _buildCodeBanner(context, patientCode),
            if (isPatient) const SizedBox(height: 20),
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: const Color(0xFFE4F7F5),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.people_alt_outlined, color: _teal, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Approved Monitors (1)',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A2D3E)),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Column(children: [
                Icon(Icons.people_outline_rounded,
                    size: 56, color: _teal.withOpacity(0.35)),
                const SizedBox(height: 16),
                Text('1 monitor connected',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2D3E))),
                const SizedBox(height: 8),
                Text(
                  // 'Share your patient code above with your\ndoctor or family member so they can\nrequest access.',
                  'Your family member is connected and can monitor patient information.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFF7A8FA6), height: 1.5),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeBanner(BuildContext context, String? code) {
    final displayCode = (code != null && code.isNotEmpty) ? code : '—';

    return GestureDetector(
      onTap: code != null && code.isNotEmpty
          ? () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Patient code copied!',
                    style: GoogleFonts.poppins()),
                backgroundColor: _teal,
                duration: const Duration(seconds: 2),
              ));
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3BBFB2), Color(0xFF2AAFA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF3BBFB2).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Patient Code',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(displayCode,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.bold, letterSpacing: 3)),
            const SizedBox(height: 4),
            Text('Share with doctors & family members',
                style: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 12)),
          ])),
          if (code != null && code.isNotEmpty)
            const Icon(Icons.copy_rounded, color: Colors.white60, size: 18),
        ]),
      ),
    );
  }
}