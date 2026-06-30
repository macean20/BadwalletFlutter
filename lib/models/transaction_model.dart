class Transaction {
  final int id;
  final String reference;
  final String type; // DEPOSIT, WITHDRAW, TRANSFER, PAYMENT
  final double amount;
  final String walletPhone;
  final String? destinationPhone;
  final String createdAt;

  Transaction({
    required this.id,
    required this.reference,
    required this.type,
    required this.amount,
    required this.walletPhone,
    this.destinationPhone,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      walletPhone: json['walletPhone'] ?? '',
      destinationPhone: json['destinationPhone'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'type': type,
      'amount': amount,
      'walletPhone': walletPhone,
      'destinationPhone': destinationPhone,
      'createdAt': createdAt,
    };
  }

  // Helper getters
  bool get isCredit => type == 'DEPOSIT' || (type == 'TRANSFER' && destinationPhone == null); // wait, actually, for transfer, if destination phone is our wallet it is credit, if walletPhone is ours and destination is not ours it is debit. Let's make it customizable based on current phone number
  bool isIncoming(String currentPhone) {
    if (type == 'DEPOSIT') return true;
    if (type == 'TRANSFER' && destinationPhone == currentPhone) return true;
    return false;
  }
}
