import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Statistiques', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cartes stats principales
            Row(
              children: [
                _StatCard(icon: Icons.visibility, label: 'Vues', value: '0'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.favorite, label: 'Likes', value: '0'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(icon: Icons.comment, label: 'Commentaires', value: '0'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.trending_up, label: 'Engagement', value: '0%'),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Vues par jour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Aucune donnée disponible', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 24),
            const Text('Top pays', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Aucune donnée disponible', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryViolet.withOpacity(0.3), AppTheme.cardDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryViolet, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }
}