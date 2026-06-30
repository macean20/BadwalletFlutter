import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/secure_storage.dart';
import '../../models/wallet_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  bool _isLoading = false;
  String? _errorMessage;
  Wallet? _currentWallet;
  bool _isAuthenticated = false;
  bool _isNewUser = false;
  String? _pendingPhone;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Wallet? get currentWallet => _currentWallet;
  bool get isAuthenticated => _isAuthenticated;
  bool get isNewUser => _isNewUser;
  String? get pendingPhone => _pendingPhone;

  AuthProvider(this._apiClient);

  // Initialize session from secure storage
  Future<void> initSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final storedPhone = await SecureStorage.getPhone();
      if (storedPhone != null) {
        // Fetch wallet to verify it still exists
        final response = await _apiClient.client.get('/api/wallets/$storedPhone');
        if (response.statusCode == 200) {
          _currentWallet = Wallet.fromJson(response.data);
          // Auto-authenticated if PIN is already set
          final storedPin = await SecureStorage.getPin();
          if (storedPin != null) {
            _isAuthenticated = true;
          }
        } else {
          await SecureStorage.clearAll();
        }
      }
    } catch (e) {
      debugPrint('Session initialization error: $e');
      // If server is unreachable, we do not clear secure storage, but we don't authenticate automatically
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if a phone number exists in the backend
  Future<bool> checkPhoneExists(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    _isNewUser = false;
    _pendingPhone = phone;
    notifyListeners();

    try {
      // URL encode the phone number (replacing + with %2B)
      final encodedPhone = Uri.encodeComponent(phone);
      final response = await _apiClient.client.get('/api/wallets/$encodedPhone');
      
      if (response.statusCode == 200) {
        _currentWallet = Wallet.fromJson(response.data);
        _isNewUser = false;
        _isLoading = false;
        notifyListeners();
        return true; // Wallet exists
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _isNewUser = true;
        _isLoading = false;
        notifyListeners();
        return false; // Wallet does not exist -> onboarding path
      }
      _errorMessage = 'Erreur de connexion au serveur : ${e.message}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register a new wallet in the backend (simulation helper)
  Future<bool> registerWallet({
    required String phone,
    required String email,
    required double initialBalance,
    required String code,
    required String currency,
    required String pin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.post(
        '/api/wallets',
        data: {
          'phoneNumber': phone,
          'email': email,
          'initialBalance': initialBalance,
          'code': code,
          'currency': currency,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentWallet = Wallet.fromJson(response.data);
        await SecureStorage.savePhone(phone);
        await SecureStorage.savePin(pin);
        _isNewUser = false;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Échec de la création du portefeuille';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erreur lors de la création du portefeuille';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur est survenue';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify PIN (simulated locally, but syncs with Secure Storage)
  Future<bool> verifyPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final storedPin = await SecureStorage.getPin();
      // If no PIN is registered (e.g. seeded wallets), we register this PIN as their default PIN!
      if (storedPin == null) {
        if (_pendingPhone != null) {
          await SecureStorage.savePhone(_pendingPhone!);
        }
        await SecureStorage.savePin(pin);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      if (storedPin == pin) {
        if (_currentWallet != null) {
          await SecureStorage.savePhone(_currentWallet!.phoneNumber);
        }
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Code PIN incorrect';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Une erreur est survenue lors de la vérification';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reload current wallet details from the server
  Future<void> reloadWallet() async {
    if (_currentWallet == null) return;
    try {
      final encodedPhone = Uri.encodeComponent(_currentWallet!.phoneNumber);
      final response = await _apiClient.client.get('/api/wallets/$encodedPhone');
      if (response.statusCode == 200) {
        _currentWallet = Wallet.fromJson(response.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Reload wallet error: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await SecureStorage.deletePhone();
    // We can keep the PIN for easy quick-access next time, or wipe it. Wipe is safer.
    await SecureStorage.deletePin();
    _currentWallet = null;
    _isAuthenticated = false;
    _isNewUser = false;
    _pendingPhone = null;
    notifyListeners();
  }
}
