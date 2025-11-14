// lib/models/reward.dart

class Reward {
  final int id;
  final String? name;
  final String? description;
  final int? pointsCost;
  final String? imageUrl;
  final int? categoryId;
  final String? categoryName;
  final int? stock;
  final bool? isActive;

  Reward({
    required this.id,
    this.name,
    this.description,
    this.pointsCost,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
    this.stock,
    this.isActive,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    int? _parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    bool? _parseBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      return v.toString().toLowerCase() == 'true' || v.toString() == '1';
    }
    
    // Read from snake_case keys from your DB/API
    final rewardName = json['name'] ?? json['item_name'] ?? json['itemName'];
    final cost = _parseInt(json['pointsCost'] ?? json['point_cost']);
    final category = _parseInt(json['categoryId'] ?? json['category_id']);
    final stock = _parseInt(json['stock'] ?? json['totalAvailableQuantity'] ?? json['total_available_quantity']);
    
    // Read imageUrl from the 'meta' jsonb object
    String? imageUrl;
    if (json['imageUrl'] != null) {
      imageUrl = json['imageUrl'];
    } else if (json['meta'] is Map<String, dynamic>) {
      imageUrl = json['meta']['imageUrl'];
    }

    return Reward(
      id: _parseInt(json['id']) ?? 0,
      name: rewardName,
      description: json['description'],
      pointsCost: cost,
      imageUrl: imageUrl,
      categoryId: category,
      categoryName: json['categoryName'], // From the API join
      stock: stock,
      isActive: _parseBool(json['isActive'] ?? json['is_active']),
    );
  }
}