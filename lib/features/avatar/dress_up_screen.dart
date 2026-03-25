import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/avatar_model.dart';
import '../../services/auth_service.dart';
import 'dart:ui';

class DressUpScreen extends StatefulWidget {
  const DressUpScreen({super.key});

  @override
  State<DressUpScreen> createState() => _DressUpScreenState();
}

class _DressUpScreenState extends State<DressUpScreen> with TickerProviderStateMixin {
  late AvatarModel _selectedAvatar;
  AvatarVariant? _selectedVariant;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    final user = AuthService.currentUser;
    
    // Default to the user's current avatar or the first one
    _selectedAvatar = AvatarModel.defaults.firstWhere(
      (a) => a.id == user?.avatarId,
      orElse: () => AvatarModel.defaults.first,
    );

    // Default to the user's current variant or null (base)
    if (user?.avatarVariantId != null) {
      _selectedVariant = _selectedAvatar.variants.cast<AvatarVariant?>().firstWhere(
        (v) => v?.id == user?.avatarVariantId,
        orElse: () => null,
      );
    }

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _saveSelection() async {
    setState(() => _isLoading = true);

    final user = AuthService.currentUser;
    if (user != null) {
      final updatedUser = user.copyWith(
        avatarId: _selectedAvatar.id,
        avatarVariantId: _selectedVariant?.id,
      );
      await AuthService.saveUser(updatedUser);
    }

    setState(() => _isLoading = false);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Outfit saved successfully!'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF0B2535), Color(0xFF0D1B2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildCharacterPreview(),
                        const SizedBox(height: 20),
                        _buildAvatarSelector(),
                        const SizedBox(height: 20),
                        _buildVariantSelector(),
                        const SizedBox(height: 30),
                        _buildSaveButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'DRESS UP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer to center the title
        ],
      ),
    );
  }

  Widget _buildCharacterPreview() {
    final imagePath = _selectedVariant?.assetPath ?? _selectedAvatar.assetPath;

    return Container(
      height: 350,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background Glow
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
            // Character Image
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_outline_rounded,
                  size: 150,
                  color: Colors.white24,
                ),
              ),
            ),
            // Info Overlay
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedAvatar.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    _selectedAvatar.role,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primary.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'SELECT CHARACTER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white60,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: AvatarModel.defaults.length,
            itemBuilder: (context, index) {
              final avatar = AvatarModel.defaults[index];
              final isSelected = _selectedAvatar.id == avatar.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatar = avatar;
                    _selectedVariant = null; // Reset variant when character changes
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      avatar.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVariantSelector() {
    if (_selectedAvatar.variants.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'CHOOSE OUTFIT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white60,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            // +1 for the base outfit
            itemCount: _selectedAvatar.variants.length + 1,
            itemBuilder: (context, index) {
              final isBase = index == 0;
              final variant = isBase ? null : _selectedAvatar.variants[index - 1];
              final isSelected = isBase 
                ? _selectedVariant == null 
                : _selectedVariant?.id == variant?.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVariant = variant;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          isBase ? _selectedAvatar.assetPath : (variant?.assetPath ?? ''),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.checkroom, color: Colors.white24),
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                )
              : const Text(
                  'SAVE OUTFIT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
        ),
      ),
    );
  }
}
