import 'package:flutter/material.dart';
import '../services/fatmecoin_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class FatmecoinWalletPage extends StatefulWidget {
  const FatmecoinWalletPage({super.key});

  @override
  State<FatmecoinWalletPage> createState() => _FatmecoinWalletPageState();
}

class _FatmecoinWalletPageState extends State<FatmecoinWalletPage> {
  final FatmecoinService _fcService = FatmecoinService();
  final SupabaseService _supabase = SupabaseService();
  
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _packs = [];
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  String? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _fcService.getWallet(),
      _fcService.getTransactions(),
      _fcService.getPacks(),
      _fcService.getPaymentProviders(),
    ]);

    if (mounted) {
      setState(() {
        _wallet = results[0] as Map<String, dynamic>?;
        _transactions = results[1] as List<Map<String, dynamic>>;
        _packs = results[2] as List<Map<String, dynamic>>;
        _providers = results[3] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Portefeuille Fatmécoin'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildPacksSection(),
                    const SizedBox(height: 24),
                    _buildPaymentProviders(),
                    const SizedBox(height: 24),
                    _buildTransactionsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = (_wallet?['balance'] as num?)?.toDouble() ?? 0.0;
    final lifetimeEarned = (_wallet?['lifetime_earned'] as num?)?.toDouble() ?? 0.0;
    final lifetimeSpent = (_wallet?['lifetime_spent'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C5CFC), Color(0xFF5C3CFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C5CFC).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde Fatmécoin',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _fcService.formatBalance(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '≈ ${_fcService.formatCurrency(balance, 'EUR')}',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('Gagné', lifetimeEarned, Colors.greenAccent),
              const SizedBox(width: 24),
              _buildStatItem('Dépensé', lifetimeSpent, Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          _fcService.formatBalance(amount),
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPacksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acheter des Fatmécoins',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '1 FC = 1€ • Rechargez pour soutenir les artistes',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ..._packs.map((pack) => _buildPackCard(pack)),
      ],
    );
  }

  Widget _buildPackCard(Map<String, dynamic> pack) {
    final fcAmount = (pack['fc_amount'] as num).toDouble();
    final price = (pack['price_eur'] as num).toDouble();
    final bonus = (pack['bonus_fc'] as num?)?.toDouble() ?? 0;
    final isPopular = pack['is_popular'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? const Color(0xFF7C5CFC) : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: const Color(0xFF7C5CFC).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showBuyDialog(pack),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C5CFC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.monetization_on, color: Color(0xFF7C5CFC), size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            pack['name'] ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (isPopular)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C5CFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'POPULAIRE',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fcAmount.toStringAsFixed(0)} FC + ${bonus.toStringAsFixed(0)} FC bonus',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${price.toStringAsFixed(2)}€',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF7C5CFC)),
                    ),
                    if (bonus > 0)
                      Text(
                        '+${bonus.toStringAsFixed(0)} FC offerts',
                        style: const TextStyle(fontSize: 11, color: Colors.green),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentProviders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Moyens de paiement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._providers.map((provider) => _buildProviderCard(provider)),
      ],
    );
  }

  Widget _buildProviderCard(Map<String, dynamic> provider) {
    final name = provider['name'] as String? ?? '';
    final displayName = provider['display_name'] as String? ?? '';
    final currencies = (provider['currencies'] as List?)?.join(', ') ?? 'EUR';

    final icons = {
      'stripe': Icons.credit_card,
      'paypal': Icons.payments,
      'wave': Icons.phone_android,
      'djamo': Icons.account_balance_wallet,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _selectedProvider == name ? const Color(0xFF7C5CFC).withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedProvider == name ? const Color(0xFF7C5CFC) : Colors.grey[200]!,
        ),
      ),
      child: RadioListTile<String>(
        value: name,
        groupValue: _selectedProvider,
        onChanged: (value) => setState(() => _selectedProvider = value),
        activeColor: const Color(0xFF7C5CFC),
        title: Row(
          children: [
            Icon(icons[name] ?? Icons.payment, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Text(displayName, style: const TextStyle(fontSize: 14)),
          ],
        ),
        subtitle: Text(currencies, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historique des transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Aucune transaction',
                  style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rechargez votre wallet pour commencer',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          )
        else
          ..._transactions.map((tx) => _buildTransactionItem(tx)),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    final type = tx['type'] as String? ?? '';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final description = tx['description'] as String? ?? '';
    final createdAt = tx['created_at'] as String? ?? '';

    final typeConfig = {
      'deposit': {'icon': Icons.add_circle, 'color': Colors.green, 'label': 'Dépôt'},
      'donation_sent': {'icon': Icons.send, 'color': Colors.orange, 'label': 'Don envoyé'},
      'donation_received': {'icon': Icons.download, 'color': Colors.blue, 'label': 'Don reçu'},
      'withdrawal': {'icon': Icons.arrow_upward, 'color': Colors.red, 'label': 'Retrait'},
      'bonus': {'icon': Icons.star, 'color': Colors.purple, 'label': 'Bonus'},
    };

    final config = typeConfig[type] ?? {'icon': Icons.receipt, 'color': Colors.grey, 'label': type};

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (config['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(config['icon'] as IconData, color: config['color'] as Color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config['label'] as String,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${type == 'deposit' || type == 'donation_received' || type == 'bonus' ? '+' : '-'}${amount.toStringAsFixed(2)} FC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: type == 'deposit' || type == 'donation_received' || type == 'bonus'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              Text(
                _formatDate(createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBuyDialog(Map<String, dynamic> pack) {
    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord choisir un moyen de paiement')),
      );
      return;
    }

    final fcAmount = (pack['fc_amount'] as num).toDouble();
    final price = (pack['price_eur'] as num).toDouble();
    final bonus = (pack['bonus_fc'] as num?)?.toDouble() ?? 0;
    final totalFc = fcAmount + bonus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmer l\'achat', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CFC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.monetization_on, size: 48, color: Color(0xFF7C5CFC)),
                  const SizedBox(height: 8),
                  Text(
                    '${totalFc.toStringAsFixed(0)} FC',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7C5CFC)),
                  ),
                  if (bonus > 0)
                    Text(
                      '(dont ${bonus.toStringAsFixed(0)} FC bonus)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prix', style: TextStyle(fontSize: 14)),
                Text('${price.toStringAsFixed(2)}€', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Paiement', style: TextStyle(fontSize: 14)),
                Text(_selectedProvider ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPurchase(pack);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C5CFC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer l\'achat'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(Map<String, dynamic> pack) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final fcAmount = (pack['fc_amount'] as num).toDouble();
    final bonus = (pack['bonus_fc'] as num?)?.toDouble() ?? 0;
    final totalFc = fcAmount + bonus;

    final result = await _fcService.deposit(
      amount: totalFc,
      provider: _selectedProvider ?? 'stripe',
    );

    if (mounted) {
      Navigator.pop(context); // Fermer le loader

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] ? result['message'] : result['error']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        await _loadData();
      }
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
      if (diff.inDays < 1) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}