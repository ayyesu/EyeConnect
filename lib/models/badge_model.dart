class Badge {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int requiredHelps;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.requiredHelps,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      requiredHelps: json['requiredHelps'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'requiredHelps': requiredHelps,
    };
  }
}
