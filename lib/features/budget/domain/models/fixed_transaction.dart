import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'fixed_category.dart';
import 'package:finanz_app/core/utils/icon_helper.dart';

/// Estado de la transacción fija
enum FixedTransactionStatus { pendiente, pagado }

/// Modelo que representa una transacción fija (gasto o ingreso)
class FixedTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;  // Solo se usa el día del mes
  final FixedCategory category;
  final FixedTransactionType type;
  final int dayOfMonth;
  final FixedTransactionStatus status;

  const FixedTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    required this.dayOfMonth,
    this.status = FixedTransactionStatus.pendiente,
  });

  /// Factory constructor para crear una nueva transacción fija
  factory FixedTransaction.create({
    required String description,
    required double amount,
    required FixedCategory category,
    required int dayOfMonth,
    required FixedTransactionType type,
    FixedTransactionStatus status = FixedTransactionStatus.pendiente,
  }) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, dayOfMonth);

    return FixedTransaction(
      id: const Uuid().v4(),
      description: description,
      amount: amount,
      date: date,
      category: category,
      type: type,
      dayOfMonth: dayOfMonth,
      status: status,
    );
  }

  /// Crear una copia de la transacción con algunos campos modificados
  FixedTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    FixedCategory? category,
    FixedTransactionType? type,
    int? dayOfMonth,
    FixedTransactionStatus? status,
  }) {
    return FixedTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      status: status ?? this.status,
    );
  }

  /// Convertir la transacción a un mapa
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': category.id,
      'type': type.toString(),
      'dayOfMonth': dayOfMonth,
      'status': status.toString().split('.').last,
    };
  }
  
  /// Convertir a JSON para exportación de datos
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'dayOfMonth': dayOfMonth,
      'category': {
        'id': category.id,
        'name': category.name,
        'icon': category.icon.codePoint,
        'color': category.color.value,
      },
      'type': type == FixedTransactionType.income ? 'income' : 'expense',
      'status': status.toString().split('.').last,
    };
  }

  /// Crear una transacción desde un mapa
  factory FixedTransaction.fromMap(Map<String, dynamic> map) {
    final categoryId = map['category_id'] as String? ?? map['categoryId'] as String;
    final category = FixedCategory.allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => FixedCategory.expenseCategories.last,
    );
    final statusString = map['status'] as String? ?? 'pendiente';
    final status = FixedTransactionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusString,
      orElse: () => FixedTransactionStatus.pendiente,
    );
    return FixedTransaction(
      id: map['id'] as String,
      description: map['description'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      category: category,
      type: FixedTransactionType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      dayOfMonth: map['dayOfMonth'] as int,
      status: status,
    );
  }

  factory FixedTransaction.empty() {
    return FixedTransaction(
      id: '',
      description: '',
      amount: 0,
      category: FixedCategory.expenseCategories.first,
      date: DateTime.now(),
      type: FixedTransactionType.expense,
      dayOfMonth: DateTime.now().day,
      status: FixedTransactionStatus.pendiente,
    );
  }

  /// Crear una transacción desde JSON
  factory FixedTransaction.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['category'] as Map<String, dynamic>;
    final category = FixedCategory(
      id: categoryJson['id'] as String,
      name: categoryJson['name'] as String,
      legend: categoryJson['legend'] as String? ?? 'Sin descripción',
      iconName: IconHelper.getIconNameByCodePoint(categoryJson['icon'] as int),
      color: Color(categoryJson['color'] as int),
      type: categoryJson['type'] == 'income' ? FixedTransactionType.income : FixedTransactionType.expense,
    );
    final statusString = json['status'] as String? ?? 'pendiente';
    final status = FixedTransactionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusString,
      orElse: () => FixedTransactionStatus.pendiente,
    );
    return FixedTransaction(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: json['amount'] as double,
      date: DateTime.parse(json['date'] as String),
      category: category,
      type: json['type'] == 'income' ? FixedTransactionType.income : FixedTransactionType.expense,
      dayOfMonth: json['dayOfMonth'] as int,
      status: status,
    );
  }

  @override
  String toString() {
    return 'FixedTransaction(id: $id, description: $description, amount: $amount, date: $date, category: ${category.name}, type: $type, status: $status)';
  }
} 