import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  String? _selectedQuestion;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ─── Brand colors ─────────────────────────────────────────
  static const Color _purple = Color(0xFF5D56E8);
  static const Color _yellow = Color(0xFFFFC107);
  static const Color _white = Colors.white;
  static const Color _green = Color(0xFF3DBE7A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _securityAnswerController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuestion == null) {
      setState(() => _errorMessage = 'Please select a security question.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await AuthService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      securityQuestion: _selectedQuestion!,
      securityAnswer: _securityAnswerController.text.trim(),
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    switch (result) {
      case AuthResult.success:
        Navigator.pushReplacementNamed(
            context, AppConstants.avatarSelectionRoute);
        break;
      case AuthResult.emailAlreadyExists:
        setState(() =>
            _errorMessage = 'An account with this email already exists.');
        break;
      default:
        setState(() => _errorMessage = 'Something went wrong. Try again.');
    }
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
                    const SizedBox(height: 40),
                    _buildLogo(),
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 32),
                    if (_errorMessage != null) _buildErrorBanner(),
                    _buildNameField(),
                    const SizedBox(height: 14),
                    _buildEmailField(),
                    const SizedBox(height: 14),
                    _buildPasswordField(),
                    const SizedBox(height: 14),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 20),
                    _buildSecuritySection(),
                    const SizedBox(height: 28),
                    _buildRegisterButton(),
                    const SizedBox(height: 32),
                    _buildLoginLink(),
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
      child: const Center(child: Text('🏃', style: TextStyle(fontSize: 52))),
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
                letterSpacing: -0.5),
            children: [
              TextSpan(text: 'GrowStep ', style: TextStyle(color: _white)),
              TextSpan(text: 'AR', style: TextStyle(color: _yellow)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'CREATE YOUR ACCOUNT',
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

  // ─── Input decoration helper ───────────────────────────────

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

  // ─── Fields ────────────────────────────────────────────────

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.name,
      style: const TextStyle(color: _white, fontSize: 15),
      cursorColor: _yellow,
      decoration: _fieldDecoration('Full Name', Icons.person_outline_rounded),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return 'Name is required';
        if (val.trim().length < 2) return 'Name is too short';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
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
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: _white, fontSize: 15),
      cursorColor: _yellow,
      decoration:
          _fieldDecoration('Password', Icons.lock_outline_rounded).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _white.withOpacity(0.7),
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Password is required';
        if (val.length < 6) return 'Minimum 6 characters';
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      style: const TextStyle(color: _white, fontSize: 15),
      cursorColor: _yellow,
      decoration:
          _fieldDecoration('Confirm Password', Icons.lock_outline_rounded)
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
        if (val == null || val.isEmpty) return 'Please confirm your password';
        if (val != _passwordController.text) return 'Passwords do not match';
        return null;
      },
    );
  }

  // ─── Security question section ─────────────────────────────

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: _green, size: 16),
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
          const SizedBox(height: 4),
          Text(
            'Used to reset your password if you forget it.',
            style: TextStyle(
              color: _white.withOpacity(0.55),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),

          // Dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: _white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _white.withOpacity(0.12)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedQuestion,
                hint: Text(
                  'Choose a question…',
                  style: TextStyle(
                      color: _white.withOpacity(0.7), fontSize: 14),
                ),
                isExpanded: true,
                dropdownColor: const Color(0xFF5D56E8),
                iconEnabledColor: _white.withOpacity(0.7),
                items: AppConstants.securityQuestions
                    .map((q) => DropdownMenuItem(
                          value: q,
                          child: Text(
                            q,
                            style: const TextStyle(
                                color: _white, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedQuestion = val),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Answer field
          TextFormField(
            controller: _securityAnswerController,
            style: const TextStyle(color: _white, fontSize: 15),
            cursorColor: _yellow,
            decoration: _fieldDecoration(
                'Your Answer', Icons.question_answer_outlined),
            validator: (val) {
              if (_selectedQuestion == null) return null;
              if (val == null || val.trim().isEmpty)
                return 'Answer is required';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── Register button ───────────────────────────────────────

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: const Color(0xFF1A1400),
          disabledBackgroundColor: _yellow.withOpacity(0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                'Start Playing  →',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // ─── Login link ────────────────────────────────────────────

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?  ',
          style: TextStyle(color: _white.withOpacity(0.7), fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(
              context, AppConstants.loginRoute),
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
