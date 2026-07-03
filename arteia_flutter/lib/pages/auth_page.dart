import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_advanced_service.dart';

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
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  final AuthAdvancedService _authService = AuthAdvancedService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    if (!_isLogin && _nameController.text.isEmpty) {
      _showSnackBar('Veuillez entrer votre nom');
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    if (_isLogin) {
      result = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      result = await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _nameController.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        _showSnackBar(_isLogin ? 'Connexion réussie !' : 'Inscription réussie !');
        Navigator.pop(context, true);
      } else {
        _showSnackBar(result['error']?.toString() ?? 'Erreur inconnue');
      }
    }
  }

  Future<void> _signInWithProvider(String provider) async {
    setState(() => _isLoading = true);

    Map<String, dynamic> result;
    switch (provider) {
      case 'google':
        result = await _authService.signInWithGoogle();
        break;
      case 'apple':
        result = await _authService.signInWithApple();
        break;
      case 'github':
        result = await _authService.signInWithGitHub();
        break;
      case 'discord':
        result = await _authService.signInWithDiscord();
        break;
      default:
        result = {'success': false, 'error': 'Provider inconnu'};
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success'] == true) {
        _showSnackBar('Connexion réussie !');
        Navigator.pop(context, true);
      } else {
        _showSnackBar(result['error']?.toString() ?? 'Erreur de connexion');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryPink,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryViolet, AppTheme.primaryTeal],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryViolet.withOpacity(0.4),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                ),
                // Title
                Text(
                  _isLogin ? 'Connexion' : 'Inscription',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Bienvenue sur Artéïa' : 'Rejoignez la communauté',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Social login buttons
                _SocialButton(
                  icon: Icons.g_mobiledata,
                  label: 'Continuer avec Google',
                  color: Colors.white,
                  bgColor: const Color(0xFFDB4437),
                  onPressed: _isLoading ? null : () => _signInWithProvider('google'),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  icon: Icons.apple,
                  label: 'Continuer avec Apple',
                  color: Colors.white,
                  bgColor: Colors.black,
                  onPressed: _isLoading ? null : () => _signInWithProvider('apple'),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  icon: Icons.code,
                  label: 'Continuer avec GitHub',
                  color: Colors.white,
                  bgColor: const Color(0xFF333333),
                  onPressed: _isLoading ? null : () => _signInWithProvider('github'),
                ),
                const SizedBox(height: 12),
                _SocialButton(
                  icon: Icons.headset_mic,
                  label: 'Continuer avec Discord',
                  color: Colors.white,
                  bgColor: const Color(0xFF5865F2),
                  onPressed: _isLoading ? null : () => _signInWithProvider('discord'),
                ),

                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[700])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('ou', style: TextStyle(color: Colors.grey[500])),
                    ),
                    Expanded(child: Divider(color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 24),

                // Name field (only for signup)
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      labelStyle: TextStyle(color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryViolet),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.textMuted.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.textMuted.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Email field
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.primaryViolet),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.textMuted.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.textMuted.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Password field
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    labelStyle: TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppTheme.primaryViolet),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.textMuted.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.textMuted.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primaryViolet, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryViolet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primaryViolet.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Se connecter' : 'S\'inscrire',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                // Toggle mode
                TextButton(
                  onPressed: _toggleMode,
                  child: Text(
                    _isLogin
                        ? 'Pas de compte ? S\'inscrire'
                        : 'Déjà un compte ? Se connecter',
                    style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 24),
        label: Text(
          label,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide.none,
        ),
      ),
    );
  }
}