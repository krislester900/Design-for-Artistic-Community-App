import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SupabaseService _supabase = SupabaseService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allArtworks = [];
  List<Map<String, dynamic>> _allArtists = [];
  List<Map<String, dynamic>> _filteredArtworks = [];
  List<Map<String, dynamic>> _filteredArtists = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _supabase.getArtworks(limit: 50),
        _supabase.getArtists(limit: 50),
      ]);
      if (mounted) {
        setState(() {
          _allArtworks = results[0];
          _allArtists = results[1];
          _filteredArtworks = _allArtworks;
          _filteredArtists = _allArtists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _search(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredArtworks = _allArtworks;
        _filteredArtists = _allArtists;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _filteredArtworks = _allArtworks.where((a) =>
        (a['title'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
        (a['artist_name'] ?? '').toLowerCase().contains(query.toLowerCase())
      ).toList();
      _filteredArtists = _allArtists.where((a) =>
        (a['name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
        (a['role'] ?? '').toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet));
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher œuvres, artistes...',
                hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { _searchController.clear(); _search(''); },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        // Results
        Expanded(
          child: _isSearching
            ? _buildSearchResults()
            : _buildDefaultContent(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_filteredArtworks.isEmpty && _filteredArtists.isEmpty) {
      return Center(child: Text('Aucun résultat trouvé', style: TextStyle(color: AppTheme.textMuted)));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_filteredArtists.isNotEmpty) ...[
          Text('Artistes (${_filteredArtists.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          ..._filteredArtists.map((artist) => _artistResult(artist)),
          const SizedBox(height: 16),
        ],
        if (_filteredArtworks.isNotEmpty) ...[
          Text('Œuvres (${_filteredArtworks.length})', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          ..._filteredArtworks.map((artwork) => _artworkResult(artwork)),
        ],
      ],
    );
  }

  Widget _buildDefaultContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (_allArtists.isNotEmpty) ...[
          Text('Artistes populaires', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          ..._allArtists.take(5).map((artist) => _artistResult(artist)),
          const SizedBox(height: 16),
        ],
        if (_allArtworks.isNotEmpty) ...[
          Text('Œuvres récentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          ..._allArtworks.take(5).map((artwork) => _artworkResult(artwork)),
        ],
      ],
    );
  }

  Widget _artistResult(Map<String, dynamic> artist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artist['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(artist['role'] ?? '', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  Widget _artworkResult(Map<String, dynamic> artwork) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              color: AppTheme.primaryViolet.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.image, color: AppTheme.primaryViolet, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artwork['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(artwork['artist_name'] ?? '', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.favorite, size: 12, color: AppTheme.primaryPink),
              const SizedBox(width: 3),
              Text('${artwork['likes'] ?? 0}', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}