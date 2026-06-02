
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(int)? onNavigateToTab;
  const ProfileScreen({super.key, this.onNavigateToTab});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _teal = Color(0xFF3BBFB2);
  static const _bgLight = Color(0xFFF4F7FB);
  bool _notifMedicines = true;
  bool _notifReminders = true;
  bool _notifHealth = false;
  String _selectedLanguage = 'English';

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    if (mounted) await context.read<AuthProvider>().setAvatar(dataUrl);
  }

  Future<void> _removeAvatar() async {
    await context.read<AuthProvider>().setAvatar(null);
  }

  void _logout() {
    if (!mounted) return;
    Provider.of<AuthProvider>(context, listen: false).logout();
  }

  void _showEditProfile(dynamic user) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    bool saving = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E6F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Edit Profile', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 20),
            Text('Full Name', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7A8FA6))),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                filled: true, fillColor: _bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  setSheetState(() => saving = true);
                  try {
                    await ApiService.updateProfile(name: name);
                    if (!ctx.mounted) return;
                    context.read<AuthProvider>().updateName(name);
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Profile updated', style: GoogleFonts.poppins()),
                        backgroundColor: _teal,
                      ));
                    }
                  } catch (e) {
                    setSheetState(() => saving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Failed to update profile'),
                        backgroundColor: Color(0xFFE74C3C),
                      ));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Save Changes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }

  void _showPhotoOptions(String? avatarDataUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE0E6F0), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Profile Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 12),
        ListTile(
          leading: Container(width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFE8F8F7), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.upload_rounded, color: _teal, size: 20)),
          title: Text('Upload Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          subtitle: Text('JPG, PNG supported',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9DB2C8))),
          onTap: () { Navigator.pop(ctx); _pickAvatar(); },
        ),
        if (avatarDataUrl != null)
          ListTile(
            leading: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFFFEBEB), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_outline, color: Color(0xFFE74C3C), size: 20)),
            title: Text('Remove Photo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: const Color(0xFFE74C3C))),
            onTap: () { Navigator.pop(ctx); _removeAvatar(); },
          ),
        const SizedBox(height: 8),
      ])),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE0E6F0), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Settings', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _settingsTile(Icons.notifications_outlined, 'Notifications', 'Manage reminder alerts',
              onTap: () { Navigator.pop(ctx); _showNotificationsSheet(); }),
          _settingsTile(Icons.lock_outline, 'Privacy', 'Control your data sharing',
              onTap: () { Navigator.pop(ctx); _showPrivacySheet(); }),
          _settingsTile(Icons.language_outlined, 'Language', _selectedLanguage,
              onTap: () { Navigator.pop(ctx); _showLanguageSheet(); }),
          _settingsTile(Icons.info_outline_rounded, 'App Version', '1.0.0',
              onTap: () { Navigator.pop(ctx); _showAppVersionDialog(); }),
        ]),
      )),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E6F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            _toggleTile('Medicine Reminders', 'Alert when it\'s time for medicine', _notifMedicines, (v) {
              setS(() => _notifMedicines = v);
              setState(() => _notifMedicines = v);
            }),
            const Divider(height: 1, color: Color(0xFFEEF2F7)),
            _toggleTile('Daily Reminders', 'Morning and evening check-in alerts', _notifReminders, (v) {
              setS(() => _notifReminders = v);
              setState(() => _notifReminders = v);
            }),
            const Divider(height: 1, color: Color(0xFFEEF2F7)),
            _toggleTile('Health Tips', 'Receive daily health tips', _notifHealth, (v) {
              setS(() => _notifHealth = v);
              setState(() => _notifHealth = v);
            }),
          ]),
        )),
      ),
    );
  }

  Widget _toggleTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A2D3E))),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7A8FA6))),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: _teal),
      ]),
    );
  }

  void _showPrivacySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE0E6F0), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Text('Privacy', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 12),
          _privacyRow(Icons.shield_outlined, 'Data Encryption', 'Your health data is encrypted end-to-end'),
          _privacyRow(Icons.visibility_off_outlined, 'Data Sharing', 'Your data is never sold to third parties'),
          _privacyRow(Icons.delete_outline_rounded, 'Delete Account', 'Contact support to delete your account'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFE4F7F5), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.info_outline, color: _teal, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('For privacy concerns email: privacy@caresync.com',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF1A2D3E)))),
            ]),
          ),
        ]),
      )),
    );
  }

  Widget _privacyRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 38, height: 38,
            decoration: BoxDecoration(color: const Color(0xFFE4F7F5), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: _teal, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A2D3E))),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7A8FA6))),
        ])),
      ]),
    );
  }

  void _showLanguageSheet() {
    final languages = ['English'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE0E6F0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Language', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 12),
            ...languages.map((lang) => InkWell(
              onTap: () {
                setS(() {});
                setState(() => _selectedLanguage = lang);
                Navigator.pop(ctx);
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Row(children: [
                  Expanded(child: Text(lang,
                      style: GoogleFonts.poppins(fontSize: 14,
                          fontWeight: _selectedLanguage == lang ? FontWeight.w600 : FontWeight.normal,
                          color: const Color(0xFF1A2D3E)))),
                  if (_selectedLanguage == lang)
                    const Icon(Icons.check_circle_rounded, color: _teal, size: 20),
                ]),
              ),
            )),
          ]),
        )),
      ),
    );
  }

  void _showAppVersionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('CareSync', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _versionRow('Version', '1.0.0'),
          _versionRow('Build', '2025.04.15'),
          _versionRow('Platform', 'Flutter'),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.poppins(color: _teal, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _versionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text('$label: ', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7A8FA6))),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A2D3E))),
      ]),
    );
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF7A8FA6), size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A2D3E))),
            Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7A8FA6))),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9DB2C8), size: 20),
        ]),
      ),
    );
  }

  Widget _buildPatientCodeCard(String code) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Patient code copied!', style: GoogleFonts.poppins()),
          backgroundColor: _teal,
          duration: const Duration(seconds: 2),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _teal.withOpacity(0.35), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFE4F7F5), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.qr_code_rounded, color: _teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your Patient Code',
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7A8FA6), fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(code,
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A2D3E), letterSpacing: 2)),
          ])),
          const Icon(Icons.copy_rounded, color: _teal, size: 18),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final avatarDataUrl = auth.avatarDataUrl;
    final initials = user?.initials ?? 'U';
    final patientCode = user?.patientCode as String?;
    final isPatient = (user?.role ?? '').toLowerCase() == 'patient';

    return Container(
      color: _bgLight,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(user, initials, avatarDataUrl),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              
              _buildMenuCard([
                _menuItem(
                  iconWidget: _iconCircle(Icons.settings_outlined, const Color(0xFF7A8FA6), const Color(0xFFF0F4F8)),
                  title: 'Settings',
                  subtitle: 'Notifications & preferences',
                  onTap: _showSettingsSheet,
                ),
              ]),
              const SizedBox(height: 12),
              _buildMenuCard([
                _menuItem(
                  iconWidget: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: Color(0xFFFFEBEB), shape: BoxShape.circle),
                    child: const Icon(Icons.help_outline_rounded, color: Color(0xFFE74C3C), size: 22),
                  ),
                  title: 'Help & Support',
                  subtitle: 'Get help or contact us',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Support: caresync@support.com', style: GoogleFonts.poppins()),
                      backgroundColor: _teal,
                    ));
                  },
                ),
              ]),
              const SizedBox(height: 16),
              _buildLogoutButton(),
              const SizedBox(height: 32),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(dynamic user, String initials, String? avatarDataUrl) {
    final patientCode = user?.patientCode as String?;
    final isPatient = (user?.role ?? '').toLowerCase() == 'patient';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD6E9F8), Color(0xFFEAF4FB), Color(0xFFF0F7FD)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(children: [
        Positioned(top: 10, right: -20, child: _cloud(120, 50, Colors.white.withOpacity(0.6))),
        Positioned(top: 40, right: 60, child: _cloud(80, 35, Colors.white.withOpacity(0.5))),
        Positioned(top: 0, left: -10, child: _cloud(90, 40, Colors.white.withOpacity(0.4))),
        Positioned(bottom: 20, left: 30, child: _cloud(70, 30, Colors.white.withOpacity(0.35))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              GestureDetector(
                onTap: () => _showPhotoOptions(avatarDataUrl),
                child: Stack(children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFB2D8F0),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: avatarDataUrl != null
                        ? Image.memory(
                            base64Decode(avatarDataUrl.split(',').last),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarInitials(initials))
                        : _avatarInitials(initials),
                  ),
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                          color: _teal, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 18),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.name ?? 'User Name',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A2D3E))),
                const SizedBox(height: 2),
                Text(user?.email ?? 'user@example.com',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF5A7A94))),
                const SizedBox(height: 2),
                Text(user?.displayRole ?? 'Patient',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF5A7A94))),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showEditProfile(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _teal.withOpacity(0.6), width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.edit_outlined, color: _teal, size: 14),
                      const SizedBox(width: 5),
                      Text('Edit Profile',
                          style: GoogleFonts.poppins(color: _teal, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ])),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _avatarInitials(String initials) {
    return Center(child: Text(initials,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)));
  }

  Widget _cloud(double w, double h, Color color) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(h / 2)),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: items),
    );
  }

  Widget _menuItem({required Widget iconWidget, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          iconWidget,
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A2D3E))),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF7A8FA6))),
            ],
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9DB2C8), size: 22),
        ]),
      ),
    );
  }

  Widget _iconCircle(IconData icon, Color iconColor, Color bgColor) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE74C3C).withOpacity(0.4), width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.logout_rounded, color: Color(0xFFE74C3C), size: 20),
          const SizedBox(width: 10),
          Text('Sign Out',
              style: GoogleFonts.poppins(color: const Color(0xFFE74C3C), fontWeight: FontWeight.w600, fontSize: 15)),
        ]),
      ),
    );
  }
}