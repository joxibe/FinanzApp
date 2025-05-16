import 'package:uuid/uuid.dart';
import 'ant_category.dart';

/// Modelo que representa una transacción hormiga (gasto o ingreso)
class AntTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final AntCategory category;
  final AntTransactionType type;

  const AntTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
  });

  /// Factory constructor para crear una nueva transacción
  factory AntTransaction.create({
    required String description,
    required double amount,
    required AntCategory category,
    required AntTransactionType type,
  }) {
    return AntTransaction(
      id: const Uuid().v4(),
      description: description,
      amount: amount,
      date: DateTime.now(),
      category: category,
      type: type,
    );
  }

  /// Crear una copia de la transacción con algunos campos modificados
  AntTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    AntCategory? category,
    AntTransactionType? type,
  }) {
    return AntTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
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
    };
  }

  /// Crear una transacción desde un mapa
  factory AntTransaction.fromMap(Map<String, dynamic> map) {
    final categoryId = map['category_id'] as String;
    final category = AntCategory.allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => AntCategory.expenseCategories.last,
    );

    return AntTransaction(
      id: map['id'] as String,
      description: map['description'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      category: category,
      type: AntTransactionType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
    );
  }

  factory AntTransaction.empty() {
    return AntTransaction(
      id: '',
      description: '',
      amount: 0,
      category: AntCategory.expenseCategories.first,
      date: DateTime.now(),
      type: AntTransactionType.expense,
    );
  }

  @override
  String toString() {
    return 'AntTransaction(id: $id, description: $description, amount: $amount, date: $date, category: ${category.name}, type: $type)';
  }
} 