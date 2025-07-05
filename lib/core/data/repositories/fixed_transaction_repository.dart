import 'package:flutter/material.dart';
import 'package:finanz_app/core/data/database/database_service.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_transaction.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:finanz_app/core/utils/icon_helper.dart';

class FixedTransactionRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<FixedTransaction>> getAllTransactions() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'fixed_transactions',
      orderBy: 'date DESC',
    );

    final List<FixedTransaction> transactions = [];
    for (var map in maps) {
      final categoryMap = await _db.query(
        'fixed_categories',
        where: 'id = ?',
        whereArgs: [map['category_id']],
      );

      if (categoryMap.isNotEmpty) {
        final category = FixedCategory(
          id: categoryMap[0]['id'],
          name: categoryMap[0]['name'],
          legend: categoryMap[0]['legend'] as String? ?? 'Sin descripción',
          iconName: categoryMap[0]['icon'] as String,
          color: Color(categoryMap[0]['color'] as int),
          type: categoryMap[0]['type'] == 'expense' 
            ? FixedTransactionType.expense 
            : FixedTransactionType.income,
        );

        transactions.add(FixedTransaction(
          id: map['id'] as String,
          description: map['description'] as String,
          amount: map['amount'] as double,
          date: DateTime.parse(map['date'] as String),
          category: category,
          type: map['type'] == 'expense' ? FixedTransactionType.expense : FixedTransactionType.income,
          dayOfMonth: map['dayOfMonth'] as int,
          status: map['status'] != null
              ? FixedTransactionStatus.values.firstWhere(
                  (e) => e.toString().split('.').last == map['status'],
                  orElse: () => FixedTransactionStatus.pendiente,
                )
              : FixedTransactionStatus.pendiente,
        ));
      }
    }

    return transactions;
  }

  Future<void> addTransaction(FixedTransaction transaction) async {
    await _db.insert('fixed_transactions', {
      'id': transaction.id,
      'description': transaction.description,
      'amount': transaction.amount,
      'date': transaction.date.toIso8601String(),
      'type': transaction.type.toString().split('.').last,
      'category_id': transaction.category.id,
      'dayOfMonth': transaction.dayOfMonth,
      'status': transaction.status.toString().split('.').last,
    });
  }

  Future<void> updateTransaction(FixedTransaction transaction) async {
    await _db.update(
      'fixed_transactions',
      {
        'description': transaction.description,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'type': transaction.type.toString().split('.').last,
        'category_id': transaction.category.id,
        'dayOfMonth': transaction.dayOfMonth,
        'status': transaction.status.toString().split('.').last,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(FixedTransaction transaction) async {
    await _db.delete(
      'fixed_transactions',
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<List<FixedTransaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'fixed_transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );

    final List<FixedTransaction> transactions = [];
    for (var map in maps) {
      final categoryMap = await _db.query(
        'fixed_categories',
        where: 'id = ?',
        whereArgs: [map['category_id']],
      );

      if (categoryMap.isNotEmpty) {
        final category = FixedCategory(
          id: categoryMap[0]['id'],
          name: categoryMap[0]['name'],
          legend: categoryMap[0]['legend'] as String? ?? 'Sin descripción',
          iconName: categoryMap[0]['icon'] as String,
          color: Color(categoryMap[0]['color'] as int),
          type: categoryMap[0]['type'] == 'expense' 
            ? FixedTransactionType.expense 
            : FixedTransactionType.income,
        );

        transactions.add(FixedTransaction(
          id: map['id'] as String,
          description: map['description'] as String,
          amount: map['amount'] as double,
          date: DateTime.parse(map['date'] as String),
          category: category,
          type: map['type'] == 'expense' ? FixedTransactionType.expense : FixedTransactionType.income,
          dayOfMonth: map['dayOfMonth'] as int,
          status: map['status'] != null
              ? FixedTransactionStatus.values.firstWhere(
                  (e) => e.toString().split('.').last == map['status'],
                  orElse: () => FixedTransactionStatus.pendiente,
                )
              : FixedTransactionStatus.pendiente,
        ));
      }
    }

    return transactions;
  }

  Future<void> deleteAllTransactions() async {
    await _db.delete('fixed_transactions');
  }
} 