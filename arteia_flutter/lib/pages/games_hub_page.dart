import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game_player_page.dart';
import 'game_upload_page.dart';

class GamesHubPage extends StatelessWidget {
  const GamesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090D),
      appBar: AppBar(
        title: const Text('Arcade Arteïa', style: TextStyle(fontFamily: 'Space Grotesk', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF15151B),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Jeux Officiels',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildGameCard(
            context,
            title: 'Shader Pilot',
            description: 'Volez à travers des univers génératifs uniques et hypnotiques.',
            icon: Icons.rocket_launch,
            gradient: const LinearGradient(colors: [Colors.deepOrange, Colors.orangeAccent]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GamePlayerPage(
                    title: 'Shader Pilot',
                    localAssetPath: 'games/shader_pilot/index.html',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildGameCard(
            context,
            title: 'Sky Metropolis',
            description: 'Bâtissez une ville futuriste dans les nuages.',
            icon: Icons.location_city,
            gradient: const LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GamePlayerPage(
                    title: 'Sky Metropolis',
                    localAssetPath: 'games/sky_metropolis/index.html',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildGameCard(
            context,
            title: 'Voxel Art',
            description: 'Transformez vos images 2D en modèles Voxel 3D.',
            icon: Icons.view_in_ar,
            gradient: const LinearGradient(colors: [Colors.purple, Colors.purpleAccent]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GamePlayerPage(
                    title: 'Voxel Art',
                    localAssetPath: 'games/voxel_art/index.html',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Créations de la Communauté',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  if (Supabase.instance.client.auth.currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vous devez être connecté pour publier un jeu.')),
                    );
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GameUploadPage()));
                },
                icon: const Icon(Icons.add, size: 16, color: Colors.deepOrange),
                label: const Text('Publier', style: TextStyle(color: Colors.deepOrange)),
              )
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client.from('community_games').stream(primaryKey: ['id']).order('created_at'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.deepOrange));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              final games = snapshot.data ?? [];
              if (games.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.gamepad, size: 48, color: Colors.white24),
                      SizedBox(height: 16),
                      Text(
                        'Soyez le premier à publier un mini-jeu !',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: games.length,
                itemBuilder: (context, index) {
                  final game = games[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GamePlayerPage(
                            title: game['title'] ?? 'Jeu Communauté',
                            remoteUrl: game['storage_url'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF15151B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: game['thumbnail_url'] != null
                                ? Image.network(
                                    game['thumbnail_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white24, size: 48),
                                  )
                                : const Icon(Icons.image, color: Colors.white24, size: 48),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game['title'] ?? 'Sans titre',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Joué ${game['play_count'] ?? 0} fois',
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(icon, size: 120, color: Colors.white.withOpacity(0.2)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('OFFICIEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
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
}
