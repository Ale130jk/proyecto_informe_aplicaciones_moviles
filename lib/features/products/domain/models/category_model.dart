class CategoryModel {
  final String id;
  final String name;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    bool? isActive,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'isActive': isActive,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      name: map['name'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}