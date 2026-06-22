import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../services/image_upload_service.dart';
import '../theme/app_theme.dart';
import '../widgets/follow_button.dart';
import 'favorites_page.dart';
import 'artwork_upload_page.dart';
import 'thought_bubble_upload_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseService _supabase = SupabaseService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isCurrentUser = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final currentUser = _supabase.currentUser;
      final targetUserId = widget.userId ?? currentUser?.id;
      
      if (targetUserId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _isCurrentUser = currentUser?.id == targetUserId;

      final profile = await _supabase.getProfile(targetUserId);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        title: Text(
          _profile?['username'] ?? 'Profil',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
        actions: [
          if (_isCurrentUser) ...[
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())),
              tooltip: 'Favoris',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArtworkUploadPage())),
              tooltip: 'Publier',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
          : _supabase.currentUser == null && widget.userId == null
              ? _buildLoginPrompt()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      if (_isCurrentUser) _buildMyPostsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppTheme.cardDarkLight,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.person, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Connectez-vous pour voir votre profil', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (image == null) return;

      setState(() => _isUploadingAvatar = true);

      final result = await _imageUploadService.uploadArtworkImage(File(image.path));
      final avatarUrl = result['image_url'];

      // Update profile in Supabase
      final user = _supabase.currentUser;
      if (user != null && avatarUrl.isNotEmpty) {
        await _supabase.client
            .from('profiles')
            .update({'avatar_url': avatarUrl})
            .eq('id', user.id);

        setState(() {
          _profile?['avatar_url'] = avatarUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Widget _buildProfileHeader() {
    final profile = _profile;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isCurrentUser ? _pickAndUploadAvatar : null,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal]),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(profile?['avatar_url'] ?? '👤', style: const TextStyle(fontSize: 40)),
                  ),
                  if (_isUploadingAvatar)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Center(
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      ),
                    ),
                  if (_isCurrentUser && !_isUploadingAvatar)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryViolet,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.cardDark, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile?['username'] ?? profile?['display_name'] ?? 'Utilisateur',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            profile?['role'] ?? 'Artiste',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          if (profile?['bio'] != null && (profile!['bio'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile['bio'] as String,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(label: 'Publications', value: '${profile?['posts_count'] ?? 0}'),
              _StatItem(label: 'Abonnés', value: '${profile?['followers_count'] ?? 0}'),
              _StatItem(label: 'Abonnements', value: '${profile?['following_count'] ?? 0}'),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isCurrentUser && widget.userId != null)
            FollowButton(userId: widget.userId!, onChanged: _loadProfile),
        ],
      ),
    );
  }

  Widget _buildMyPostsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mes publications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.cardDarkLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 12),
              const Text('Vos œuvres apparaîtront ici', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArtworkUploadPage())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Publier une œuvre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThoughtBubbleUploadPage())),
                icon: const Icon(Icons.psychology, size: 18),
                label: const Text('Nouvelle bulle de pensée'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }
}