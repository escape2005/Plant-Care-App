// lib/models/faq.dart
class FAQ {
  final String id;
  final String question;
  final String answer;
  final String? categoryId;
  final int order;
  bool isExpanded; // To track expansion state in UI

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    this.categoryId,
    required this.order,
    this.isExpanded = false, // Default not expanded
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      categoryId: json['category_id'],
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category_id': categoryId,
      'order': order,
    };
  }
}