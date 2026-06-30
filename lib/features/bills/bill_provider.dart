import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../models/bill_model.dart';

class BillProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<Bill> _bills = [];
  final List<String> _selectedBillReferences = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedBiller;

  List<Bill> get bills => _bills;
  List<String> get selectedBillReferences => _selectedBillReferences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedBiller => _selectedBiller;

  double get totalSelectedAmount {
    double total = 0.0;
    for (var bill in _bills) {
      if (_selectedBillReferences.contains(bill.reference)) {
        total += bill.amount;
      }
    }
    return total;
  }

  BillProvider(this._apiClient);

  // Set the currently active biller and fetch their bills
  Future<void> fetchBills(String phone, String biller) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedBiller = biller;
    _selectedBillReferences.clear();
    _bills = [];
    notifyListeners();

    try {
      final encodedPhone = Uri.encodeComponent(phone);
      final response = await _apiClient.client.get(
        '/api/external/factures/$encodedPhone/current',
        queryParameters: {'unite': biller},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data ?? [];
        _bills = data.map((json) => Bill.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erreur lors du chargement des factures';
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle invoice selection checkbox
  void toggleBillSelection(String reference) {
    if (_selectedBillReferences.contains(reference)) {
      _selectedBillReferences.remove(reference);
    } else {
      _selectedBillReferences.add(reference);
    }
    notifyListeners();
  }

  // Select/Deselect all bills
  void toggleAllBills(bool selectAll) {
    _selectedBillReferences.clear();
    if (selectAll) {
      for (var bill in _bills) {
        _selectedBillReferences.add(bill.reference);
      }
    }
    notifyListeners();
  }

  // Pay selected bills
  Future<bool> paySelectedBills(String phone) async {
    if (_selectedBillReferences.isEmpty || _selectedBiller == null) {
      _errorMessage = 'Aucune facture sélectionnée';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.post(
        '/api/wallets/pay-factures',
        data: {
          'phoneNumber': phone,
          'serviceName': _selectedBiller,
          'factureReferences': _selectedBillReferences,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _selectedBillReferences.clear();
        _bills.clear(); // Clear local list since they are paid
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Le paiement a échoué';
      _isLoading = false;
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Erreur lors du paiement';
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
