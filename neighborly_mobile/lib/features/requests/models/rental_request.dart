/// Rental request model matching the FastAPI RentalRequestResponse schema.
class RentalRequest {
  final String id;
  final String itemId;
  final String borrowerId;
  final String communityId;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final double proposedDailyRate;
  final String? message;
  final DateTime? counterStartDate;
  final DateTime? counterEndDate;
  final double? counterDailyRate;
  final String? counterMessage;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const RentalRequest({
    required this.id,
    required this.itemId,
    required this.borrowerId,
    required this.communityId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.proposedDailyRate,
    this.message,
    this.counterStartDate,
    this.counterEndDate,
    this.counterDailyRate,
    this.counterMessage,
    this.expiresAt,
    required this.createdAt,
  });

  bool get hasCounter => counterDailyRate != null;

  factory RentalRequest.fromJson(Map<String, dynamic> json) {
    return RentalRequest(
      id: json['id'],
      itemId: json['item_id'],
      borrowerId: json['borrower_id'],
      communityId: json['community_id'],
      status: json['status'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      proposedDailyRate: (json['proposed_daily_rate'] as num).toDouble(),
      message: json['message'],
      counterStartDate: json['counter_start_date'] != null
          ? DateTime.parse(json['counter_start_date'])
          : null,
      counterEndDate: json['counter_end_date'] != null
          ? DateTime.parse(json['counter_end_date'])
          : null,
      counterDailyRate: json['counter_daily_rate'] != null
          ? (json['counter_daily_rate'] as num).toDouble()
          : null,
      counterMessage: json['counter_message'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
