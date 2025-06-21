import 'package:flutter/material.dart';
import 'package:finanz_app/core/utils/icon_helper.dart';

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
  final String iconName;
  final Color color;
  final FixedTransactionType type;

  const FixedCategory({
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
      'type': type == FixedTransactionType.income ? 'income' : 'expense',
    };
  }

  /// Crear una categoría desde JSON
  factory FixedCategory.fromJson(Map<String, dynamic> json) {
    return FixedCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      legend: json['legend'] as String? ?? 'Sin descripción',
      iconName: json['iconName'] as String,
      color: Color(json['color'] as int),
      type: json['type'] == 'income' ? FixedTransactionType.income : FixedTransactionType.expense,
    );
  }

  /// Lista predefinida de categorías de gastos fijos
  static const List<FixedCategory> expenseCategories = [
    FixedCategory(
      id: 'housing',
      name: 'Vivienda',
      legend: 'Arriendo, administración, servicios públicos, internet fijo, mantenimiento, hijos, padres, mascotas',
      iconName: 'home',
      color: Colors.blue,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'main_food',
      name: 'Alimentación',
      legend: 'Mercado mensual, carnicería, frutas y verduras, productos de aseo, despensa',
      iconName: 'restaurant',
      color: Colors.orange,
      type: FixedTransactionType.expense,
    ), 
    FixedCategory(
      id: 'main_transport',
      name: 'Transporte',
      legend: 'Cuota vehículo, seguro, mantenimiento, SOAT, impuestos vehiculares',
      iconName: 'directions_car',
      color: Colors.purple,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'personal_services',
      name: 'Servicios Personales',
      legend: 'Plan de datos, gimnasio, suscripciones, belleza, educación, compras',
      iconName: 'person',
      color: Colors.pink,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'financial_obligations',
      name: 'Obligaciones Financieras',
      legend: 'Tarjetas de credito, creditos, seguros',
      iconName: 'credit_card',
      color: Colors.indigo,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'health',
      name: 'Salud',
      legend: 'Medicina prepagada, medicamentos, consultas, exámenes, odontología',
      iconName: 'medical_services',
      color: Colors.red,
      type: FixedTransactionType.expense,
    ),
    FixedCategory(
      id: 'other_fixed',
      name: 'Otros gastos fijos',
      legend: 'Gastos fijos varios no categorizados',
      iconName: 'more_horiz',
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
      iconName: 'work',
      color: Colors.green,
      type: FixedTransactionType.income,
    ),
    FixedCategory(
      id: 'complementary_income',
      name: 'Ingresos Complementarios',
      legend: 'Bonos mensuales, comisiones, negocios, inversiones, servicios profesionales',
      iconName: 'trending_up',
      color: Colors.teal,
      type: FixedTransactionType.income,
    ),
    FixedCategory(
      id: 'subsidies',
      name: 'Subsidios',
      legend: 'Transporte, alimentación, vivienda, educación, ayudas gubernamentales',
      iconName: 'school',
      color: Colors.amber,
      type: FixedTransactionType.income,
    ),
    /*FixedCategory(
      id: 'saving',
      name: 'Ahorro',
      legend: 'Ahorros, fondos de emergencia, metas financieras, inversiones a largo plazo, reservas para imprevistos',
      icon: Icons.savings_outlined,
      color: Colors.green,
      type: FixedTransactionType.income,
    ),*/
    FixedCategory(
      id: 'other_fixed_income',
      name: 'Otros ingresos fijos',
      legend: 'Ingresos fijos varios no categorizados',
      iconName: 'more_horiz',
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