class Gig {
  final int id;
  final String userId;
  final String title;
  final String description;
  final String priceEstimate;
  final String category;
  final String? imageUrl;
  final DateTime createdAt;

  Gig({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.priceEstimate,
    required this.category,
    this.imageUrl,
    required this.createdAt,
  });

  factory Gig.fromJson(Map<String, dynamic> json) => Gig(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'],
    description: json['description'],
    priceEstimate: json['price_estimate'] ?? 'Thỏa thuận',
    category: json['category'] ?? 'General',
    imageUrl: json['image_url'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
