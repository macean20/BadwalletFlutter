import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import 'dashboard_provider.dart';
import '../transfers/transfer_screen.dart';
import '../bills/bills_screen.dart';
import '../history/history_screen.dart';
import '../../models/transaction_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'XOF',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentWallet != null) {
        Provider.of<DashboardProvider>(context, listen: false)
            .fetchDashboardData(authProvider.currentWallet!.phoneNumber);
      }
    });
  }

  Future<void> _handleRefresh() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentWallet != null) {
      await Provider.of<DashboardProvider>(context, listen: false)
          .fetchDashboardData(authProvider.currentWallet!.phoneNumber);
      await authProvider.reloadWallet();
    }
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final wallet = authProvider.currentWallet;

    if (wallet == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Text('BadWallet'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.errorColor),
            tooltip: 'Déconnexion',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.secondaryColor,
        backgroundColor: AppTheme.surfaceColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour,',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        wallet.email.split('@').first,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Text(
                      wallet.code,
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // 2. Premium Balance Card
              _buildBalanceCard(wallet, dashboardProvider),

              const SizedBox(height: 28),

              // 3. Quick Action Grid
              Text(
                'Opérations rapides',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(wallet),

              const SizedBox(height: 32),

              // 4. Recent Transactions List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions récentes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Transactions List
              _buildTransactionsList(dashboardProvider, wallet.phoneNumber),
            ],
          ),
        ),
      ),
    );
  }

  // Premium Balance Card builder
  Widget _buildBalanceCard(dynamic wallet, DashboardProvider dashboardProvider) {
    final double displayBalance = dashboardProvider.isLoading ? wallet.balance : dashboardProvider.balance;
    final String formattedBalance = _currencyFormat.format(displayBalance);

    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dynamic glow designs
          Positioned(
            right: -20,
            top: -20,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withOpacity(0.06),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: CircleAvatar(
              radius: 90,
              backgroundColor: AppTheme.secondaryColor.withOpacity(0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Solde disponible',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        dashboardProvider.isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.9),
                        size: 22,
                      ),
                      onPressed: dashboardProvider.toggleBalanceHidden,
                    ),
                  ],
                ),
                Text(
                  dashboardProvider.isBalanceHidden ? '•••••• XOF' : formattedBalance,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      wallet.phoneNumber,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.currency_exchange, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          wallet.currency,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick action buttons row
  Widget _buildQuickActions(dynamic wallet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          icon: Icons.send,
          label: 'Transférer',
          color: AppTheme.primaryColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransferScreen()),
            );
          },
        ),
        _buildActionItem(
          icon: Icons.receipt_long,
          label: 'Payer Factures',
          color: AppTheme.secondaryColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BillsScreen()),
            );
          },
        ),
        _buildActionItem(
          icon: Icons.history,
          label: 'Historique',
          color: AppTheme.accentColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the list of 5 recent transactions
  Widget _buildTransactionsList(DashboardProvider dashboardProvider, String userPhone) {
    if (dashboardProvider.isLoading && dashboardProvider.transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.secondaryColor),
        ),
      );
    }

    final txns = dashboardProvider.recentTransactions;

    if (txns.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
              const SizedBox(height: 12),
              const Text(
                'Aucune transaction récente',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Vos transferts et paiements apparaîtront ici.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: txns.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final txn = txns[index];
        final isIncoming = txn.isIncoming(userPhone);
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withOpacity(0.03)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: _getTransactionColor(txn, isIncoming).withOpacity(0.12),
              child: Icon(
                _getTransactionIcon(txn, isIncoming),
                color: _getTransactionColor(txn, isIncoming),
                size: 20,
              ),
            ),
            title: Text(
              _getTransactionTitle(txn, isIncoming),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              _formatTransactionDate(txn.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Text(
              '${isIncoming ? "+" : "-"} ${_currencyFormat.format(txn.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _getTransactionColor(txn, isIncoming),
              ),
            ),
          ),
        );
      },
    );
  }

  // Get Transaction Icon based on Type
  IconData _getTransactionIcon(Transaction txn, bool isIncoming) {
    switch (txn.type) {
      case 'DEPOSIT':
        return Icons.arrow_downward;
      case 'WITHDRAW':
        return Icons.arrow_upward;
      case 'TRANSFER':
        return isIncoming ? Icons.call_received : Icons.call_made;
      case 'PAYMENT':
      default:
        return Icons.receipt_long;
    }
  }

  // Get Transaction Color based on Type/Flow
  Color _getTransactionColor(Transaction txn, bool isIncoming) {
    if (txn.type == 'DEPOSIT' || isIncoming) {
      return AppTheme.accentColor; // Green for credits
    }
    return AppTheme.errorColor; // Red for debits
  }

  // Get User-friendly transaction description
  String _getTransactionTitle(Transaction txn, bool isIncoming) {
    switch (txn.type) {
      case 'DEPOSIT':
        return 'Dépôt reçu';
      case 'WITHDRAW':
        return 'Retrait effectué';
      case 'TRANSFER':
        if (isIncoming) {
          return 'Reçu de ${txn.walletPhone}';
        } else {
          return 'Envoyé à ${txn.destinationPhone}';
        }
      case 'PAYMENT':
      default:
        return 'Paiement Facture';
    }
  }

  // Format creation Date
  String _formatTransactionDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(dateTime);
    } catch (e) {
      return isoString;
    }
  }
}
