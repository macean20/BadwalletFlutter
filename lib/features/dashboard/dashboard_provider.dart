import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../models/transaction_model.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  double _balance = 0.0;
  bool _isBalanceHidden = false;
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  double get balance => _balance;
  bool get isBalanceHidden => _isBalanceHidden;
  List<Transaction> get transactions => _transactions;
  List<Transaction> get recentTransactions => _transactions.take(5).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardProvider(this._apiClient);

  // Toggle hiding the balance on the dashboard
  void toggleBalanceHidden() {
    _isBalanceHidden = !_isBalanceHidden;
    notifyListeners();
  }

  // Fetch the current balance and transaction history
  Future<void> fetchDashboardData(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final encodedPhone = Uri.encodeComponent(phone);

      // 1. Fetch balance
      final balanceResponse = await _apiClient.client.get('/api/wallets/$encodedPhone/balance');
      if (balanceResponse.statusCode == 200) {
        _balance = (balanceResponse.data['balance'] as num?)?.toDouble() ?? 0.0;
      }

      // 2. Fetch transactions
      final txnResponse = await _apiClient.client.get('/api/wallets/$encodedPhone/transactions');
      if (txnResponse.statusCode == 200) {
        final List<dynamic> data = txnResponse.data ?? [];
        _transactions = data.map((json) => Transaction.fromJson(json)).toList();
        
        // Sort transactions by date descending (newest first)
        _transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erreur lors du chargement des données';
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send Money (Transfer)
  Future<bool> sendTransfer({
    required String senderPhone,
    required String receiverPhone,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.post(
        '/api/wallets/transfer',
        data: {
          'senderPhone': senderPhone,
          'receiverPhone': receiverPhone,
          'amount': amount,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Reload dashboard details to reflect new balance and transaction
        await fetchDashboardData(senderPhone);
        return true;
      }
      _errorMessage = 'Échec du transfert';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erreur lors du transfert';
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
}
