import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseService _supabase = SupabaseService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.currentUser;
      if (user != null) {
        final profile = await _supabase.getProfile(user.id);
        if (mounted) setState(() { _profile = profile; _isLoading = false; });
      } else {
        if (mounted) setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet));
    }

    final user = _supabase.currentUser;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Non connecté', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Connectez-vous pour accéder à votre profil', style: TextStyle(color: AppTheme.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet, foregroundColor: Colors.white),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.primaryViolet.withOpacity(0.3), blurRadius: 20)],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(user.email ?? 'Utilisateur', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_profile?['role'] ?? 'user', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 24),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statItem('0', 'Œuvres'),
              _statItem('0', 'Abonnés'),
              _statItem('0', 'Abonnements'),
            ],
          ),
          const SizedBox(height: 24),
          // Menu items
          _menuItem(Icons.upload, 'Mes œuvres', '0 œuvres'),
          _menuItem(Icons.favorite, 'Mes favoris', '0 favoris'),
          _menuItem(Icons.bookmark, 'Enregistrés', '0 enregistrés'),
          _menuItem(Icons.settings, 'Paramètres', ''),
          _menuItem(Icons.help, 'Aide', ''),
          const SizedBox(height: 24),
          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await _supabase.signOut();
                if (mounted) setState(() {});
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryPink,
                side: const BorderSide(color: AppTheme.primaryPink),
              ),
              child: const Text('Se déconnecter'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryViolet),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
        ],
      ),
    );
  }
}