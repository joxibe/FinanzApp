import 'package:uuid/uuid.dart';
import 'fixed_category.dart';

/// Modelo que representa una transacción fija (gasto o ingreso)
class FixedTransaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;  // Solo se usa el día del mes
  final FixedCategory category;
  final FixedTransactionType type;
  final int dayOfMonth;

  const FixedTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    required this.dayOfMonth,
  });

  /// Factory constructor para crear una nueva transacción fija
  factory FixedTransaction.create({
    required String description,
    required double amount,
    required FixedCategory category,
    required int dayOfMonth,
    required FixedTransactionType type,
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
  }) {
    return FixedTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
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
    };
  }

  /// Crear una transacción desde un mapa
  factory FixedTransaction.fromMap(Map<String, dynamic> map) {
    final categoryId = map['category_id'] as String;
    final category = FixedCategory.allCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => FixedCategory.expenseCategories.last,
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
    );
  }

  @override
  String toString() {
    return 'FixedTransaction(id: $id, description: $description, amount: $amount, date: $date, category: ${category.name}, type: $type)';
  }
} 