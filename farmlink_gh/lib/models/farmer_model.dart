class FarmerModel {
  final String id;
  final String farmName;
  final String farmLocation;
  final String farmSize;
  final String? description;
  final bool verified;
  final DateTime createdAt;
  final DateTime updatedAt;

  FarmerModel({
    required this.id,
    required this.farmName,
    required this.farmLocation,
    required this.farmSize,
    this.description,
    this.verified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmerModel.fromJson(Map<String, dynamic> json) {
    return FarmerModel(
      id: json['id'],
      farmName: json['farm_name'],
      farmLocation: json['farm_location'],
      farmSize: json['farm_size'],
      description: json['description'],
      verified: json['verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_name': farmName,
      'farm_location': farmLocation,
      'farm_size': farmSize,
      'description': description,
      'verified': verified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FarmerModel copyWith({
    String? id,
    String? farmName,
    String? farmLocation,
    String? farmSize,
    String? description,
    bool? verified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FarmerModel(
      id: id ?? this.id,
      farmName: farmName ?? this.farmName,
      farmLocation: farmLocation ?? this.farmLocation,
      farmSize: farmSize ?? this.farmSize,
      description: description ?? this.description,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
