import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import 'auth_provider.dart';
import '../dashboard/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '+221');
  final _emailController = TextEditingController();
  final _balanceController = TextEditingController(text: '25000');
  final _codeController = TextEditingController();
  final _pinController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  
  // Login Phases: 'phone', 'pin', 'register'
  String _currentPhase = 'phone';
  String? _phoneError;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _balanceController.dispose();
    _codeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // Phase 1: Check Phone
  void _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone == '+221') {
      setState(() => _phoneError = 'Veuillez saisir un numéro de téléphone');
      return;
    }
    // Simple validation for Senegal number (starts with +221 followed by 9 digits)
    final senegalRegex = RegExp(r'^\+221\d{9}$');
    if (!senegalRegex.hasMatch(phone)) {
      setState(() => _phoneError = 'Format invalide (Ex: +221770000000)');
      return;
    }

    setState(() => _phoneError = null);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final exists = await authProvider.checkPhoneExists(phone);
    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (exists) {
      setState(() {
        _currentPhase = 'pin';
      });
    } else {
      // Auto-generate code based on phone suffix
      final phoneSuffix = phone.substring(phone.length - 4);
      _codeController.text = 'WLT-$phoneSuffix';
      _emailController.text = 'user$phoneSuffix@example.com';
      setState(() {
        _currentPhase = 'register';
      });
    }
  }

  // Phase 2: Verify PIN
  void _submitPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le code PIN doit comporter 4 chiffres'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyPin(pin);
    
    if (success) {
      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Code PIN incorrect'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Phase 3: Register New User
  void _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final code = _codeController.text.trim();
    final pin = _pinController.text.trim();

    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez configurer un code PIN à 4 chiffres'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.registerWallet(
      phone: phone,
      email: email,
      initialBalance: balance,
      code: code,
      currency: 'XOF',
      pin: pin,
    );

    if (success) {
      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Échec de la création'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // Support going back
  void _goBack() {
    setState(() {
      if (_currentPhase == 'pin' || _currentPhase == 'register') {
        _currentPhase = 'phone';
        _pinController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundColor, Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top header
                      Column(
                        children: [
                          if (_currentPhase != 'phone')
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textPrimary),
                                onPressed: _goBack,
                              ),
                            ),
                          const SizedBox(height: 16),
                          // Premium Logo Container
                          if (!isKeyboardOpen) ...[
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            'BadWallet',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getHeaderSubtitle(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),

                      // Main Form Container
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _buildPhaseContent(authProvider),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // Bottom notes / info
                      if (!isKeyboardOpen)
                        Text(
                          'Sécurisé par BadWallet Protocol. Tous droits réservés.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _getHeaderSubtitle() {
    switch (_currentPhase) {
      case 'pin':
        return 'Saisissez votre code PIN pour accéder au portefeuille';
      case 'register':
        return 'Créez votre compte BadWallet gratuitement';
      default:
        return 'Gérez votre argent instantanément de manière moderne';
    }
  }

  Widget _buildPhaseContent(AuthProvider authProvider) {
    if (authProvider.isLoading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20),
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
          SizedBox(height: 20),
          Text(
            'Vérification en cours...',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 20),
        ],
      );
    }

    switch (_currentPhase) {
      case 'pin':
        return _buildPinPhase();
      case 'register':
        return _buildRegisterPhase();
      default:
        return _buildPhonePhase();
    }
  }

  // Phase 1 Widget: Phone Form
  Widget _buildPhonePhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Numéro de téléphone',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          decoration: InputDecoration(
            hintText: '+221770000000',
            errorText: _phoneError,
            prefixIcon: const Icon(Icons.phone_android, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitPhone,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continuer'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  // Phase 2 Widget: PIN Form
  Widget _buildPinPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Code PIN secret',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez les 4 chiffres de votre code',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 16),
          decoration: const InputDecoration(
            counterText: '',
            prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryColor),
          ),
          onChanged: (val) {
            if (val.length == 4) {
              _submitPin();
            }
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitPin,
          child: const Text('Se connecter'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            // Simulated biometric unlock alert
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Authentification Biométrique'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fingerprint, size: 64, color: AppTheme.secondaryColor),
                    SizedBox(height: 16),
                    Text('Placez votre doigt sur le capteur pour déverrouiller BadWallet'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Simulate successful biometric login
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      authProvider.verifyPin('1234').then((success) {
                        if (success) _navigateToHome();
                      });
                    },
                    child: const Text('Simuler Succès'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  )
                ],
              ),
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint, size: 20),
              SizedBox(width: 8),
              Text('Utiliser la biométrie'),
            ],
          ),
        ),
      ],
    );
  }

  // Phase 3 Widget: Registration Form
  Widget _buildRegisterPhase() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nouveau Portefeuille',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'L\'email est obligatoire';
              if (!value.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code Portefeuille',
                    prefixIcon: Icon(Icons.wallet_giftcard),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Obligatoire';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _balanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Solde Initial (XOF)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Obligatoire';
                    if (double.tryParse(value) == null) return 'Nombre invalide';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'Créer Code PIN (4 chiffres)',
              prefixIcon: Icon(Icons.lock_reset),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.length < 4) return 'PIN à 4 chiffres requis';
              return null;
            },
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _submitRegistration,
            child: const Text('Créer mon compte'),
          ),
        ],
      ),
    );
  }
}
