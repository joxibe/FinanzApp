import 'package:flutter/material.dart';
import 'package:finanz_app/core/utils/icon_helper.dart';

/// Tipo de transacción hormiga
enum AntTransactionType {
  expense,  // Gasto hormiga
  income,   // Ingreso hormiga
}

/// Modelo que representa una categoría para transacciones hormiga
class AntCategory {
  final String id;
  final String name;
  final String legend;  // Leyenda descriptiva de la categoría
  final String iconName;
  final Color color;
  final AntTransactionType type;

  const AntCategory({
    required this.id,
    required this.name,
    required this.legend,
    required this.iconName,
    required this.color,
    required this.type,
  });

  IconData get icon => IconHelper.getIconByName(iconName);

  /// Convertir a JSON para exportación
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'legend': legend,
      'iconName': iconName,
      'color': color.value,
      'type': type == AntTransactionType.income ? 'income' : 'expense',
    };
  }

  /// Crear una categoría desde JSON
  factory AntCategory.fromJson(Map<String, dynamic> json) {
    return AntCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      legend: json['legend'] as String? ?? 'Sin descripción',
      iconName: json['iconName'] as String,
      color: Color(json['color'] as int),
      type: json['type'] == 'income' ? AntTransactionType.income : AntTransactionType.expense,
    );
  }

  /// Lista predefinida de categorías de gastos hormiga
  static const List<AntCategory> expenseCategories = [
    AntCategory(
      id: 'food_drinks',
      name: 'Alimentación y Bebidas',
      legend: 'Cafés, comidas rápidas, snacks, bebidas, mercado pequeño',
      iconName: 'restaurant_menu',
      color: Colors.orange,
      type: AntTransactionType.expense,
    ),
    AntCategory(
      id: 'transport',
      name: 'Transporte',
      legend: 'Pasajes, taxi/plataformas, gasolina moto, parqueaderos, peajes',
      iconName: 'directions_car',
      color: Colors.blue,
      type: AntTransactionType.expense,
    ),
    AntCategory(
      id: 'entertainment',
      name: 'Entretenimiento',
      legend: 'Cine, videojuegos, streaming, salidas, eventos',
      iconName: 'games',
      color: Colors.purple,
      type: AntTransactionType.expense,
    ),
    AntCategory(
      id: 'personal_shopping',
      name: 'Compras Personales',
      legend: 'Ropa, belleza, tecnología, regalos, artículos para el hogar',
      iconName: 'shopping_bag',
      color: Colors.pink,
      type: AntTransactionType.expense,
    ),
    AntCategory(
      id: 'basic_services',
      name: 'Servicios Básicos',
      legend: 'Recargas, internet móvil, delivery, lavandería, impresiones',
      iconName: 'phone_android',
      color: Colors.teal,
      type: AntTransactionType.expense,
    ),
    AntCategory(
      id: 'other_expense',
      name: 'Otros gastos',
      legend: 'Gastos varios no categorizados',
      iconName: 'more_horiz',
      color: Colors.grey,
      type: AntTransactionType.expense,
    ),
  ];

  /// Lista predefinida de categorías de ingresos hormiga
  static const List<AntCategory> incomeCategories = [
    AntCategory(
      id: 'additional_income',
      name: 'Ingresos Adicionales',
      legend: 'Propinas, bonos pequeños, reembolsos, venta de artículos, trabajos freelance',
      iconName: 'attach_money',
      color: Colors.green,
      type: AntTransactionType.income,
    ),
    AntCategory(
      id: 'personal_income',
      name: 'Ingresos Personales',
      legend: 'Mesada, regalos en efectivo, premios, intereses, cashback',
      iconName: 'person',
      color: Colors.indigo,
      type: AntTransactionType.income,
    ),
    AntCategory(
      id: 'other_income',
      name: 'Otros ingresos',
      legend: 'Ingresos varios no categorizados',
      iconName: 'more_horiz',
      color: Colors.grey,
      type: AntTransactionType.income,
    ),
  ];

  /// Obtener todas las categorías
  static List<AntCategory> get allCategories => [
    ...expenseCategories,
    ...incomeCategories,
  ];

  /// Obtener categorías por tipo
  static List<AntCategory> getCategoriesByType(AntTransactionType type) {
    return type == AntTransactionType.expense 
      ? expenseCategories 
      : incomeCategories;
  }
} 