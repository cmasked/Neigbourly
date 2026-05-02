/// Transaction model matching the FastAPI TransactionResponse schema.
class Transaction {
  final String id;
  final String rentalRequestId;
  final String communityId;
  final String ownerId;
  final String borrowerId;
  final String itemId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double dailyRate;
  final double totalRentalFee;
  final double commissionAmount;
  final DateTime? pickupAt;
  final DateTime? returnAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.rentalRequestId,
    required this.communityId,
    required this.ownerId,
    required this.borrowerId,
    required this.itemId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.dailyRate,
    required this.totalRentalFee,
    required this.commissionAmount,
    this.pickupAt,
    this.returnAt,
    this.completedAt,
    required this.createdAt,
  });

  int get rentalDays => endDate.difference(startDate).inDays;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      rentalRequestId: json['rental_request_id'],
      communityId: json['community_id'],
      ownerId: json['owner_id'],
      borrowerId: json['borrower_id'],
      itemId: json['item_id'],
      status: json['status'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      dailyRate: (json['daily_rate'] as num).toDouble(),
      totalRentalFee: (json['total_rental_fee'] as num).toDouble(),
      commissionAmount: (json['commission_amount'] as num).toDouble(),
      pickupAt: json['pickup_at'] != null ? DateTime.parse(json['pickup_at']) : null,
      returnAt: json['return_at'] != null ? DateTime.parse(json['return_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Payment model matching the FastAPI PaymentResponse schema.
class Payment {
  final String id;
  final String transactionId;
  final String paymentType;
  final double amount;
  final String escrowStatus;
  final String? gatewayReference;
  final String? gatewayProvider;
  final DateTime? paidAt;
  final DateTime? releasedAt;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.transactionId,
    required this.paymentType,
    required this.amount,
    required this.escrowStatus,
    this.gatewayReference,
    this.gatewayProvider,
    this.paidAt,
    this.releasedAt,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      transactionId: json['transaction_id'],
      paymentType: json['payment_type'],
      amount: (json['amount'] as num).toDouble(),
      escrowStatus: json['escrow_status'],
      gatewayReference: json['gateway_reference'],
      gatewayProvider: json['gateway_provider'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      releasedAt: json['released_at'] != null ? DateTime.parse(json['released_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Review model matching the FastAPI ReviewResponse schema.
class Review {
  final String id;
  final String transactionId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.transactionId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      transactionId: json['transaction_id'],
      reviewerId: json['reviewer_id'],
      revieweeId: json['reviewee_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Dispute model matching the FastAPI DisputeResponse schema.
class Dispute {
  final String id;
  final String transactionId;
  final String? damageReportId;
  final String communityId;
  final String filedBy;
  final String status;
  final String reason;
  final List<String>? evidenceUrls;
  final String? verdict;
  final String? verdictBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const Dispute({
    required this.id,
    required this.transactionId,
    this.damageReportId,
    required this.communityId,
    required this.filedBy,
    required this.status,
    required this.reason,
    this.evidenceUrls,
    this.verdict,
    this.verdictBy,
    this.resolvedAt,
    required this.createdAt,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'],
      transactionId: json['transaction_id'],
      damageReportId: json['damage_report_id'],
      communityId: json['community_id'],
      filedBy: json['filed_by'],
      status: json['status'],
      reason: json['reason'],
      evidenceUrls: json['evidence_urls'] != null
          ? List<String>.from(json['evidence_urls'])
          : null,
      verdict: json['verdict'],
      verdictBy: json['verdict_by'],
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
