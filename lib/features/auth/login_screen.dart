import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── Brand colors ─────────────────────────────────────────
  static const Color _purple = Color(0xFF5D56E8);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _white = Colors.white;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    final result = await AuthService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    switch (result) {
      case AuthResult.success:
        final user = AuthService.currentUser;
        final route = (user == null || !user.hasSelectedAvatar)
            ? AppConstants.avatarSelectionRoute
            : AppConstants.homeRoute;
        Navigator.pushReplacementNamed(context, route);
        break;
      case AuthResult.invalidCredentials:
        setState(() => _errorMessage = 'Incorrect email or password.');
        break;
      default:
        setState(() => _errorMessage = 'Something went wrong. Try again.');
    }
  }

  void _handleQuickPreview() {
    // Skip login — go directly to home for preview purposes
    Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purple,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    _buildLogo(),
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 36),
                    if (_errorMessage != null) _buildErrorBanner(),
                    _buildEmailField(),
                    const SizedBox(height: 14),
                    _buildPasswordField(),
                    const SizedBox(height: 8),
                    _buildForgotPassword(),
                    const SizedBox(height: 24),
                    _buildLoginButton(),
                    const SizedBox(height: 14),
                    _buildQuickPreviewButton(),
                    const SizedBox(height: 24),
                    _buildDevShortcut(),
                    const SizedBox(height: 32),
                    _buildSignUpLink(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Logo ──────────────────────────────────────────────────

  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '🏃',
          style: TextStyle(fontSize: 52),
        ),
      ),
    );
  }

  // ─── Title ─────────────────────────────────────────────────

  Widget _buildTitle() {
    return Column(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(text: 'GrowStep ', style: TextStyle(color: _white)),
              TextSpan(text: 'AR', style: TextStyle(color: _yellow)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'YOUR JOURNEY STARTS HERE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _yellow,
            letterSpacing: 2.5,
          ),
        ),
      ],
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

  // ─── Input fields ──────────────────────────────────────────

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _white.withOpacity(0.7), fontSize: 15),
      prefixIcon: Icon(icon, color: _white.withOpacity(0.7), size: 20),
      filled: true,
      fillColor: _white.withOpacity(0.18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: _white, fontSize: 15),
      cursorColor: _yellow,
      decoration: _fieldDecoration('Email Address', Icons.mail_outline_rounded),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Email is required';
        if (!val.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: _white, fontSize: 15),
      cursorColor: _yellow,
      decoration: _fieldDecoration('Password', Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: _white.withOpacity(0.7),
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Password is required';
        if (val.length < 6) return 'Minimum 6 characters';
        return null;
      },
    );
  }

  // ─── Forgot password ───────────────────────────────────────

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: _white,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
        child: const Text(
          'FORGOT PASSWORD?',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: _white,
          ),
        ),
      ),
    );
  }

  // ─── Buttons ───────────────────────────────────────────────

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: const Color(0xFF1A1400),
          disabledBackgroundColor: _yellow.withOpacity(0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                "Let's Play  →",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  Widget _buildQuickPreviewButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _handleQuickPreview,
        style: OutlinedButton.styleFrom(
          foregroundColor: _white,
          side: BorderSide(color: _white.withOpacity(0.7), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text(
          'QUICK PREVIEW (SKIP LOGIN)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
            color: _white,
          ),
        ),
      ),
    );
  }

  // ─── Developer shortcut ────────────────────────────────────

  Widget _buildDevShortcut() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            'DEVELOPER SHORTCUT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              color: _white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, AppConstants.homeRoute),
            child: const Text(
              'CLICK HERE TO ENTER THE AR GAME & SEE SHOP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: _yellow,
                decoration: TextDecoration.underline,
                decorationColor: _yellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sign up link ──────────────────────────────────────────

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?  ",
          style: TextStyle(
            color: _white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppConstants.registerRoute),
          child: const Text(
            'Sign Up',
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