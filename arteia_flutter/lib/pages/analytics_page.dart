import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = AnalyticsService().getAnalytics('user-123');

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
                _StatCard(icon: Icons.visibility, label: 'Vues', value: '${analytics.totalViews}'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.favorite, label: 'Likes', value: '${analytics.totalLikes}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatCard(icon: Icons.comment, label: 'Commentaires', value: '${analytics.totalComments}'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.trending_up, label: 'Engagement', value: '${analytics.engagementRate.toStringAsFixed(1)}%'),
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
              child: Column(
                children: analytics.viewsByDay.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 40, child: Text(e.key, style: TextStyle(color: Colors.grey[400], fontSize: 12))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: e.value / analytics.viewsByDay.values.reduce((a, b) => a > b ? a : b),
                            backgroundColor: Colors.grey[800],
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryViolet),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                )).toList(),
              ),
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
              child: Column(
                children: analytics.viewsByCountry.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.public, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(e.key, style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                      const Spacer(),
                      Text('${e.value}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ),
                )).toList(),
              ),
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