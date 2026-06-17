import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'chat_room_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _channels = [];
  List<Map<String, dynamic>> _discussions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _supabase.getChatChannels(),
        _supabase.getForumDiscussions(limit: 20),
      ]);
      if (mounted) {
        setState(() {
          _channels = results[0];
          _discussions = results[1];
          _isLoading = false;
        });
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

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryViolet,
      child: CustomScrollView(
        slivers: [
          // Channels section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Canaux', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
          ),
          if (_channels.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun canal disponible', style: TextStyle(color: AppTheme.textMuted)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final channel = _channels[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomPage(
                            channelId: channel['id'] ?? '',
                            channelName: channel['name'] ?? 'Chat',
                          ),
                        ),
                      );
                    },
                    child: _channelCard(channel),
                  );
                },
                childCount: _channels.length,
              ),
            ),
          // Discussions section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Discussions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ),
          ),
          if (_discussions.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune discussion', style: TextStyle(color: AppTheme.textMuted)),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final discussion = _discussions[index];
                  return _discussionCard(discussion);
                },
                childCount: _discussions.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _channelCard(Map<String, dynamic> channel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channel['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(channel['description'] ?? '', style: TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(channel['type'] ?? 'public', style: const TextStyle(fontSize: 10, color: AppTheme.primaryViolet)),
          ),
        ],
      ),
    );
  }

  Widget _discussionCard(Map<String, dynamic> discussion) {
    final isTrending = discussion['trending'] == true;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isTrending ? AppTheme.primaryPink.withOpacity(0.3) : Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (isTrending)
            Container(
              width: 4,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(discussion['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(discussion['author_name'] ?? '', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(width: 8),
                    Text('${discussion['replies'] ?? 0} réponses', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    if (isTrending) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.trending_up, size: 12, color: AppTheme.primaryPink),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}