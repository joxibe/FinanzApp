import 'package:flutter/material.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:finanz_app/core/data/database/database_service.dart';
import 'package:finanz_app/core/utils/icon_helper.dart';

class FixedCategoryRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<List<FixedCategory>> getAllCategories() async {
    final maps = await _dbService.query('fixed_categories');
    return List.generate(maps.length, (i) {
      final map = maps[i];
      return FixedCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        legend: map['legend'] as String? ?? 'Sin descripción',
        iconName: map['icon'] as String,
        color: Color(map['color'] as int),
        type: map['type'] == 'expense' 
          ? FixedTransactionType.expense 
          : FixedTransactionType.income,
      );
    });
  }

  Future<void> addCategory(FixedCategory category) async {
    await _dbService.insert('fixed_categories', {
      'id': category.id,
      'name': category.name,
      'legend': category.legend,
      'icon': category.iconName,
      'color': category.color.value,
      'type': category.type.toString(),
    });
  }

  Future<void> updateCategory(FixedCategory category) async {
    await _dbService.update(
      'fixed_categories',
      {
        'name': category.name,
        'legend': category.legend,
        'icon': category.iconName,
        'color': category.color.value,
        'type': category.type.toString(),
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(FixedCategory category) async {
    await _dbService.delete(
      'fixed_categories',
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteAllCategories() async {
    await _dbService.delete('fixed_categories');
  }
} 