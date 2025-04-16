// lib/models/guide.dart
import 'package:flutter/material.dart';

class Guide {
  final int id;
  final String title;
  final String categoryId; // UUID as string
  final String summary;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Guide({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.summary,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Guide.fromJson(Map<String, dynamic> json) {
    return Guide(
      id: json['id'],
      title: json['title'],
      categoryId: json['category'],
      summary: json['summary'],
      content: json['content'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class GuideCategory {
  final String id; // UUID as string
  final String title;
  final IconData icon;
  final int count;
  final Color color;
  final Color textColor;

  GuideCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.count,
    required this.color,
    required this.textColor,
  });
}