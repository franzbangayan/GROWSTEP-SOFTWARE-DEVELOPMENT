import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  // Step 1 controllers
  final _emailController = TextEditingController();

  // Step 2 controllers
  final _answerController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  int _step = 1; // 1 or 2
  String _foundQuestion = '';
  String _verifiedEmail = '';
  bool _isLoading = false;
  String? _errorMessage;

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  // ─── Brand colors (matches LoginScreen) ──────────────────
  static const Color _purple = Color(0xFF5D56E8);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _white = Colors.white;
  static const Color _green = Color(0xFF3DBE7A);

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _emailController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Step 1: find account ─────────────────────────────────

  Future<void> _findAccount() async {
    if (!_step1Key.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final email = _emailController.text.trim();
    final question = await AuthService.getSecurityQuestion(email);

    setState(() => _isLoading = false);

    if (question == null) {
      setState(() => _errorMessage = 'No account found with that email.');
      return;
    }

    setState(() {
      _step = 2;
      _foundQuestion = question;
      _verifiedEmail = email;
    });
    _slideController.forward(from: 0);
  }

  // ─── Step 2: verify answer + reset ───────────────────────

  Future<void> _resetPassword() async {
    if (!_step2Key.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await AuthService.resetPassword(
      email: _verifiedEmail,
      securityAnswer: _answerController.text.trim(),
      newPassword: _newPasswordController.text,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result == AuthResult.success) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: _green, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Password Reset!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your password has been updated.\nYou can now log in with your new password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pushReplacementNamed(
                          context, AppConstants.loginRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Back to Login',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      setState(() =>
          _errorMessage = 'Incorrect answer. Please check your spelling.');
    }
  }

  // ─── Input decoration ─────────────────────────────────────

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _white.withOpacity(0.7), fontSize: 15),
      prefixIcon: Icon(icon, color: _white.withOpacity(0.7), size: 20),
      filled: true,
      fillColor: _white.withOpacity(0.18),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _white.withOpacity(0.6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purple,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStepIndicator(),
              const SizedBox(height: 28),
              if (_errorMessage != null) _buildErrorBanner(),
              _step == 1 ? _buildStep1() : _buildStep2(),
              const SizedBox(height: 24),
              _buildBackToLogin(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
              child: Text('🔐', style: TextStyle(fontSize: 40))),
        ),
        const SizedBox(height: 18),
        const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _white,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _step == 1
              ? 'Enter your email to find your account'
              : 'Answer your security question',
          style: TextStyle(
            fontSize: 13,
            color: _white.withOpacity(0.75),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ─── Step indicator dots ──────────────────────────────────

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final active = i + 1 <= _step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? _yellow : _white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }

  // ─── Error banner ──────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: _white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: email ────────────────────────────────────────

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _white, fontSize: 15),
            cursorColor: _yellow,
            decoration:
                _fieldDecoration('Email Address', Icons.mail_outline_rounded),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Email is required';
              if (!val.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _findAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: const Color(0xFF1A1400),
                disabledBackgroundColor: _yellow.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Color(0xFF1A1400), strokeWidth: 2.5),
                    )
                  : const Text(
                      'Find My Account  →',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: security question + new password ─────────────

  Widget _buildStep2() {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _step2Key,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security question card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _green.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_rounded,
                            color: _green, size: 16),
                        const SizedBox(width: 7),
                        Text(
                          'SECURITY QUESTION',
                          style: TextStyle(
                            color: _green,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _foundQuestion,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Answer field
              TextFormField(
                controller: _answerController,
                style: const TextStyle(color: _white, fontSize: 15),
                cursorColor: _yellow,
                decoration: _fieldDecoration(
                    'Your Answer', Icons.question_answer_outlined),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Answer is required';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // New password
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: const TextStyle(color: _white, fontSize: 15),
                cursorColor: _yellow,
                decoration:
                    _fieldDecoration('New Password', Icons.lock_outline_rounded)
                        .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _white.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Password is required';
                  if (val.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirm new password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: const TextStyle(color: _white, fontSize: 15),
                cursorColor: _yellow,
                decoration: _fieldDecoration(
                        'Confirm New Password', Icons.lock_outline_rounded)
                    .copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _white.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Please confirm your password';
                  if (val != _newPasswordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Reset button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _yellow,
                    foregroundColor: const Color(0xFF1A1400),
                    disabledBackgroundColor: _yellow.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Color(0xFF1A1400), strokeWidth: 2.5),
                        )
                      : const Text(
                          'Reset Password  →',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),
              // Back to step 1
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _step = 1;
                      _errorMessage = null;
                      _answerController.clear();
                      _newPasswordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  style: TextButton.styleFrom(foregroundColor: _white),
                  child: Text(
                    '← Try a different email',
                    style: TextStyle(
                      color: _white.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Back to login ────────────────────────────────────────

  Widget _buildBackToLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Remember your password?  ',
          style: TextStyle(color: _white.withOpacity(0.7), fontSize: 14),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.pushReplacementNamed(context, AppConstants.loginRoute),
          child: const Text(
            'Log In',
            style: TextStyle(
              color: _yellow,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
