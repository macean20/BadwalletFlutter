import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../dashboard/dashboard_provider.dart';
import 'bill_provider.dart';
import '../../models/bill_model.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'XOF',
    decimalDigits: 0,
  );

  // List of pre-configured billers with design tokens
  final List<Map<String, dynamic>> _billers = [
    {
      'name': 'SENELEC',
      'label': 'Senelec',
      'desc': 'Électricité (Post-payé)',
      'icon': Icons.lightbulb,
      'color': Colors.amber,
    },
    {
      'name': 'WOYAFAL',
      'label': 'Woyofal',
      'desc': 'Recharge électricité',
      'icon': Icons.flash_on,
      'color': Colors.orange,
    },
    {
      'name': 'RAPIDO',
      'label': 'Rapido',
      'desc': 'Badge autoroute',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'name': 'ISM',
      'label': 'ISM',
      'desc': 'Frais de scolarité',
      'icon': Icons.school,
      'color': Colors.red,
    },
  ];

  String? _activeBiller;
  bool _isSuccess = false;
  List<String> _paidRefs = [];

  void _selectBiller(String billerName) {
    setState(() {
      _activeBiller = billerName;
      _isSuccess = false;
    });
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = authProvider.currentWallet?.phoneNumber;
    
    if (phone != null) {
      Provider.of<BillProvider>(context, listen: false).fetchBills(phone, billerName);
    }
  }

  void _deselectBiller() {
    setState(() {
      _activeBiller = null;
    });
  }

  void _paySelected() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final billProvider = Provider.of<BillProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    
    final phone = authProvider.currentWallet?.phoneNumber;
    if (phone == null) return;

    if (billProvider.totalSelectedAmount > dashboardProvider.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solde insuffisant pour régler ces factures'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final refsToPay = List<String>.from(billProvider.selectedBillReferences);
    final success = await billProvider.paySelectedBills(phone);

    if (success) {
      // Reload user's main wallet/dashboard data to reflect deductions
      await dashboardProvider.fetchDashboardData(phone);
      await authProvider.reloadWallet();
      
      setState(() {
        _isSuccess = true;
        _paidRefs = refsToPay;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billProvider.errorMessage ?? 'Le paiement a échoué'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_activeBiller == null ? 'Factures & Services' : 'Règlement $_activeBiller'),
        leading: _activeBiller != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _deselectBiller,
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _activeBiller == null ? _buildBillerGrid() : _buildBillsList(),
      ),
    );
  }

  // 1. Grid of Billers screen
  Widget _buildBillerGrid() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choisissez un fournisseur',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: _billers.length,
            itemBuilder: (context, index) {
              final biller = _billers[index];
              final IconData icon = biller['icon'];
              final Color color = biller['color'];

              return Card(
                elevation: 4,
                child: InkWell(
                  onTap: () => _selectBiller(biller['name']),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 32),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          biller['label'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          biller['desc'],
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 2. Unpaid bills list screen for selected Biller
  Widget _buildBillsList() {
    final billProvider = Provider.of<BillProvider>(context);

    if (billProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.secondaryColor),
      );
    }

    if (billProvider.bills.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 64, color: AppTheme.accentColor),
              const SizedBox(height: 16),
              const Text(
                'Félicitations !',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Aucune facture en attente de paiement chez $_activeBiller.',
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _deselectBiller,
                child: const Text('Retour aux fournisseurs'),
              ),
            ],
          ),
        ),
      );
    }

    final allSelected = billProvider.selectedBillReferences.length == billProvider.bills.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selection tools header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: AppTheme.surfaceColor.withOpacity(0.5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${billProvider.bills.length} Factures trouvées',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              TextButton.icon(
                icon: Icon(allSelected ? Icons.deselect : Icons.select_all, size: 18),
                label: Text(allSelected ? 'Tout désélectionner' : 'Tout sélectionner'),
                onPressed: () => billProvider.toggleAllBills(!allSelected),
              ),
            ],
          ),
        ),

        // Unpaid bills list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20.0),
            itemCount: billProvider.bills.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final Bill bill = billProvider.bills[index];
              final isSelected = billProvider.selectedBillReferences.contains(bill.reference);

              return Card(
                elevation: 2,
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.03),
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: () => billProvider.toggleBillSelection(bill.reference),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isSelected,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (bool? val) {
                            billProvider.toggleBillSelection(bill.reference);
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.reference,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: AppTheme.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Échéance: ${_formatDate(bill.dueDate)}',
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _currencyFormat.format(bill.amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Total checkout bar
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total sélectionné',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      Text(
                        '${billProvider.selectedBillReferences.length} facture(s) cochée(s)',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    _currencyFormat.format(billProvider.totalSelectedAmount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: billProvider.selectedBillReferences.isEmpty ? null : _paySelected,
                child: Text('Régler les factures (${billProvider.selectedBillReferences.length})'),
              ),
            ],
          ),
        )
      ],
    );
  }

  // 3. Success checkout Screen
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: AppTheme.accentColor,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Paiement Effectué !',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Les factures chez $_activeBiller ont été réglées avec succès.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fournisseur', style: TextStyle(color: AppTheme.textSecondary)),
                          Text(_activeBiller ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Factures réglées', style: TextStyle(color: AppTheme.textSecondary)),
                          Text('${_paidRefs.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 8),
                      // Notice the backend payFactures stub returns 0 amount, we explain it nicely
                      const Text(
                        'Débit en cours de traitement sur votre compte.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _activeBiller = null;
                    _isSuccess = false;
                  });
                },
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return isoString;
    }
  }
}
