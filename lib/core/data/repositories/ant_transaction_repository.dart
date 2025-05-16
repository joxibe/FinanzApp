import 'package:finanz_app/core/data/database/database_service.dart';
import 'package:finanz_app/features/balance/domain/models/ant_transaction.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';
import 'package:flutter/material.dart';

class AntTransactionRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<AntTransaction>> getAllTransactions() async {
    print('Recuperando todas las transacciones hormiga');
    final List<Map<String, dynamic>> maps = await _db.query(
      'ant_transactions',
      orderBy: 'date DESC',
    );
    print('Transacciones hormiga encontradas en BD: \\${maps.length}');

    final List<AntTransaction> transactions = [];
    for (var map in maps) {
      print('Procesando transacción hormiga: $map');
      final categoryMap = await _db.query(
        'ant_categories',
        where: 'id = ?',
        whereArgs: [map['category_id']],
      );
      print('Categoría hormiga encontrada: \\${categoryMap.isNotEmpty ? categoryMap[0] : "No encontrada"}');

      if (categoryMap.isNotEmpty) {
        final category = AntCategory(
          id: categoryMap[0]['id'],
          name: categoryMap[0]['name'],
          legend: categoryMap[0]['legend'] as String? ?? 'Sin descripción',
          icon: IconData(categoryMap[0]['icon'] as int, fontFamily: 'MaterialIcons'),
          color: Color(categoryMap[0]['color'] as int),
          type: AntTransactionType.values.firstWhere(
            (e) => e.toString() == 'AntTransactionType.${categoryMap[0]['type']}',
            orElse: () => AntTransactionType.expense,
          ),
        );

        print('Creando AntTransaction con tipo: ${map['type']} y fecha: ${map['date']}');

        AntTransactionType transactionType;
        final typeStr = map['type'].toString().toLowerCase();
        if (typeStr == 'income') {
          transactionType = AntTransactionType.income;
        } else {
          transactionType = AntTransactionType.expense;
        }

        transactions.add(AntTransaction(
          id: map['id'],
          description: map['description'],
          amount: map['amount'],
          date: DateTime.parse(map['date']),
          type: transactionType,
          category: category,
        ));
      }
    }

    return transactions;
  }

  Future<void> addTransaction(AntTransaction transaction) async {
    print('Guardando transacción hormiga: ${transaction.toMap()}');
    await _db.insert('ant_transactions', {
      'id': transaction.id,
      'description': transaction.description,
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'type': transaction.type.toString().split('.').last,
      'category_id': transaction.category.id,
    });
    print('Transacción hormiga guardada exitosamente');
  }

  Future<void> updateTransaction(AntTransaction transaction) async {
    await _db.update(
      'ant_transactions',
      {
        'description': transaction.description,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'type': transaction.type.toString().split('.').last,
        'category_id': transaction.category.id,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(AntTransaction transaction) async {
    await _db.delete(
      'ant_transactions',
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<List<AntTransaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'ant_transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );

    final List<AntTransaction> transactions = [];
    for (var map in maps) {
      final categoryMap = await _db.query(
        'ant_categories',
        where: 'id = ?',
        whereArgs: [map['category_id']],
      );

      if (categoryMap.isNotEmpty) {
        final category = AntCategory(
          id: categoryMap[0]['id'],
          name: categoryMap[0]['name'],
          legend: categoryMap[0]['legend'] as String? ?? 'Sin descripción',
          icon: IconData(int.parse(categoryMap[0]['icon']), fontFamily: 'MaterialIcons'),
          color: Color(int.parse(categoryMap[0]['color'])),
          type: AntTransactionType.values.firstWhere(
            (e) => e.toString() == 'AntTransactionType.${categoryMap[0]['type']}',
            orElse: () => AntTransactionType.expense,
          ),
        );

        transactions.add(AntTransaction(
          id: map['id'],
          description: map['description'],
          amount: map['amount'],
          date: DateTime.parse(map['date']),
          type: map['type'] == 'expense' ? AntTransactionType.expense : AntTransactionType.income,
          category: category,
        ));
      }
    }

    return transactions;
  }
} 