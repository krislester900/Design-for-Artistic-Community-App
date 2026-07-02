import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class DonationService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final DonationService _instance = DonationService._();
  factory DonationService() => _instance;
  DonationService._();

  /// Faire un don à un artiste
  Future<Map<String, dynamic>?> makeDonation({
    required String recipientId,
    required double amount,
    String? message,
    String paymentMethod = 'stripe',
    String? paymentIntentId,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');
    if (user.id == recipientId) throw Exception('Vous ne pouvez pas vous faire un don à vous-même.');
    if (amount <= 0) throw Exception('Le montant doit être supérieur à 0.');

    try {
      // Appeler la fonction SQL process_donation via l'API
      final response = await _client.rpc('process_donation', params: {
        'p_sender_id': user.id,
        'p_recipient_id': recipientId,
        'p_amount': amount,
        'p_message': message ?? '',
        'p_payment_method': paymentMethod,
        'p_payment_intent_id': paymentIntentId ?? '',
      });

      if (response != null) {
        // Récupérer le don créé
        final donation = await _client
            .from('donations')
            .select('*, recipient:profiles!recipient_id(id, username, avatar_url)')
            .eq('id', response)
            .maybeSingle();
        
        return donation as Map<String, dynamic>?;
      }
      
      return null;
    } catch (e) {
      print('🔴 Donation error: $e');
      rethrow;
    }
  }

  /// Obtenir l'historique des dons envoyés
  Future<List<Map<String, dynamic>>> getSentDonations() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('donations')
          .select('*, recipient:profiles!recipient_id(id, username, avatar_url)')
          .eq('sender_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getSentDonations error: $e');
      return [];
    }
  }

  /// Obtenir l'historique des dons reçus
  Future<List<Map<String, dynamic>>> getReceivedDonations() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('donations')
          .select('*, sender:profiles!sender_id(id, username, avatar_url)')
          .eq('recipient_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getReceivedDonations error: $e');
      return [];
    }
  }

  /// Obtenir le solde de l'artiste connecté
  Future<Map<String, dynamic>?> getArtistBalance() async {
    final user = _supabase.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('artist_balances')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('🔴 getArtistBalance error: $e');
      return null;
    }
  }

  /// Demander un retrait
  Future<bool> requestPayout({
    required double amount,
    String paymentMethod = 'bank_transfer',
    Map<String, dynamic>? accountInfo,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    // Vérifier le solde minimum (10€)
    if (amount < 10) throw Exception('Le montant minimum de retrait est de 10€.');

    try {
      final balance = await getArtistBalance();
      final currentBalance = (balance?['current_balance'] as num?)?.toDouble() ?? 0;
      
      if (amount > currentBalance) {
        throw Exception('Solde insuffisant. Vous avez $currentBalance€ disponible.');
      }

      final fee = double.parse((amount * 0.01).toStringAsFixed(2)); // 1% de frais de retrait
      final netAmount = amount - fee;

      await _client.from('payout_requests').insert({
        'user_id': user.id,
        'amount': amount,
        'fee': fee,
        'net_amount': netAmount,
        'payment_method': paymentMethod,
        'account_info': accountInfo ?? {},
      });

      return true;
    } catch (e) {
      print('🔴 requestPayout error: $e');
      rethrow;
    }
  }

  /// Calculer les frais de donation
  double calculateFee(double amount) {
    return double.parse((amount * 0.05).toStringAsFixed(2)); // 5%
  }

  /// Calculer le montant net après frais
  double calculateNetAmount(double amount) {
    return double.parse((amount - calculateFee(amount)).toStringAsFixed(2));
  }

  /// Obtenir les statistiques de dons pour un artiste
  Future<Map<String, dynamic>> getDonationStats(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('total_donations_received, donation_count')
          .eq('id', userId)
          .maybeSingle();

      return {
        'total': (response?['total_donations_received'] as num?)?.toDouble() ?? 0.0,
        'count': (response?['donation_count'] as int?) ?? 0,
      };
    } catch (e) {
      print('🔴 getDonationStats error: $e');
      return {'total': 0.0, 'count': 0};
    }
  }
}