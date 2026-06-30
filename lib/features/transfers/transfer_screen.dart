import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../dashboard/dashboard_provider.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _phoneController = TextEditingController();
  String _amountString = '0';
  String? _phoneError;
  String? _amountError;
  bool _isSuccess = false;
  String _txnReference = '';

  // Seeded list of potential recipients to quick pick (looks like real contact list!)
  final List<Map<String, String>> _contacts = [
    {'name': 'Amadou Diop', 'phone': '+221770000001'},
    {'name': 'Fatou Ndiaye', 'phone': '+221770000002'},
    {'name': 'Babacar Sow', 'phone': '+221770000004'},
    {'name': 'Mariama Diallo', 'phone': '+221770000005'},
    {'name': 'Ousmane Mane', 'phone': '+221770000006'},
  ];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'XOF',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  double get _enteredAmount => double.tryParse(_amountString) ?? 0.0;

  // Calculate 1% fee capped at 5000
  double get _fee {
    double calculated = _enteredAmount * 0.01;
    return calculated > 5000.0 ? 5000.0 : calculated;
  }

  double get _totalDebit => _enteredAmount + _fee;

  // Append key press to amount
  void _onKeyPress(String key) {
    setState(() {
      _amountError = null;
      if (key == 'C') {
        _amountString = '0';
      } else if (key == 'backspace') {
        if (_amountString.length > 1) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        } else {
          _amountString = '0';
        }
      } else {
        if (_amountString == '0') {
          _amountString = key;
        } else {
          // Prevent ridiculously large input
          if (_amountString.length < 9) {
            _amountString += key;
          }
        }
      }
    });
  }

  void _selectContact(String phone) {
    setState(() {
      _phoneController.text = phone;
      _phoneError = null;
    });
    Navigator.pop(context); // Close contact picker modal
  }

  void _showContactPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Contacts de confiance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                        child: Text(
                          contact['name']!.substring(0, 1),
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(contact['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(contact['phone']!),
                      onTap: () => _selectContact(contact['phone']!),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _validateAndConfirm() {
    final receiverPhone = _phoneController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final senderPhone = authProvider.currentWallet?.phoneNumber;

    // Validation
    if (receiverPhone.isEmpty) {
      setState(() => _phoneError = 'Veuillez renseigner le destinataire');
      return;
    }
    
    // Senegal phone validation
    final senegalRegex = RegExp(r'^\+221\d{9}$');
    if (!senegalRegex.hasMatch(receiverPhone)) {
      setState(() => _phoneError = 'Format requis: +22177XXXXXXX');
      return;
    }

    if (receiverPhone == senderPhone) {
      setState(() => _phoneError = 'Impossible de transférer à soi-même');
      return;
    }

    if (_enteredAmount <= 0) {
      setState(() => _amountError = 'Le montant doit être supérieur à 0');
      return;
    }

    if (_totalDebit > dashboardProvider.balance) {
      setState(() => _amountError = 'Solde insuffisant (Frais de transfert inclus)');
      return;
    }

    setState(() {
      _phoneError = null;
      _amountError = null;
    });

    _showConfirmationBottomSheet(senderPhone!, receiverPhone);
  }

  void _showConfirmationBottomSheet(String senderPhone, String receiverPhone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Confirmer le transfert',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Summary card
              Card(
                color: AppTheme.backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildSummaryRow('Destinataire', receiverPhone, isBold: true),
                      const Divider(color: Colors.white12, height: 24),
                      _buildSummaryRow('Montant', _currencyFormat.format(_enteredAmount)),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Frais de transfert (1%)', _currencyFormat.format(_fee), isMuted: true),
                      const Divider(color: Colors.white12, height: 24),
                      _buildSummaryRow(
                        'Total à débiter',
                        _currencyFormat.format(_totalDebit),
                        color: AppTheme.secondaryColor,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 28),
              
              ElevatedButton(
                onPressed: () => _executeTransfer(senderPhone, receiverPhone),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Confirmer & Envoyer'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isMuted = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isMuted ? AppTheme.textMuted : AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppTheme.textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  void _executeTransfer(String senderPhone, String receiverPhone) async {
    Navigator.pop(context); // Close bottom sheet
    
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final success = await dashboardProvider.sendTransfer(
      senderPhone: senderPhone,
      receiverPhone: receiverPhone,
      amount: _enteredAmount,
    );

    if (success) {
      setState(() {
        _isSuccess = true;
        // Retrieve transaction reference from the recent list
        if (dashboardProvider.transactions.isNotEmpty) {
          _txnReference = dashboardProvider.transactions.first.reference;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dashboardProvider.errorMessage ?? 'Le transfert a échoué'),
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

    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transférer de l\'argent'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Destinataire entry
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destinataire (Numéro de téléphone)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+221770000000',
                      errorText: _phoneError,
                      prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.contacts, color: AppTheme.secondaryColor),
                        onPressed: _showContactPicker,
                        tooltip: 'Choisir parmi les contacts de test',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Amount display area
            Expanded(
              child: Container(
                color: AppTheme.backgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Montant du transfert',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _currencyFormat.format(_enteredAmount),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: _amountError != null ? AppTheme.errorColor : AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                    if (_amountError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _amountError!,
                        style: const TextStyle(color: AppTheme.errorColor, fontSize: 13, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Frais associés: ${_currencyFormat.format(_fee)} (1% max 5000)',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Custom Keypad
            _buildCustomKeypad(dashboardProvider),
          ],
        ),
      ),
    );
  }

  // Success Screen
  Widget _buildSuccessScreen() {
    final formattedTotal = _currencyFormat.format(_enteredAmount);
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
                  Icons.check_circle_outline,
                  color: AppTheme.accentColor,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Transfert Réussi !',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Votre virement a été traité instantanément.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Receipt Container
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildSummaryRow('Montant envoyé', formattedTotal, isBold: true),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Destinataire', _phoneController.text),
                      if (_txnReference.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildSummaryRow('Référence', _txnReference, isMuted: true),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Transfer screen
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Retour au tableau de bord'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom numerical Keypad builder
  Widget _buildCustomKeypad(DashboardProvider dashboardProvider) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', 'backspace']
    ];

    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          ...keys.map((row) {
            return Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                    child: InkWell(
                      onTap: () => _onKeyPress(key),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: _getKeypadWidget(key),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 12),
          // Transfer execution button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: dashboardProvider.isLoading ? null : _validateAndConfirm,
                child: dashboardProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Envoyer le transfert'),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _getKeypadWidget(String key) {
    if (key == 'backspace') {
      return const Icon(Icons.backspace_outlined, color: AppTheme.textPrimary, size: 22);
    }
    
    Color textColor = AppTheme.textPrimary;
    if (key == 'C') {
      textColor = AppTheme.errorColor;
    }
    
    return Text(
      key,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }
}
