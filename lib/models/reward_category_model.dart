// lib/models/reward_category.dart

class RewardCategory {
  final int id;
  final String? name;

  RewardCategory({
    required this.id,
    this.name,
  });

  factory RewardCategory.fromJson(Map<String, dynamic> json) {
    return RewardCategory(
      id: (json['id'] as num? ?? 0).toInt(),
      name: json['name'] as String?,
    );
  }
}