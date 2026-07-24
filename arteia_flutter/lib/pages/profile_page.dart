import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import 'auth_page.dart';

class ProfilePage extends StatefulWidget {
  final String? userId; // null = profil de l'utilisateur connecté
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _artworks = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isUploadingAvatar = false;
  String _visibilityFilter = 'all';

  String get _targetUserId => widget.userId ?? _supabase.auth.currentUser?.id ?? '';
  bool get _isOwnProfile => widget.userId == null || widget.userId == _supabase.auth.currentUser?.id;

  String _profileFont = 'Default';
  final List<String> _fontChoices = [
    'Default',
    'Roboto',
    'Open Sans',
    'Montserrat',
    'Poppins',
    'Lato',
    'Oswald',
    'Raleway',
    'Nunito',
    'Playfair Display',
    'Bebas Neue',
    'Work Sans',
    'Space Grotesk',
    'Inter',
    'Permanent Marker',
    'Caveat',
  ];

  TextStyle get _displayNameStyle =>
      _profileFont == 'Default' ? const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white) : GoogleFonts.getFont(_profileFont, fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white);

  TextStyle get _bioStyle =>
      _profileFont == 'Default' ? const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5) : GoogleFonts.getFont(_profileFont, fontSize: 14, color: Colors.white70, height: 1.5);

  TextStyle get _statValueStyle =>
      _profileFont == 'Default' ? const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white) : GoogleFonts.getFont(_profileFont, fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white);

  TextStyle get _statLabelStyle =>
      _profileFont == 'Default' ? const TextStyle(fontSize: 12, color: Colors.white70) : GoogleFonts.getFont(_profileFont, fontSize: 12, color: Colors.white70);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (_targetUserId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', _targetUserId)
          .maybeSingle();

      final artworks = await _supabase
          .from('artworks')
          .select()
          .eq('author_id', _targetUserId)
          .order('created_at', ascending: false)
          .limit(20);

      final currentUser = _supabase.auth.currentUser;
      final isSubscriber = currentUser != null && !_isOwnProfile
          ? (await _supabase.from('follows').select().eq('follower_id', currentUser.id).eq('following_id', _targetUserId).maybeSingle()) != null
          : false;

      final visibleArtworks = artworks.where((art) {
        final visibility = art['visibility'] ?? 'public';
        if (visibility == 'public') return true;
        if (visibility == 'subscribers') return _isOwnProfile || isSubscriber;
        if (visibility == 'private') return _isOwnProfile;
        return true;
      }).toList();

      bool isFollowing = false;
      if (currentUser != null && !_isOwnProfile) {
        final follow = await _supabase
            .from('follows')
            .select()
            .eq('follower_id', currentUser.id)
            .eq('following_id', _targetUserId)
            .maybeSingle();
        isFollowing = follow != null;
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _artworks = visibleArtworks;
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      _goToAuth();
      return;
    }
    try {
      if (_isFollowing) {
        await _supabase.from('follows')
            .delete()
            .eq('follower_id', currentUser.id)
            .eq('following_id', _targetUserId);
      } else {
        await _supabase.from('follows').insert({
          'follower_id': currentUser.id,
          'following_id': _targetUserId,
        });
      }
      setState(() {
        _isFollowing = !_isFollowing;
        final count = _profile?['followers_count'] ?? 0;
        _profile?['followers_count'] = _isFollowing ? count + 1 : count - 1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.primaryPink),
        );
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      final path = 'avatars/${_targetUserId}.$ext';

      await _supabase.storage.from('avatars').uploadBinary(
        path, bytes,
        fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
      );

      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      await _supabase.from('profiles').update({'avatar_url': url}).eq('id', _targetUserId);

      setState(() => _profile?['avatar_url'] = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload avatar: $e'), backgroundColor: AppTheme.primaryPink),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _updateBio() async {
    final controller = TextEditingController(text: _profile?['bio'] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier la bio'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 150,
          decoration: const InputDecoration(hintText: 'Parlez de vous...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (result == null) return;
    try {
      await _supabase.from('profiles').update({'bio': result}).eq('id', _targetUserId);
      setState(() => _profile?['bio'] = result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.primaryPink));
    }
  }

  Future<void> _pickFont(BuildContext context) async {
    final fonts = ['Default', 'Roboto', 'Open Sans', 'Montserrat', 'Poppins', 'Lato', 'Oswald', 'Raleway', 'Nunito', 'Playfair Display', 'Bebas Neue', 'Work Sans', 'Space Grotesk', 'Inter', 'Permanent Marker', 'Caveat'];
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Police du profil'),
        children: fonts
            .map((font) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, font),
                  child: Text(
                    font,
                    style: TextStyle(
                      fontFamily: font == 'Default' ? null : font,
                      fontSize: 16,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
    if (selected != null) {
      setState(() => _profileFont = selected);
    }
  }

  Future<void> _updateArtworkVisibility(String artId, String visibility) async {
    try {
      await _supabase.from('artworks').update({'visibility': visibility}).eq('id', artId);
      setState(() {
        final art = _artworks.firstWhere((a) => a['id'] == artId, orElse: () => {});
        if (art.isNotEmpty) art['visibility'] = visibility;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.primaryPink));
    }
  }

  void _goToAuth() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final isGuest = user == null;

    if (isGuest && _isOwnProfile) {
      return _buildGuestView();
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
          : _profile == null
              ? _buildNotFound()
              : _buildProfileView(),
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              const Text('Rejoignez Artéïa', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Text(
                'Connectez-vous pour accéder à votre profil, vos créations et interagir avec la communauté.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _goToAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Se connecter / S\'inscrire', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return const Center(
      child: Text('Profil introuvable', style: TextStyle(color: Colors.white54)),
    );
  }

  Widget _buildProfileView() {
    final name = _profile?['display_name'] ?? _profile?['username'] ?? 'Artiste';
    final bio = _profile?['bio'] ?? '';
    final avatarUrl = _profile?['avatar_url'];
    final followersCount = _profile?['followers_count'] ?? 0;
    final followingCount = _profile?['following_count'] ?? 0;

    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppTheme.bgDark,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Banner gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryViolet, Color(0xFF0D0D12)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _isOwnProfile ? _pickAndUploadAvatar : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: AppTheme.primaryViolet,
                                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                child: avatarUrl == null
                                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))
                                    : null,
                              ),
                              if (_isOwnProfile)
                                Positioned(
                                  bottom: 0, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: AppTheme.primaryViolet, shape: BoxShape.circle, border: Border.all(color: AppTheme.bgDark, width: 2)),
                                    child: _isUploadingAvatar
                                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                    if (bio.isNotEmpty)
                                      Text(bio, style: _bioStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    if (_isOwnProfile)
                                      TextButton.icon(
                                        onPressed: _updateBio,
                                        icon: Icon(Icons.edit_rounded, size: 14, color: Colors.white70),
                                        label: Text(bio.isEmpty ? 'Ajouter une bio' : 'Modifier la bio', style: TextStyle(fontSize: 12, color: Colors.white70)),
                                      ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(followersCount.toString(), 'Abonnés'),
                    _buildStat(followingCount.toString(), 'Abonnements'),
                    _buildStat(_artworks.length.toString(), 'Œuvres'),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                if (!_isOwnProfile)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing ? Colors.transparent : AppTheme.primaryViolet,
                        foregroundColor: Colors.white,
                        side: BorderSide(color: AppTheme.primaryViolet, width: _isFollowing ? 1.5 : 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_isFollowing ? 'Abonné ✓' : 'Suivre',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),

                if (_isOwnProfile)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickFont(context),
                          icon: const Icon(Icons.text_fields_rounded, size: 18, color: Colors.white),
                          label: Text('Police : $_profileFont', style: const TextStyle(fontSize: 13, color: Colors.white)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 10)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: appearance settings
                          },
                          icon: const Icon(Icons.palette_outlined, size: 18, color: Colors.white),
                          label: const Text('Apparence', style: TextStyle(fontSize: 13, color: Colors.white)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 10)),
                        ),
                      ),
                    ],
                  ),

                // Tabs
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primaryViolet,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textMuted,
                  tabs: const [
                    Tab(text: 'Œuvres'),
                    Tab(text: 'À propos'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],

      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Œuvres
          Column(
            children: [
              if (_isOwnProfile)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      _FilterChip(label: 'Tout', selected: _visibilityFilter == 'all', onTap: () => setState(() => _visibilityFilter = 'all')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Public', selected: _visibilityFilter == 'public', onTap: () => setState(() => _visibilityFilter = 'public')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Abonnés', selected: _visibilityFilter == 'subscribers', onTap: () => setState(() => _visibilityFilter = 'subscribers')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Privé', selected: _visibilityFilter == 'private', onTap: () => setState(() => _visibilityFilter = 'private')),
                    ],
                  ),
                ),
              Expanded(
                child: _artworks.isEmpty
                    ? Center(child: Text('Aucune œuvre publiée', style: TextStyle(color: AppTheme.textMuted)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4,
                        ),
                        itemCount: _artworks.length,
                        itemBuilder: (context, i) {
                          final art = _artworks[i];
                          return art['image_url'] != null
                              ? Image.network(art['image_url'], fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: AppTheme.cardDark))
                              : Container(
                                  color: AppTheme.cardDark,
                                  child: const Icon(Icons.image, color: Colors.white24),
                                );
                        },
                      ),
              ),
            ],
          ),

          // Onglet À propos
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bio.isNotEmpty) ...[
                  const Text('Biographie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(bio, style: TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.6)),
                  const SizedBox(height: 20),
                ],
                if (_isOwnProfile) ...[
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _supabase.auth.signOut();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.logout, color: AppTheme.primaryPink),
                    label: const Text('Se déconnecter', style: TextStyle(color: AppTheme.primaryPink)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.primaryPink)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}