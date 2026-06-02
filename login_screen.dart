
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final int initialTab;
  const LoginScreen({super.key, this.initialTab = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late bool _showLogin;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmCtrl = TextEditingController();
  final _patientCodeCtrl = TextEditingController();
  final _trustedPhoneCtrl = TextEditingController();
  final _trustedEmailCtrl = TextEditingController();

  String _selectedRole = 'patient';
  bool _loginLoading = false;
  bool _registerLoading = false;
  bool _obscureLoginPw = true;
  bool _obscureRegPw = true;
  bool _obscureConfirmPw = true;

  @override
  void initState() {
    super.initState();
    _showLogin = widget.initialTab == 0;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmCtrl.dispose();
    _patientCodeCtrl.dispose();
    _trustedPhoneCtrl.dispose();
    _trustedEmailCtrl.dispose();
    super.dispose();
      }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loginLoading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!ok && mounted) _showError(auth.error ?? 'Login failed');
    if (mounted) setState(() => _loginLoading = false);
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _registerLoading = true);
    final auth = context.read<AuthProvider>();

    final ok = await auth.register(
      name: _regNameCtrl.text.trim(),
      email: _regEmailCtrl.text.trim(),
      password: _regPasswordCtrl.text,
      role: _selectedRole,
      patientCode: _selectedRole != 'patient' ? _patientCodeCtrl.text.trim() : null,
      trustedContactPhone: _selectedRole == 'patient' ? _trustedPhoneCtrl.text.trim() : null,
      trustedContactEmail: _selectedRole == 'patient' ? _trustedEmailCtrl.text.trim() : null,
    );
    if (!ok && mounted) _showError(auth.error ?? 'Registration failed');
    if (mounted) setState(() => _registerLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFE57373),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _switchTo(bool login) => setState(() => _showLogin = login);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD6EEF8), Color(0xFFEEF7FB), Color(0xFFFFFFFF)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTopSection(),
                _buildFormSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _buildClouds(),
        Column(
          children: [
            const SizedBox(height: 20),
            _buildLogo(),
            const SizedBox(height: 12),
            _buildIllustration(),
          ],
        ),
      ],
    );
  }

  Widget _buildClouds() {
    return Positioned.fill(
      child: CustomPaint(painter: _CloudPainter()),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF3BBFB2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          'CareSync',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2A3A4A),
          ),
        ),
      ],
    );
  }





  Widget _buildIllustration() {
  return SizedBox(
    height: 220,
    child: Image.asset(
      'assets/images/doctor_female.png',
      fit: BoxFit.contain,
    ),
  );
}

  Widget _buildFormSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _showLogin ? _buildLoginForm() : _buildRegisterForm(),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back!',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A3A4A),
            ),
          ),
          const SizedBox(height: 24),
          _buildField(
            controller: _emailCtrl,
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.contains('@') ? null : 'Enter valid email',
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _passwordCtrl,
            hint: 'Enter your password',
            icon: Icons.lock_outline,
            obscure: _obscureLoginPw,
            suffix: IconButton(
              icon: Icon(
                _obscureLoginPw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF9DB2C8),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureLoginPw = !_obscureLoginPw),
            ),
            validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF3BBFB2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildButton(
            label: 'Login',
            onPressed: _loginLoading ? null : _login,
            loading: _loginLoading,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7A90A4)),
              ),
              GestureDetector(
                onTap: () => _switchTo(false),
                child: Text(
                  'Register',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF3BBFB2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create an Account',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2A3A4A),
            ),
          ),
          const SizedBox(height: 20),
          _buildField(
            controller: _regNameCtrl,
            hint: 'Full Name',
            icon: Icons.person_outline,
            validator: (v) => v!.trim().isNotEmpty ? null : 'Required',
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _regEmailCtrl,
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.contains('@') ? null : 'Enter valid email',
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _regPasswordCtrl,
            hint: 'Enter your password',
            icon: Icons.lock_outline,
            obscure: _obscureRegPw,
            suffix: IconButton(
              icon: Icon(
                _obscureRegPw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF9DB2C8),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureRegPw = !_obscureRegPw),
            ),
            validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _regConfirmCtrl,
            hint: 'Repeat your password',
            icon: Icons.lock_outline,
            obscure: _obscureConfirmPw,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirmPw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF9DB2C8),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureConfirmPw = !_obscureConfirmPw),
            ),
            validator: (v) => v == _regPasswordCtrl.text ? null : 'Passwords do not match',
          ),
          const SizedBox(height: 12),
          
          _buildRoleSelector(),
            if (_selectedRole != 'patient') ...[
              const SizedBox(height: 12),
              _buildField(
                controller: _patientCodeCtrl,
                hint: 'Patient Code',
                icon: Icons.qr_code,
                validator: (v) => v!.trim().isNotEmpty ? null : 'Required',
              ),
            ],
            if (_selectedRole == 'patient') ...[
              const SizedBox(height: 12),
              _buildField(
                controller: _trustedPhoneCtrl,
                hint: 'Trusted Contact Phone *',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.trim().length >= 7 ? null : 'Enter valid phone number',
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _trustedEmailCtrl,
                hint: 'Trusted Contact Email (optional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return v.contains('@') ? null : 'Enter valid email';
                },
              ),
            ],
          const SizedBox(height: 20),
          _buildButton(
            label: 'Register',
            onPressed: _registerLoading ? null : _register,
            loading: _registerLoading,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7A90A4)),
              ),
              GestureDetector(
                onTap: () => _switchTo(true),
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF3BBFB2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am a...',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFF7A90A4),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _roleChip('patient', Icons.person, 'Patient'),
            const SizedBox(width: 8),
            _roleChip('doctor', Icons.medical_services_outlined, 'Doctor'),
            const SizedBox(width: 8),
            _roleChip('family', Icons.people_outline, 'Family'),
          ],
        ),
      ],
    );
  }

  Widget _roleChip(String role, IconData icon, String label) {
    final selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3BBFB2).withOpacity(0.1) : const Color(0xFFF5F9FC),
            border: Border.all(
              color: selected ? const Color(0xFF3BBFB2) : const Color(0xFFDDE8F0),
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? const Color(0xFF3BBFB2) : const Color(0xFF9DB2C8), size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: selected ? const Color(0xFF3BBFB2) : const Color(0xFF9DB2C8),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF2A3A4A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9DB2C8)),
        prefixIcon: Icon(icon, color: const Color(0xFF9DB2C8), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF5F9FC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDE8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3BBFB2), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE57373)),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3BBFB2),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF3BBFB2).withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
              ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.6);
    void drawCloud(double x, double y, double scale) {
      canvas.drawCircle(Offset(x, y), 28 * scale, paint);
      canvas.drawCircle(Offset(x + 22 * scale, y - 8 * scale), 22 * scale, paint);
      canvas.drawCircle(Offset(x + 44 * scale, y), 26 * scale, paint);
      canvas.drawCircle(Offset(x + 20 * scale, y + 12 * scale), 22 * scale, paint);
    }
    drawCloud(20, 50, 0.7);
    drawCloud(size.width - 100, 30, 0.9);
    drawCloud(size.width * 0.3, 80, 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DoctorFemalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;

    final skinPaint = Paint()..color = const Color(0xFFFDD5B1);
    final coatPaint = Paint()..color = Colors.white;
    final tealPaint = Paint()..color = const Color(0xFF3BBFB2);
    final darkPaint = Paint()..color = const Color(0xFF2A3A4A);
    final hairPaint = Paint()..color = const Color(0xFF4A3728);
    final redPaint = Paint()..color = const Color(0xFFE57373);

    canvas.drawCircle(Offset(cx, cy - 52), 34, skinPaint);
    final hairPath = Path()
      ..moveTo(cx - 34, cy - 52)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy - 52), radius: 34), 3.14, 3.14, false)
      ..lineTo(cx + 20, cy - 28)
      ..lineTo(cx - 20, cy - 28)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    final eyePaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawCircle(Offset(cx - 10, cy - 52), 3.5, eyePaint);
    canvas.drawCircle(Offset(cx + 10, cy - 52), 3.5, eyePaint);

    final smilePath = Path()
      ..moveTo(cx - 8, cy - 42)
      ..quadraticBezierTo(cx, cy - 36, cx + 8, cy - 42);
    canvas.drawPath(smilePath, Paint()..color = const Color(0xFFD4956A)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: 70, height: 80),
      const Radius.circular(16),
    );
    canvas.drawRRect(bodyRect, coatPaint);
    canvas.drawLine(Offset(cx, cy - 16), Offset(cx, cy + 60), tealPaint..strokeWidth = 2);

    canvas.drawRect(Rect.fromCenter(center: Offset(cx - 4, cy + 5), width: 12, height: 5), redPaint);
    canvas.drawRect(Rect.fromCenter(center: Offset(cx - 4, cy + 5), width: 5, height: 12), redPaint);

    canvas.drawCircle(Offset(cx - 48, cy - 10), 16, coatPaint);
    canvas.drawCircle(Offset(cx - 48, cy - 10), 16, Paint()..color = const Color(0xFFDDE8F0)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx - 53, cy - 10), Offset(cx - 43, cy - 10), darkPaint..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx - 48, cy - 15), Offset(cx - 48, cy - 5), darkPaint..strokeWidth = 1.5);

    canvas.drawCircle(Offset(cx + 52, cy - 20), 14, coatPaint);
    canvas.drawCircle(Offset(cx + 52, cy - 20), 14, Paint()..color = const Color(0xFFDDE8F0)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx + 44, cy - 20), Offset(cx + 60, cy - 20), tealPaint..strokeWidth = 2);
    canvas.drawLine(Offset(cx + 52, cy - 28), Offset(cx + 52, cy - 12), tealPaint..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DoctorMalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;

    final skinPaint = Paint()..color = const Color(0xFFFDD5B1);
    final coatPaint = Paint()..color = Colors.white;
    final tealPaint = Paint()..color = const Color(0xFF3BBFB2);
    final darkPaint = Paint()..color = const Color(0xFF2A3A4A);
    final hairPaint = Paint()..color = const Color(0xFF3A2820);

    canvas.drawCircle(Offset(cx, cy - 52), 32, skinPaint);
    final hairPath = Path()
      ..moveTo(cx - 32, cy - 62)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy - 52), radius: 32), 3.5, 2.4, false)
      ..lineTo(cx, cy - 84)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    final eyePaint = Paint()..color = const Color(0xFF5D4037);
    canvas.drawCircle(Offset(cx - 10, cy - 53), 3.5, eyePaint);
    canvas.drawCircle(Offset(cx + 10, cy - 53), 3.5, eyePaint);

    final smilePath = Path()
      ..moveTo(cx - 8, cy - 43)
      ..quadraticBezierTo(cx, cy - 37, cx + 8, cy - 43);
    canvas.drawPath(smilePath, Paint()..color = const Color(0xFFD4956A)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round);

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 20), width: 72, height: 82),
      const Radius.circular(16),
    );
    canvas.drawRRect(bodyRect, coatPaint);
    canvas.drawLine(Offset(cx, cy - 16), Offset(cx, cy + 62), tealPaint..strokeWidth = 2);

    canvas.drawCircle(Offset(cx + 50, cy - 15), 16, coatPaint);
    canvas.drawCircle(Offset(cx + 50, cy - 15), 16, Paint()..color = const Color(0xFFDDE8F0)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx + 44, cy - 15), Offset(cx + 56, cy - 15), darkPaint..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx + 50, cy - 21), Offset(cx + 50, cy - 9), darkPaint..strokeWidth = 1.5);

    canvas.drawCircle(Offset(cx - 50, cy - 25), 13, coatPaint);
    canvas.drawCircle(Offset(cx - 50, cy - 25), 13, Paint()..color = const Color(0xFFDDE8F0)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx - 57, cy - 25), Offset(cx - 43, cy - 25), tealPaint..strokeWidth = 2);
    canvas.drawLine(Offset(cx - 50, cy - 32), Offset(cx - 50, cy - 18), tealPaint..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}