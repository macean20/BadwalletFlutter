import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../dashboard/dashboard_provider.dart';
import '../../models/transaction_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'XOF',
    decimalDigits: 0,
  );

  String _selectedFilter = 'ALL'; // ALL, DEPOSIT, TRANSFER, PAYMENT

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  Future<void> _refreshHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = authProvider.currentWallet?.phoneNumber;
    if (phone != null) {
      await Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final phone = authProvider.currentWallet?.phoneNumber ?? '';

    // Filter transactions
    final filteredTxns = dashboardProvider.transactions.where((txn) {
      if (_selectedFilter == 'ALL') return true;
      if (_selectedFilter == 'DEPOSIT') return txn.type == 'DEPOSIT';
      if (_selectedFilter == 'TRANSFER') return txn.type == 'TRANSFER';
      if (_selectedFilter == 'PAYMENT') return txn.type == 'PAYMENT';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique complet'),
      ),
      body: Column(
        children: [
          // Filter pills row
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterPill('ALL', 'Toutes'),
                const SizedBox(width: 8),
                _buildFilterPill('DEPOSIT', 'Dépôts'),
                const SizedBox(width: 8),
                _buildFilterPill('TRANSFER', 'Transferts'),
                const SizedBox(width: 8),
                _buildFilterPill('PAYMENT', 'Paiements'),
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshHistory,
              color: AppTheme.secondaryColor,
              child: _buildTransactionListContent(dashboardProvider, filteredTxns, phone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String filterValue, String label) {
    final isSelected = _selectedFilter == filterValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: AppTheme.surfaceColor,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filterValue;
          });
        }
      },
    );
  }

  Widget _buildTransactionListContent(
    DashboardProvider dashboardProvider,
    List<Transaction> txns,
    String userPhone,
  ) {
    if (dashboardProvider.isLoading && txns.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.secondaryColor),
      );
    }

    if (txns.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80.0, horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: AppTheme.textMuted.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucune transaction trouvée',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Vos opérations pour ce filtre s\'afficheront ici.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: txns.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final txn = txns[index];
        final isIncoming = txn.isIncoming(userPhone);

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.03)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  _formatTransactionDate(txn.createdAt),
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ref: ${txn.reference}',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],
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

  Color _getTransactionColor(Transaction txn, bool isIncoming) {
    if (txn.type == 'DEPOSIT' || isIncoming) {
      return AppTheme.accentColor;
    }
    return AppTheme.errorColor;
  }

  String _getTransactionTitle(Transaction txn, bool isIncoming) {
    switch (txn.type) {
      case 'DEPOSIT':
        return 'Dépôt direct';
      case 'WITHDRAW':
        return 'Retrait d\'argent';
      case 'TRANSFER':
        if (isIncoming) {
          return 'Transfert reçu de ${txn.walletPhone}';
        } else {
          return 'Transfert envoyé à ${txn.destinationPhone}';
        }
      case 'PAYMENT':
      default:
        return 'Règlement de facture';
    }
  }

  String _formatTransactionDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('dd MMMM yyyy, HH:mm', 'fr_FR').format(dateTime);
    } catch (e) {
      return isoString;
    }
  }
}
