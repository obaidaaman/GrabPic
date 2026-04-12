class Space {
  final String id;
  final String name;
  final DateTime? createdAt;
 
  const Space({required this.id, required this.name, this.createdAt});
 
  factory Space.fromJson(Map<String, dynamic> json) => Space(
        id:        json['id'] ?? '',
        name:      json['name'] ?? '',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}