import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/auth_advanced_service.dart';
import '../theme/app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+33';
  final List<_CountryCode> _countryCodes = [
    _CountryCode('FR', '+33'),
    _CountryCode('US', '+1'),
    _CountryCode('GB', '+44'),
    _CountryCode('DE', '+49'),
    _CountryCode('CA', "+1"),
    _CountryCode('AU', '+61'),
    _CountryCode('BR', '+55'),
    _CountryCode('IN', '+91'),
    _CountryCode('JP', '+81'),
    _CountryCode('CN', '+86'),
    _CountryCode('RU', '+7'),
    _CountryCode('MX', '+52'),
    _CountryCode('ES', '+34'),
    _CountryCode('IT', '+39'),
    _CountryCode('AR', '+54'),
    _CountryCode('ZA', '+27'),
    _CountryCode('NG', '+234'),
    _CountryCode('KE', '+254'),
    _CountryCode('EG', '+20'),
    _CountryCode('PH', '+63'),
  ];

  final _supabaseService = SupabaseService();
  final _authAdvancedService = AuthAdvancedService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _detectCountryCode();
  }

  void _detectCountryCode() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final country = locale.countryCode;
    final match = _countryCodes.firstWhere(
      (c) => c.code.toUpperCase() == (country ?? '').toUpperCase(),
      orElse: () => _countryCodes.first,
    );
    setState(() => _selectedCountryCode = match.prefix);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      AuthResult result;

      if (_isLogin) {
        result = await _supabaseService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        final rawPhone = _phoneController.text.trim();
        final phone = rawPhone.isEmpty ? '' : '$_selectedCountryCode${rawPhone.replaceAll(RegExp(r'^\+?00'), '')}';
        if (phone.isEmpty) {
          _showError('Le numéro de téléphone est obligatoire');
          return;
        }
        result = await _supabaseService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          displayName: _nameController.text.trim(),
          phoneNumber: phone,
        );
      }

      if (!mounted) return;

      if (result.error != null) {
        _showError(_mapError(result.error!));
      } else {
        if (!_isLogin && result.user?.confirmedAt == null) {
          _showSuccess('Vérifiez votre email pour confirmer votre compte !');
        } else {
          Navigator.pop(context, true); // true = succès
        }
      }
    } catch (e) {
      if (mounted) _showError('Une erreur inattendue est survenue.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _authAdvancedService.signInWithGoogle();
      
      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccess('Connexion Google réussie !');
        Navigator.pop(context, true);
      } else {
        _showError('Erreur Google: ${result['error']}');
      }
    } catch (e) {
      if (mounted) _showError('Erreur lors de la connexion Google');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Entrez votre email d\'abord');
      return;
    }
    try {
      await _supabaseService.client.auth.resetPasswordForEmail(email);
      _showSuccess('Email de réinitialisation envoyé à $email');
    } catch (e) {
      _showError('Impossible d\'envoyer l\'email');
    }
  }

  String _mapError(String error) {
    if (error.contains('Invalid login credentials')) return 'Email ou mot de passe incorrect';
    if (error.contains('Email not confirmed')) return 'Confirmez votre email avant de vous connecter';
    if (error.contains('User already registered')) return 'Un compte existe déjà avec cet email';
    if (error.contains('Password should be at least')) return 'Le mot de passe doit faire au moins 6 caractères';
    if (error.contains('Unable to validate email')) return 'Adresse email invalide';
    return error;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.primaryPink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.primaryTeal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),

                  // Logo
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryViolet, AppTheme.primaryTeal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                          color: AppTheme.primaryViolet.withOpacity(0.5),
                          blurRadius: 32, spreadRadius: 4,
                        )],
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    _isLogin ? 'Connexion' : 'Inscription',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Bienvenue sur Artéïa' : 'Rejoignez la communauté artistique',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Name field (signup only)
                  if (!_isLogin) ...[
                    _buildField(
                      controller: _nameController,
                      label: 'Nom d\'artiste',
                      icon: Icons.person_outline,
                      validator: (v) => v!.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Phone number (signup only)
                  if (!_isLogin) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.1))),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              isDense: true,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              dropdownColor: AppTheme.cardDark,
                              items: _countryCodes
                                  .map((c) => DropdownMenuItem(value: c.prefix, child: Text(c.prefix)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedCountryCode = v ?? _selectedCountryCode),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v!.trim().isEmpty) return 'Champ requis';
                              final phone = v.trim();
                              if (!phone.startsWith('+') && phone.length < 10) return 'Format invalide (ex: +33612345678)';
                              return null;
                            },
                            decoration: _inputDecoration('Numéro de téléphone', Icons.phone_outlined),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  _buildField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Champ requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: _obscurePassword,
                    validator: (v) {
                      if (v!.isEmpty) return 'Champ requis';
                      if (!_isLogin && v.length < 6) return 'Minimum 6 caractères';
                      return null;
                    },
                    decoration: _inputDecoration('Mot de passe', Icons.lock_outlined).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  // Forgot password
                  if (_isLogin) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: Text('Mot de passe oublié ?', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Google Sign-In Button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.g_mobiledata, size: 28, color: Colors.white);
                      },
                    ),
                    label: const Text(
                      'Continuer avec Google',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('ou', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 8,
                        shadowColor: AppTheme.primaryViolet.withOpacity(0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              _isLogin ? 'Se connecter' : 'Créer mon compte',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Toggle
                  TextButton(
                    onPressed: _toggleMode,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        children: [
                          TextSpan(text: _isLogin ? 'Pas encore de compte ? ' : 'Déjà un compte ? '),
                          TextSpan(
                            text: _isLogin ? 'S\'inscrire' : 'Se connecter',
                            style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppTheme.textMuted),
      prefixIcon: Icon(icon, color: AppTheme.primaryViolet, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryPink, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
      ),
    );
  }
}

class _CountryCode {
  final String code;
  final String prefix;
  const _CountryCode(this.code, this.prefix);
}