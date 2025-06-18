class BookingModel {
  final String id;
  final String userId;
  final String expertId;
  final String serviceId;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime scheduledAt;
  final String? paymentStatus; // 'pending', 'paid', 'failed'
  final double? amount;
  final String? notes;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.expertId,
    required this.serviceId,
    required this.status,
    required this.scheduledAt,
    this.paymentStatus,
    this.amount,
    this.notes,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      expertId: map['expertId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      status: map['status'] ?? 'pending',
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(map['scheduledAt'] ?? 0),
      paymentStatus: map['paymentStatus'],
      amount: map['amount']?.toDouble(),
      notes: map['notes'],
      address: map['address'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'expertId': expertId,
      'serviceId': serviceId,
      'status': status,
      'scheduledAt': scheduledAt.millisecondsSinceEpoch,
      'paymentStatus': paymentStatus,
      'amount': amount,
      'notes': notes,
      'address': address,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    String? expertId,
    String? serviceId,
    String? status,
    DateTime? scheduledAt,
    String? paymentStatus,
    double? amount,
    String? notes,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      expertId: expertId ?? this.expertId,
      serviceId: serviceId ?? this.serviceId,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isPaymentPending => paymentStatus == 'pending';
  bool get isPaymentPaid => paymentStatus == 'paid';
  bool get isPaymentFailed => paymentStatus == 'failed';

  String get formattedAmount {
    if (amount == null) return 'TBD';
    return '₹${amount!.toStringAsFixed(0)}';
  }

  @override
  String toString() {
    return 'BookingModel(id: $id, userId: $userId, expertId: $expertId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}