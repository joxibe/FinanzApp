import 'package:flutter/material.dart';

/// Tipo de transacción fija
enum FixedTransactionType {
  expense,  // Gasto fijo
  income,   // Ingreso fijo
}

/// Modelo que representa una categoría para transacciones fijas
class FixedCategory {
  final String id;
  final String name;
  final String legend;  // Leyenda descriptiva de la categoría
  final IconData icon;
  final Color color;
  final FixedTransactionType type;

  const FixedCategory({
    required this.id,
    required this.name,
    required this.legend,
    required this.icon,
    required this.color,
    required this.type,
  });

  /// Lista predefinida de categorías de gastos fijos
  static const List<FixedCategory> expenseCategories = [
    FixedCategory(
      id: 'housing',
      name: 'Vivienda',
      legend: 'Arriendo, administración, servicios públicos, internet fijo, mantenimiento',
      icon: Icons.home,
      color: Colors.blue,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'main_food',
      name: 'Alimentación Principal',
      legend: 'Mercado mensual, carnicería, frutas y verduras, productos de aseo, despensa',
      icon: Icons.restaurant,
      color: Colors.orange,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'main_transport',
      name: 'Transporte Principal',
      legend: 'Cuota vehículo, seguro, mantenimiento, SOAT, impuestos vehiculares',
      icon: Icons.directions_car,
      color: Colors.purple,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'personal_services',
      name: 'Servicios Personales',
      legend: 'Plan de datos, gimnasio, suscripciones, belleza, educación',
      icon: Icons.person,
      color: Colors.pink,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'financial_obligations',
      name: 'Obligaciones Financieras',
      legend: 'Tarjetas, préstamos, seguros, fondos, inversiones',
      icon: Icons.credit_card,
      color: Colors.indigo,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'health',
      name: 'Salud',
      legend: 'Medicina prepagada, medicamentos, consultas, exámenes, odontología',
      icon: Icons.medical_services,
      color: Colors.red,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'other_fixed',
      name: 'Otros gastos fijos',
      legend: 'Gastos fijos varios no categorizados',
      icon: Icons.more_horiz,
      color: Colors.grey,
      type: FixedTransactionType.expense,
    ),
  ];

  /// Lista predefinida de categorías de ingresos fijos
  static const List<FixedCategory> incomeCategories = [
    FixedCategory(
      id: 'main_income',
      name: 'Ingresos Principales',
      legend: 'Salario fijo, honorarios, arriendos, pensiones, dividendos',
      icon: Icons.work,
      color: Colors.green,
      type: FixedTransactionType.income,
    ),
    FixedCategory(
      id: 'complementary_income',
      name: 'Ingresos Complementarios',
      legend: 'Bonos mensuales, comisiones, negocios, inversiones, servicios profesionales',
      icon: Icons.trending_up,
      color: Colors.teal,
      type: FixedTransactionType.income,
    ),
    FixedCategory(
      id: 'subsidies',
      name: 'Subsidios',
      legend: 'Transporte, alimentación, vivienda, educación, ayudas gubernamentales',
      icon: Icons.school,
      color: Colors.amber,
      type: FixedTransactionType.income,
    ),
    FixedCategory(
      id: 'other_fixed_income',
      name: 'Otros ingresos fijos',
      legend: 'Ingresos fijos varios no categorizados',
      icon: Icons.more_horiz,
      color: Colors.grey,
      type: FixedTransactionType.income,
    ),
  ];

  /// Obtener todas las categorías
  static List<FixedCategory> get allCategories => [
    ...expenseCategories,
    ...incomeCategories,
  ];

  /// Obtener categorías por tipo
  static List<FixedCategory> getCategoriesByType(FixedTransactionType type) {
    return type == FixedTransactionType.expense 
      ? expenseCategories 
      : incomeCategories;
  }
} 