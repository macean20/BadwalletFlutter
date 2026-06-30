class Wallet {
  final int id;
  final String phoneNumber;
  final String email;
  final String code;
  final String currency;
  final double balance;
  final String createdAt;
  final String updatedAt;

  Wallet({
    required this.id,
    required this.phoneNumber,
    required this.email,
    required this.code,
    required this.currency,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] ?? 0,
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      code: json['code'] ?? '',
      currency: json['currency'] ?? 'XOF',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'email': email,
      'code': code,
      'currency': currency,
      'balance': balance,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
