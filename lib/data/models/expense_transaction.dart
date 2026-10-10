import 'package:flutter/foundation.dart';

/// Represents a saved expense transaction
@immutable
class ExpenseTransaction {
  final String id;
  final double totalAmount;
  final DateTime date;
  final String merchantName;
  final String category;
  final String? thumbnailPath;
  final String? rawOcrText;
  final DateTime createdAt;

  const ExpenseTransaction({
    required this.id,
    required this.totalAmount,
    required this.date,
    required this.merchantName,
    required this.category,
    this.thumbnailPath,
    this.rawOcrText,
    required this.createdAt,
  });

  ExpenseTransaction copyWith({
    String? id,
    double? totalAmount,
    DateTime? date,
    String? merchantName,
    String? category,
    String? thumbnailPath,
    String? rawOcrText,
    DateTime? createdAt,
  }) {
    return ExpenseTransaction(
      id: id ?? this.id,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'date': date.toIso8601String(),
      'merchant_name': merchantName,
      'category': category,
      'thumbnail_path': thumbnailPath,
      'raw_ocr_text': rawOcrText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ExpenseTransaction.fromMap(Map<String, dynamic> map) {
    return ExpenseTransaction(
      id: map['id'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      merchantName: map['merchant_name'] as String,
      category: map['category'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ExpenseTransaction(id: $id, amount: $totalAmount, merchant: $merchantName)';
}
