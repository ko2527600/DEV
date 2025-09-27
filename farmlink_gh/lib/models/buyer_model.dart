class BuyerModel {
  final String id;
  final String companyName;
  final String businessType;
  final String location;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  BuyerModel({
    required this.id,
    required this.companyName,
    required this.businessType,
    required this.location,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BuyerModel.fromJson(Map<String, dynamic> json) {
    return BuyerModel(
      id: json['id'],
      companyName: json['company_name'],
      businessType: json['business_type'],
      location: json['location'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'business_type': businessType,
      'location': location,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BuyerModel copyWith({
    String? id,
    String? companyName,
    String? businessType,
    String? location,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BuyerModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      location: location ?? this.location,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
