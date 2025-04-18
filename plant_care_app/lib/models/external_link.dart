class ExternalLink {
  final String id;
  final String categoryId;
  final String title;
  final String url;
  final String? thumbnailUrl;
  final String? description;
  final int order;
  final DateTime createdAt;

  ExternalLink({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.url,
    this.thumbnailUrl,
    this.description,
    required this.order,
    required this.createdAt,
  });

  factory ExternalLink.fromJson(Map<String, dynamic> json) {
    return ExternalLink(
      id: json['id'].toString(), // Convert int to String
      categoryId: json['category_id'].toString(), // Convert to String if needed
      title: json['title'],
      url: json['url'],
      thumbnailUrl: json['thumbnail_url'],
      description: json['description'],
      order: json['order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'description': description,
      'order': order,
      'created_at': createdAt.toIso8601String(),
    };
  }
}