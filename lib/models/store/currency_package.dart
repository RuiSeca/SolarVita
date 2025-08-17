import 'package:flutter/material.dart';

/// Currency package model for in-app purchases
class CurrencyPackage {
  final String id;
  final String title;
  final int coins;
  final double price;
  final String currencySymbol;
  final String description;
  final Color color;
  final bool popular;

  const CurrencyPackage({
    required this.id,
    required this.title,
    required this.coins,
    required this.price,
    required this.currencySymbol,
    required this.description,
    required this.color,
    this.popular = false,
  });

  // Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'coins': coins,
    'price': price,
    'currencySymbol': currencySymbol,
    'description': description,
    'popular': popular,
  };

  // Create from JSON
  factory CurrencyPackage.fromJson(Map<String, dynamic> json) => CurrencyPackage(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    coins: json['coins'] ?? 0,
    price: (json['price'] ?? 0).toDouble(),
    currencySymbol: json['currencySymbol'] ?? '£',
    description: json['description'] ?? '',
    color: _colorFromString(json['color']),
    popular: json['popular'] ?? false,
  );

  // Helper method to convert color from string
  static Color _colorFromString(String? colorString) {
    switch (colorString?.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  // Copy with method for immutability
  CurrencyPackage copyWith({
    String? id,
    String? title,
    int? coins,
    double? price,
    String? currencySymbol,
    String? description,
    Color? color,
    bool? popular,
  }) => CurrencyPackage(
    id: id ?? this.id,
    title: title ?? this.title,
    coins: coins ?? this.coins,
    price: price ?? this.price,
    currencySymbol: currencySymbol ?? this.currencySymbol,
    description: description ?? this.description,
    color: color ?? this.color,
    popular: popular ?? this.popular,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyPackage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CurrencyPackage(id: $id, title: $title, coins: $coins, price: $price)';
}