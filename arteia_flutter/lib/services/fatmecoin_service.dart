import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class FatmecoinService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final FatmecoinService _instance = FatmecoinService._();
  factory FatmecoinService() => _instance;
  FatmecoinService._();

  // ==================== WALLET ====================

  /// Obtenir le solde du wallet
  Future<Map<String, dynamic>?> getWallet() async {
    final user = _supabase.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('fatmecoin_wallets')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();
      return response as Map<String, dynamic>?;
    } catch (e) {
      print('🔴 getWallet error: $e');
      return null;
    }
  }

  /// Obtenir le solde d'un autre utilisateur (public)
  Future<double> getUserBalance(String userId) async {
    try {
      final response = await _client
          .from('fatmecoin_wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();
      return (response?['balance'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('🔴 getUserBalance error: $e');
      return 0.0;
    }
  }

  // ==================== TRANSACTIONS ====================

  /// Obtenir l'historique des transactions
  Future<List<Map<String, dynamic>>> getTransactions({int limit = 50}) async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('fatmecoin_transactions')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getTransactions error: $e');
      return [];
    }
  }

  // ==================== PACKS ====================

  /// Obtenir les packs Fatmécoins disponibles
  Future<List<Map<String, dynamic>>> getPacks() async {
    try {
      final response = await _client
          .from('fatmecoin_packs')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getPacks error: $e');
      return [];
    }
  }

  // ==================== FOURNISSEURS ====================

  /// Obtenir les fournisseurs de paiement disponibles
  Future<List<Map<String, dynamic>>> getPaymentProviders() async {
    try {
      final response = await _client
          .from('payment_providers')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getPaymentProviders error: $e');
      return [];
    }
  }

  // ==================== DÉPÔT ====================

  /// Recharger le wallet (appelle Stripe/PayPal côté serveur)
  Future<Map<String, dynamic>> deposit({
    required double amount,
    required String provider, // 'stripe', 'paypal', 'wave', 'djamo'
    String? providerTxId,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');
    if (amount <= 0) throw Exception('Montant invalide.');

    try {
      // Appeler la fonction RPC pour créditer le wallet
      final txId = await _client.rpc('deposit_fatmecoins', params: {
        'p_user_id': user.id,
        'p_amount': amount,
        'p_provider': provider,
        'p_provider_tx_id': providerTxId ?? '',
        'p_description': 'Achat Fatmécoins via $provider',
      });

      // Récupérer la transaction créée
      final transaction = await _client
          .from('fatmecoin_transactions')
          .select('*')
          .eq('id', txId)
          .maybeSingle();

      return {
        'success': true,
        'transaction': transaction,
        'message': '✅ ${amount} FC ajoutés à votre wallet !',
      };
    } catch (e) {
      print('🔴 deposit error: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Créer un PaymentIntent Stripe (appel Edge Function)
  Future<Map<String, dynamic>> createStripePaymentIntent({
    required double amount,
    required String currency,
  }) async {
    try {
      // Appeler l'Edge Function Supabase pour créer le PaymentIntent
      final response = await _client.functions.invoke('create-payment-intent', body: {
        'amount': (amount * 100).toInt(), // Centimes
        'currency': currency,
      });

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('🔴 createStripePaymentIntent error: $e');
      return {'error': e.toString()};
    }
  }

  /// Créer une transaction PayPal (appel Edge Function)
  Future<Map<String, dynamic>> createPayPalOrder({
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await _client.functions.invoke('create-paypal-order', body: {
        'amount': amount,
        'currency': currency,
      });

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('🔴 createPayPalOrder error: $e');
      return {'error': e.toString()};
    }
  }

  /// Confirmer une transaction Wave
  Future<Map<String, dynamic>> confirmWavePayment({
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      final response = await _client.functions.invoke('wave-payment', body: {
        'phone_number': phoneNumber,
        'amount': amount,
      });

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('🔴 confirmWavePayment error: $e');
      return {'error': e.toString()};
    }
  }

  /// Confirmer une transaction Djamo
  Future<Map<String, dynamic>> confirmDjamoPayment({
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      final response = await _client.functions.invoke('djamo-payment', body: {
        'phone_number': phoneNumber,
        'amount': amount,
      });

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('🔴 confirmDjamoPayment error: $e');
      return {'error': e.toString()};
    }
  }

  // ==================== ENVOI ====================

  /// Envoyer des Fatmécoins à un artiste (don)
  Future<Map<String, dynamic>> sendDonation({
    required String recipientId,
    required double amount,
    String? message,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');
    if (user.id == recipientId) throw Exception('Vous ne pouvez pas vous envoyer des FC à vous-même.');

    try {
      // Vérifier le solde
      final wallet = await getWallet();
      final balance = (wallet?['balance'] as num?)?.toDouble() ?? 0.0;
      
      if (balance < amount) {
        return {
          'success': false,
          'error': 'Solde insuffisant. Vous avez $balance FC, besoin de $amount FC.',
        };
      }

      // Envoyer via la fonction RPC
      final result = await _client.rpc('send_fatmecoins', params: {
        'p_sender_id': user.id,
        'p_recipient_id': recipientId,
        'p_amount': amount,
        'p_donation_id': null,
        'p_description': message ?? 'Don Fatmécoins',
      });

      return {
        'success': result == true,
        'message': '✅ $amount FC envoyés avec succès !',
      };
    } catch (e) {
      print('🔴 sendDonation error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== CONVERSION ====================

  /// Convertir FC en devise
  Future<double> convertToCurrency(double fcAmount, String currency) async {
    try {
      final response = await _client
          .from('conversion_rates')
          .select('rate')
          .eq('to_currency', currency)
          .maybeSingle();

      final rate = (response?['rate'] as num?)?.toDouble() ?? 1.0;
      return double.parse((fcAmount * rate).toStringAsFixed(2));
    } catch (e) {
      print('🔴 convertToCurrency error: $e');
      return fcAmount; // Fallback 1:1
    }
  }

  /// Formater le solde en FC
  String formatBalance(double balance) {
    return '${balance.toStringAsFixed(2)} FC';
  }

  /// Formater le solde en devise
  String formatCurrency(double amount, String currency) {
    final symbols = {
      'EUR': '€',
      'USD': '\$',
      'GBP': '£',
      'XOF': 'CFA',
    };
    final symbol = symbols[currency] ?? currency;
    return '${amount.toStringAsFixed(2)} $symbol';
  }
}