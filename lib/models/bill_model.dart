class Bill {
  final String reference;
  final double amount;
  final String serviceName; // ISM, WOYAFAL, RAPIDO, SENELEC, etc.
  final String clientCode;
  final String dueDate;
  final String status; // IMPAYEE, PAYEE

  Bill({
    required this.reference,
    required this.amount,
    required this.serviceName,
    required this.clientCode,
    required this.dueDate,
    required this.status,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      reference: json['reference'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      serviceName: json['serviceName'] ?? '',
      clientCode: json['clientCode'] ?? '',
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? 'IMPAYEE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference': reference,
      'amount': amount,
      'serviceName': serviceName,
      'clientCode': clientCode,
      'dueDate': dueDate,
      'status': status,
    };
  }
}
