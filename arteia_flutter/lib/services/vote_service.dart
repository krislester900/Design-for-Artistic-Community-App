import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class VoteService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final VoteService _instance = VoteService._();
  factory VoteService() => _instance;
  VoteService._();

  /// Obtenir les compétitions actives
  Future<List<Map<String, dynamic>>> getActiveCompetitions() async {
    try {
      final response = await _client
          .from('competitions')
          .select('*, category:categories!category_id(name, icon)')
          .eq('status', 'active')
          .order('end_date', ascending: true)
          .limit(10);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getActiveCompetitions error: $e');
      return [];
    }
  }

  /// Obtenir les compétitions à venir
  Future<List<Map<String, dynamic>>> getUpcomingCompetitions() async {
    try {
      final response = await _client
          .from('competitions')
          .select('*, category:categories!category_id(name, icon)')
          .eq('status', 'upcoming')
          .order('start_date', ascending: true)
          .limit(10);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getUpcomingCompetitions error: $e');
      return [];
    }
  }

  /// Obtenir les compétitions terminées
  Future<List<Map<String, dynamic>>> getClosedCompetitions() async {
    try {
      final response = await _client
          .from('competitions')
          .select('*, category:categories!category_id(name, icon), winner:posts!winner_id(title)')
          .eq('status', 'closed')
          .order('end_date', ascending: false)
          .limit(10);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getClosedCompetitions error: $e');
      return [];
    }
  }

  /// Obtenir les détails d'une compétition
  Future<Map<String, dynamic>?> getCompetitionDetails(String competitionId) async {
    try {
      final response = await _client
          .from('competitions')
          .select('*, category:categories!category_id(name, icon, color), prizes:competition_prizes(*)')
          .eq('id', competitionId)
          .maybeSingle();

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('🔴 getCompetitionDetails error: $e');
      return null;
    }
  }

  /// Obtenir les inscriptions à une compétition
  Future<List<Map<String, dynamic>>> getCompetitionEntries(String competitionId) async {
    try {
      final response = await _client
          .from('competition_entries')
          .select('*, post:posts!post_id(*), user:profiles!user_id(id, username, avatar_url)')
          .eq('competition_id', competitionId)
          .order('vote_count', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getCompetitionEntries error: $e');
      return [];
    }
  }

  /// Voter pour une œuvre
  Future<bool> castVote(String competitionId, String entryId, String postId) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    try {
      // Vérifier si l'utilisateur a déjà voté pour cette entrée
      final existingVote = await _client
          .from('votes')
          .select('id')
          .eq('competition_id', competitionId)
          .eq('voter_id', user.id)
          .eq('entry_id', entryId)
          .maybeSingle();

      if (existingVote != null) {
        throw Exception('Vous avez déjà voté pour cette œuvre.');
      }

      // Voter via la fonction RPC
      await _client.rpc('cast_vote', params: {
        'p_competition_id': competitionId,
        'p_entry_id': entryId,
        'p_voter_id': user.id,
        'p_post_id': postId,
      });

      return true;
    } catch (e) {
      print('🔴 castVote error: $e');
      rethrow;
    }
  }

  /// Vérifier si l'utilisateur a déjà voté pour une œuvre
  Future<bool> hasVoted(String competitionId, String entryId) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('votes')
          .select('id')
          .eq('competition_id', competitionId)
          .eq('voter_id', user.id)
          .eq('entry_id', entryId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('🔴 hasVoted error: $e');
      return false;
    }
  }

  /// Obtenir le nombre de votes restants pour l'utilisateur
  Future<int> getRemainingVotes(String competitionId) async {
    final user = _supabase.currentUser;
    if (user == null) return 0;

    try {
      // Récupérer la compétition
      final competition = await _client
          .from('competitions')
          .select('max_votes_per_user')
          .eq('id', competitionId)
          .maybeSingle();

      final maxVotes = (competition?['max_votes_per_user'] as int?) ?? 3;

      // Compter les votes déjà émis
      final count = await _client
          .from('votes')
          .select('id', count: CountOption.exact)
          .filter('competition_id', 'eq', competitionId)
          .filter('voter_id', 'eq', user.id);

      final usedVotes = (count as List).length;
      
      return maxVotes - usedVotes;
    } catch (e) {
      print('🔴 getRemainingVotes error: $e');
      return 0;
    }
  }

  /// Inscrire son œuvre à une compétition
  Future<bool> enterCompetition({
    required String competitionId,
    required String postId,
    required String title,
    String? description,
    String? imageUrl,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    try {
      await _client.from('competition_entries').insert({
        'competition_id': competitionId,
        'post_id': postId,
        'user_id': user.id,
        'title': title,
        'description': description ?? '',
        'image_url': imageUrl ?? '',
      });

      return true;
    } catch (e) {
      print('🔴 enterCompetition error: $e');
      rethrow;
    }
  }

  /// Obtenir les compétitions par catégorie
  Future<List<Map<String, dynamic>>> getCompetitionsByCategory(String categoryName) async {
    try {
      final response = await _client
          .from('competitions')
          .select('*')
          .eq('category_name', categoryName)
          .order('start_date', ascending: false)
          .limit(20);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getCompetitionsByCategory error: $e');
      return [];
    }
  }
}