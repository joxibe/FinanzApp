import 'package:finanz_app/core/data/database/database_service.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';
import 'package:flutter/material.dart';
import 'package:finanz_app/core/utils/icon_helper.dart';

class AntCategoryRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<AntCategory>> getAllCategories() async {
    final List<Map<String, dynamic>> maps = await _db.query('ant_categories');

    return List.generate(maps.length, (i) {
      return AntCategory(
        id: maps[i]['id'] as String,
        name: maps[i]['name'] as String,
        legend: maps[i]['legend'] as String? ?? 'Sin descripción',
        iconName: maps[i]['icon'] as String,
        color: Color(maps[i]['color'] as int),
        type: AntTransactionType.values.firstWhere(
          (e) => e.toString() == 'AntTransactionType.${maps[i]['type']}',
          orElse: () => AntTransactionType.expense,
        ),
      );
    });
  }

  Future<void> addCategory(AntCategory category) async {
    await _db.insert('ant_categories', {
      'id': category.id,
      'name': category.name,
      'legend': category.legend,
      'icon': category.iconName,
      'color': category.color.value,
      'type': category.type.toString().split('.').last,
    });
  }

  Future<void> updateCategory(AntCategory category) async {
    await _db.update(
      'ant_categories',
      {
        'name': category.name,
        'legend': category.legend,
        'icon': category.iconName,
        'color': category.color.value,
        'type': category.type.toString().split('.').last,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(AntCategory category) async {
    await _db.delete(
      'ant_categories',
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteAllCategories() async {
    await _db.delete('ant_categories');
  }
} 