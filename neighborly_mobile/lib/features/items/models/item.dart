/// Item model matching the FastAPI ItemResponse schema.
class Item {
  final String id;
  final String ownerId;
  final String communityId;
  final String title;
  final String? description;
  final String category;
  final double dailyRate;
  final double? weeklyRate;
  final double depositRequired;
  final String? conditionDescription;
  final List<String>? imageUrls;
  final String status;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.ownerId,
    required this.communityId,
    required this.title,
    this.description,
    required this.category,
    required this.dailyRate,
    this.weeklyRate,
    required this.depositRequired,
    this.conditionDescription,
    this.imageUrls,
    required this.status,
    required this.createdAt,
  });

  String get primaryImage =>
      (imageUrls != null && imageUrls!.isNotEmpty) ? imageUrls!.first : '';

  bool get hasImages => imageUrls != null && imageUrls!.isNotEmpty;

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      ownerId: json['owner_id'],
      communityId: json['community_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      dailyRate: (json['daily_rate'] as num).toDouble(),
      weeklyRate: json['weekly_rate'] != null ? (json['weekly_rate'] as num).toDouble() : null,
      depositRequired: (json['deposit_required'] as num).toDouble(),
      conditionDescription: json['condition_description'],
      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : null,
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'community_id': communityId,
    'title': title,
    'description': description,
    'category': category,
    'daily_rate': dailyRate,
    'weekly_rate': weeklyRate,
    'deposit_required': depositRequired,
    'condition_description': conditionDescription,
    'image_urls': imageUrls,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}
