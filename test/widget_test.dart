import 'package:flutter_test/flutter_test.dart';
import 'package:badwallet_flutter/models/wallet_model.dart';
import 'package:badwallet_flutter/models/transaction_model.dart';
import 'package:badwallet_flutter/models/bill_model.dart';

void main() {
  group('BadWallet Data Models Tests', () {
    test('Wallet Model JSON Parsing', () {
      final json = {
        'id': 105,
        'phoneNumber': '+221770000003',
        'email': 'user3@example.com',
        'code': 'WLT-003',
        'currency': 'XOF',
        'balance': 56000.00,
        'createdAt': '2026-06-29T14:42:24.136905',
        'updatedAt': '2026-06-30T14:15:27.600624'
      };

      final wallet = Wallet.fromJson(json);

      expect(wallet.id, 105);
      expect(wallet.phoneNumber, '+221770000003');
      expect(wallet.email, 'user3@example.com');
      expect(wallet.code, 'WLT-003');
      expect(wallet.balance, 56000.00);
      expect(wallet.currency, 'XOF');
    });

    test('Transaction Model JSON Parsing and Direction Helpers', () {
      final json = {
        'id': 7,
        'reference': 'TXN-BCFD06099A554633',
        'type': 'TRANSFER',
        'amount': 6000.00,
        'walletPhone': '+221770000003',
        'destinationPhone': '+221770000001',
        'createdAt': '2026-06-29T14:53:58.307416'
      };

      final transaction = Transaction.fromJson(json);

      expect(transaction.id, 7);
      expect(transaction.reference, 'TXN-BCFD06099A554633');
      expect(transaction.amount, 6000.0);
      expect(transaction.walletPhone, '+221770000003');
      
      // Test helper logic
      expect(transaction.isIncoming('+221770000001'), true);
      expect(transaction.isIncoming('+221770000003'), false);
    });

    test('Bill Model JSON Parsing', () {
      final json = {
        'reference': 'FAC-ISM-3-1',
        'amount': 50000.00,
        'serviceName': 'ISM',
        'clientCode': '+221770000003',
        'dueDate': '2026-06-15',
        'status': 'IMPAYEE'
      };

      final bill = Bill.fromJson(json);

      expect(bill.reference, 'FAC-ISM-3-1');
      expect(bill.amount, 50000.0);
      expect(bill.serviceName, 'ISM');
      expect(bill.clientCode, '+221770000003');
      expect(bill.status, 'IMPAYEE');
    });
  });
}
