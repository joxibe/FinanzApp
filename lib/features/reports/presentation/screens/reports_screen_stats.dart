import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_transaction.dart';
import 'package:finanz_app/features/balance/domain/models/ant_transaction.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';

// Constantes para las categorías de presupuesto
const Map<String, List<String>> _budgetCategories = {
  'Necesidades Básicas (50%)': [
    'Vivienda',
    'Alimentación',
    'Servicios básicos',
    'Transporte',
    'Salud',
    'Hijos',
    'Padres',
    'Mascotas',
  ],
  'Gastos Personales (30%)': [
    'Entretenimiento',
    'Compras',
    'Suscripciones',
    'Educacion',
    'Tarjetas de credito',
    'Creditos',
    'Gastos hormiga',
  ],
  'Ahorro e Inversión (20%)': [
    'Fondo de emergencia',
    'Ahorro a largo plazo',
    'Inversiones',
    'Deudas',
  ],
};

// Constantes para las categorías principales de la regla 50/30/20
const Map<String, List<Map<String, String>>> _mainBudgetCategories = {
  'Necesidades Básicas (50%)': [
    {'id': 'housing', 'name': 'Vivienda'},
    {'id': 'main_food', 'name': 'Alimentación'},
    {'id': 'main_transport', 'name': 'Transporte'},
    {'id': 'health', 'name': 'Salud'},
  ],
  'Gastos Personales (30%)': [
    {'id': 'personal_services', 'name': 'Servicios personales'},
    {'id': 'financial_obligations', 'name': 'Obligaciones financieras'},
    {'id': 'other_fixed', 'name': 'Otros gastos fijos'},
    {'id': 'hormiga', 'name': 'Gastos hormiga'},
  ],
  'Ahorro e Inversión (20%)': [
    {'id': 'saving', 'name': 'Ahorro e inversión'},
  ],
};

String _getMonthName(int month) {
  const months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];
  return months[month - 1];
}

class StatisticsCard extends StatelessWidget {
  final DateTime selectedDate;
  final bool isAnnualView;
  final Function(BuildContext, AppState, DateTime, bool) onShowGastosHormigaAnalysis;

  const StatisticsCard({
    super.key,
    required this.selectedDate,
    required this.isAnnualView,
    required this.onShowGastosHormigaAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Filtrar transacciones según la vista seleccionada
        final filteredFixedTransactions = appState.fixedTransactions.where((t) {
          if (isAnnualView) {
            return t.date.year == selectedDate.year;
          } else {
            return t.date.year == selectedDate.year && 
                   t.date.month == selectedDate.month;
          }
        }).toList();

        // Calcular ingresos fijos totales según la vista
        double totalFixedIncome;
        if (isAnnualView) {
          // Para vista anual, sumamos los ingresos de cada mes
          final Map<int, double> monthlyIncomes = {};
          for (var transaction in filteredFixedTransactions.where((t) => t.type == FixedTransactionType.income)) {
            final month = transaction.date.month;
            monthlyIncomes[month] = (monthlyIncomes[month] ?? 0) + transaction.amount;
          }
          // Sumamos el ingreso mensual de cada mes
          totalFixedIncome = monthlyIncomes.values.fold(0.0, (sum, monthIncome) => sum + monthIncome);
        } else {
          // Para vista mensual, sumamos los ingresos del mes
          totalFixedIncome = filteredFixedTransactions
              .where((t) => t.type == FixedTransactionType.income)
              .fold(0.0, (sum, t) => sum + t.amount);
        }

        // Calcular gastos actuales por categoría según la regla 50/30/20
        double necesidadesBasicas = 0.0;
        double gastosPersonales = 0.0;
        double ahorroInversion = 0.0;

        // Clasificar gastos fijos en categorías según la regla 50/30/20
        for (var transaction in filteredFixedTransactions) {
          if (transaction.type == FixedTransactionType.expense) {
            // Necesidades Básicas (50%)
            if (transaction.category.id == 'housing' || // Vivienda
                transaction.category.id == 'main_food' || // Alimentación Principal
                transaction.category.id == 'main_transport' || // Transporte Principal
                transaction.category.id == 'health') { // Salud
              necesidadesBasicas += transaction.amount;
            }
            // Gastos Personales (30%)
            else if (transaction.category.id == 'personal_services' || // Servicios Personales
                     transaction.category.id == 'other_fixed' || // Otros Gastos Fijos
                     transaction.category.id == 'financial_obligations') { // Obligaciones Financieras
              gastosPersonales += transaction.amount;
            }
            // Ahorro e Inversión (20%) - No hay categorías específicas para esto
            // ya que son gastos que deberían ser manejados manualmente
          }
        }

        // Calcular montos recomendados según la regla 50/30/20
        final necesidadesBasicasRecomendado = totalFixedIncome * 0.5;
        final gastosPersonalesRecomendado = totalFixedIncome * 0.3;
        final ahorroInversionRecomendado = totalFixedIncome * 0.2;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estadísticas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _ExpandableStatisticItem(
                  title: isAnnualView ? 'Promedio Mensual' : 'Promedio Diario',
                  value: isAnnualView ? 'Promedio por mes' : 'Promedio por día',
                  amount: _calculateDailyAverage(appState.antTransactions, selectedDate, isAnnualView),
                  icon: Icons.calendar_today,
                  onTap: () {
                    final stats = _calculateDailyStats(appState.antTransactions, selectedDate, isAnnualView);
                    showDialog(
                      context: context,
                      builder: (context) => _BaseDialog(
                        title: isAnnualView ? 'Análisis de gastos mensuales' : 'Análisis de gastos diarios',
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAnnualView 
                                ? 'Resumen del año ${selectedDate.year}:'
                                : 'Resumen del mes actual:',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            if (isAnnualView) ...[
                              _StatisticItem(
                                title: 'Promedio mensual',
                                value: 'Todos los meses',
                                amount: NumberFormatter.formatCurrency(stats['average'] ?? 0),
                                icon: Icons.trending_up,
                              ),
                              const SizedBox(height: 8),
                              _StatisticItem(
                                title: 'Mes con más gastos',
                                value: stats['maxDate'] != null 
                                  ? _getMonthName(stats['maxDate']!.month)
                                  : 'Sin datos',
                                amount: NumberFormatter.formatCurrency(stats['maxAmount'] ?? 0),
                                icon: Icons.arrow_upward,
                              ),
                              const SizedBox(height: 8),
                              _StatisticItem(
                                title: 'Mes con menos gastos',
                                value: stats['minDate'] != null 
                                  ? _getMonthName(stats['minDate']!.month)
                                  : 'Sin datos',
                                amount: NumberFormatter.formatCurrency(stats['minAmount'] ?? 0),
                                icon: Icons.arrow_downward,
                              ),
                            ] else ...[
                              _StatisticItem(
                                title: 'Promedio diario',
                                value: 'Todos los días',
                                amount: NumberFormatter.formatCurrency(stats['average'] ?? 0),
                                icon: Icons.trending_up,
                              ),
                              const SizedBox(height: 8),
                              _StatisticItem(
                                title: 'Día con más gastos',
                                value: stats['maxDate'] != null 
                                  ? '${stats['maxDate']!.day} de ${_getMonthName(stats['maxDate']!.month)}'
                                  : 'Sin datos',
                                amount: NumberFormatter.formatCurrency(stats['maxAmount'] ?? 0),
                                icon: Icons.arrow_upward,
                              ),
                              const SizedBox(height: 8),
                              _StatisticItem(
                                title: 'Día con menos gastos',
                                value: stats['minDate'] != null 
                                  ? '${stats['minDate']!.day} de ${_getMonthName(stats['minDate']!.month)}'
                                  : 'Sin datos',
                                amount: NumberFormatter.formatCurrency(stats['minAmount'] ?? 0),
                                icon: Icons.arrow_downward,
                              ),
                            ],
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isAnnualView ? Icons.calendar_month : Icons.calendar_today,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAnnualView ? 'Consejo del Año' : 'Consejo del Mes',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isAnnualView
                                        ? 'Analiza tus gastos mes a mes para identificar patrones y temporadas de mayor gasto. '
                                          'Esto te ayudará a planificar mejor tu presupuesto anual y establecer metas realistas de ahorro.'
                                        : 'Observa tus patrones de gasto diario para entender mejor tus hábitos financieros. '
                                          'Los días de mayor gasto pueden indicar oportunidades de ahorro o necesidad de mejor planificación.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _AhorroPotencialItem(
                  amount: NumberFormatter.formatCurrency(
                    totalFixedIncome +
                    (isAnnualView
                      ? appState.antTransactions
                          .where((t) => t.date.year == selectedDate.year)
                          .where((t) => t.type == AntTransactionType.income)
                          .fold<double>(0, (sum, t) => sum + t.amount)
                      : appState.antTransactions
                          .where((t) => t.date.year == selectedDate.year && t.date.month == selectedDate.month)
                          .where((t) => t.type == AntTransactionType.income)
                          .fold<double>(0, (sum, t) => sum + t.amount)
                    )
                  ),
                  onTap: () => showBudgetRuleDialog(context, appState, selectedDate, isAnnualView),
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message: 'Total de gastos hormiga en el período seleccionado.\n'
                          'Los gastos hormiga son pequeños gastos frecuentes que sumados pueden representar una cantidad significativa.\n'
                          'Toca para ver el análisis detallado y descubrir tu potencial de ahorro.',
                  child: _GastosHormigaItem(
                    amount: NumberFormatter.formatCurrency(
                      isAnnualView
                        ? appState.antTransactions
                            .where((t) => t.date.year == selectedDate.year)
                            .where((t) => t.type == AntTransactionType.expense)
                            .fold<double>(0, (sum, t) => sum + t.amount)
                        : appState.antTransactions
                            .where((t) => t.date.year == selectedDate.year && 
                                        t.date.month == selectedDate.month)
                            .where((t) => t.type == AntTransactionType.expense)
                            .fold<double>(0, (sum, t) => sum + t.amount)
                    ),
                    onTap: () => onShowGastosHormigaAnalysis(context, appState, selectedDate, isAnnualView),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _calculateDailyAverage(List<AntTransaction> transactions, DateTime selectedDate, bool isAnnualView) {
    final filteredTransactions = transactions.where((t) {
      if (isAnnualView) {
        return t.date.year == selectedDate.year;
      } else {
        return t.date.year == selectedDate.year && 
               t.date.month == selectedDate.month;
      }
    }).toList();

    if (filteredTransactions.isEmpty) return NumberFormatter.formatCurrency(0);

    final totalExpenses = filteredTransactions
        .where((t) => t.type == AntTransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    if (isAnnualView) {
      // Para vista anual, calculamos el promedio mensual
      final average = totalExpenses / 12;
      return NumberFormatter.formatCurrency(average);
    } else {
      // Para vista mensual, calculamos el promedio diario
      final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
      final average = totalExpenses / daysInMonth;
      return NumberFormatter.formatCurrency(average);
    }
  }

  Map<String, dynamic> _calculateDailyStats(List<AntTransaction> transactions, DateTime selectedDate, bool isAnnualView) {
    final filteredTransactions = transactions.where((t) {
      if (isAnnualView) {
        return t.date.year == selectedDate.year;
      } else {
        return t.date.year == selectedDate.year && 
               t.date.month == selectedDate.month;
      }
    }).toList();

    if (filteredTransactions.isEmpty) {
      return {
        'average': 0.0,
        'minAmount': 0.0,
        'minDate': null,
        'maxAmount': 0.0,
        'maxDate': null,
        'total': 0.0,
        'count': 0,
      };
    }

    if (isAnnualView) {
      // Para vista anual, agrupamos por mes
      final Map<DateTime, double> monthlyExpenses = {};
      for (var transaction in filteredTransactions.where((t) => t.type == AntTransactionType.expense)) {
        final date = DateTime(transaction.date.year, transaction.date.month);
        monthlyExpenses[date] = (monthlyExpenses[date] ?? 0) + transaction.amount;
      }

      double totalExpenses = 0;
      double minAmount = double.infinity;
      DateTime? minDate;
      double maxAmount = 0;
      DateTime? maxDate;

      monthlyExpenses.forEach((date, amount) {
        totalExpenses += amount;
        
        if (amount < minAmount) {
          minAmount = amount;
          minDate = date;
        }
        
        if (amount > maxAmount) {
          maxAmount = amount;
          maxDate = date;
        }
      });

      final average = totalExpenses / 12; // Promedio mensual

      return {
        'average': average,
        'minAmount': minAmount == double.infinity ? 0 : minAmount,
        'minDate': minDate,
        'maxAmount': maxAmount,
        'maxDate': maxDate,
        'total': totalExpenses,
        'count': filteredTransactions.where((t) => t.type == AntTransactionType.expense).length,
      };
    } else {
      // Para vista mensual, agrupamos por día
      final Map<DateTime, double> dailyExpenses = {};
      for (var transaction in filteredTransactions.where((t) => t.type == AntTransactionType.expense)) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        dailyExpenses[date] = (dailyExpenses[date] ?? 0) + transaction.amount;
      }

      double totalExpenses = 0;
      double minAmount = double.infinity;
      DateTime? minDate;
      double maxAmount = 0;
      DateTime? maxDate;

      dailyExpenses.forEach((date, amount) {
        totalExpenses += amount;
        
        if (amount < minAmount) {
          minAmount = amount;
          minDate = date;
        }
        
        if (amount > maxAmount) {
          maxAmount = amount;
          maxDate = date;
        }
      });

      final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
      final average = totalExpenses / daysInMonth; // Promedio diario

      return {
        'average': average,
        'minAmount': minAmount == double.infinity ? 0 : minAmount,
        'minDate': minDate,
        'maxAmount': maxAmount,
        'maxDate': maxDate,
        'total': totalExpenses,
        'count': filteredTransactions.where((t) => t.type == AntTransactionType.expense).length,
      };
    }
  }

  double _calculateTotalPotentialSaving(List<AntTransaction> transactions, DateTime selectedDate, bool isAnnualView) {
    final filteredTransactions = transactions.where((t) {
      if (isAnnualView) {
        return t.date.year == selectedDate.year;
      } else {
        return t.date.year == selectedDate.year && 
               t.date.month == selectedDate.month;
      }
    }).toList();

    final Map<String, List<AntTransaction>> transactionsByCategory = {};
    for (var transaction in filteredTransactions.where((t) => t.type == AntTransactionType.expense)) {
      final categoryName = transaction.category.name;
      if (!transactionsByCategory.containsKey(categoryName)) {
        transactionsByCategory[categoryName] = [];
      }
      transactionsByCategory[categoryName]!.add(transaction);
    }

    double totalPotentialSaving = 0.0;
    transactionsByCategory.forEach((category, transactions) {
      final total = transactions.fold<double>(0, (sum, t) => sum + t.amount);
      double savingPercentage = 0.15;

      switch (category.toLowerCase()) {
        case 'alimentación y bebidas':
          savingPercentage = 0.2;
          break;
        case 'entretenimiento y ocio':
          savingPercentage = 0.3;
          break;
        case 'transporte y movilidad':
          savingPercentage = 0.15;
          break;
        case 'compras personales':
          savingPercentage = 0.25;
          break;
        case 'servicios básicos':
          savingPercentage = 0.1;
          break;
        case 'salud y bienestar':
          savingPercentage = 0.15;
          break;
        case 'educación y desarrollo':
          savingPercentage = 0.1;
          break;
        default:
          savingPercentage = 0.15;
      }

      totalPotentialSaving += total * savingPercentage;
    });

    return totalPotentialSaving;
  }

  static void showGastosHormigaAnalysis(BuildContext context, AppState appState, DateTime selectedDate, bool isAnnualView) {
    // Obtener transacciones hormiga según la vista seleccionada
    final filteredTransactions = appState.antTransactions.where((t) {
      if (isAnnualView) {
        return t.date.year == selectedDate.year;
      } else {
        return t.date.year == selectedDate.year && 
               t.date.month == selectedDate.month;
      }
    }).toList();

    // Agrupar por categoría
    final Map<String, List<AntTransaction>> transactionsByCategory = {};
    for (var transaction in filteredTransactions.where((t) => t.type == AntTransactionType.expense)) {
      final categoryName = transaction.category.name;
      if (!transactionsByCategory.containsKey(categoryName)) {
        transactionsByCategory[categoryName] = [];
      }
      transactionsByCategory[categoryName]!.add(transaction);
    }

    // Si es vista anual, calcular totales mensuales por categoría
    final Map<String, Map<int, double>> monthlyTotalsByCategory = {};
    if (isAnnualView) {
      transactionsByCategory.forEach((category, transactions) {
        monthlyTotalsByCategory[category] = {};
        for (var transaction in transactions) {
          final month = transaction.date.month;
          monthlyTotalsByCategory[category]![month] = 
            (monthlyTotalsByCategory[category]![month] ?? 0) + transaction.amount;
        }
      });
    }

    // Calcular totales y sugerencias por categoría
    final List<Map<String, dynamic>> categoryAnalysis = [];
    transactionsByCategory.forEach((category, transactions) {
      double total;
      if (isAnnualView) {
        // Para vista anual, sumamos los totales mensuales
        total = monthlyTotalsByCategory[category]!.values.fold(0.0, (sum, monthTotal) => sum + monthTotal);
      } else {
        total = transactions.fold<double>(0, (sum, t) => sum + t.amount);
      }
      
      final count = transactions.length;
      final average = isAnnualView ? total / 12 : total / count; // Promedio mensual o por transacción

      // Sugerencias específicas por categoría
      List<String> suggestions = [];
      double potentialSaving = 0.0;
      
      switch (category.toLowerCase()) {
        case 'alimentación y bebidas':
          suggestions = [
            '• Planifica tus comidas para ahorrar y aún darte el gusto de salir a comer de vez en cuando',
            '• Disfruta cocinar en casa como una experiencia creativa, e invita a alguien para hacerlo más especial',
            '• Compra inteligentemente: productos de temporada y al por mayor sin dejar de darte antojos ocasionales'
          ];
          potentialSaving = total * 0.15;
          break;
        case 'entretenimiento':
          suggestions = [
            '• Alterna actividades gratuitas o de bajo costo con salidas especiales que realmente disfrutes',
            '• Aprovecha descuentos y promociones para cine, teatro o conciertos sin dejar de divertirte',
            '• Elige experiencias significativas que te llenen de recuerdos más que de gastos'
          ];
          potentialSaving = total * 0.2;
          break;
        case 'transporte':
          suggestions = [
            '• Usa apps para compartir viajes y conoce nuevas personas mientras ahorras',
            '• Camina o usa bicicleta si puedes, es bueno para tu salud y tu bolsillo',
            '• Mantén tu vehículo en buen estado para evitar gastos inesperados y viajar con tranquilidad'
          ];
          potentialSaving = total * 0.15;
          break;
        case 'compras personales':
          suggestions = [
            '• Disfruta de comprar, pero con intención: prioriza artículos que realmente te hagan feliz',
            '• Espera eventos de descuentos para darte un gusto sin culpa',
            '• Usa la regla de 24 horas para pensar si realmente quieres algo o es un impulso'
          ];
          potentialSaving = total * 0.2;
          break;
        case 'servicios básicos':
          suggestions = [
            '• Optimiza tus consumos para tener más dinero libre sin sacrificar comodidad',
            '• Evalúa cambiar de proveedor si puedes mejorar el servicio y pagar menos',
            '• Apóyate en la tecnología para controlar el gasto y mejorar tu calidad de vida'
          ];
          potentialSaving = total * 0.1;
          break;
        default:
          suggestions = [
            '• Reflexiona sobre cómo ese gasto contribuye a tu felicidad o desarrollo',
            '• Establece un presupuesto flexible que te permita disfrutar sin excederte',
            '• Siempre hay formas de mejorar sin dejar de vivir bien'
          ];
          potentialSaving = total * 0.1;
      }

      categoryAnalysis.add({
        'category': category,
        'total': total,
        'count': count,
        'average': average,
        'suggestions': suggestions,
        'potentialSaving': potentialSaving,
        'icon': transactions.first.category.icon,
        'color': transactions.first.category.color,
        'monthlyTotals': isAnnualView ? monthlyTotalsByCategory[category] : null,
      });
    });

    // Ordenar por monto total
    categoryAnalysis.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));

    // Calcular ahorro total potencial
    final totalPotentialSaving = categoryAnalysis.fold<double>(
      0, (sum, analysis) => sum + (analysis['potentialSaving'] as double)
    );

    showDialog(
      context: context,
      builder: (context) => _BaseDialog(
        title: 'Análisis de Gastos Hormiga',
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAnnualView ? 'Resumen Anual' : 'Resumen Mensual',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total gastos hormiga: ${NumberFormatter.formatCurrency(
                        isAnnualView
                          ? filteredTransactions
                              .where((t) => t.type == AntTransactionType.expense)
                              .fold<double>(0, (sum, t) => sum + t.amount)
                          : filteredTransactions
                              .where((t) => t.type == AntTransactionType.expense)
                              .fold<double>(0, (sum, t) => sum + t.amount)
                      )}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAnnualView
                        ? 'Promedio mensual: ${NumberFormatter.formatCurrency(
                            filteredTransactions
                                .where((t) => t.type == AntTransactionType.expense)
                                .fold<double>(0, (sum, t) => sum + t.amount) / 12
                          )}'
                        : '',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ahorro potencial: ${NumberFormatter.formatCurrency(totalPotentialSaving)}',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...categoryAnalysis.map((analysis) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        analysis['icon'] as IconData,
                        color: analysis['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    analysis['category'] as String,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => _BaseDialog(
                                        title: analysis['category'] as String,
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (isAnnualView && analysis['monthlyTotals'] != null) ...[
                                              Text(
                                                'Gastos mensuales:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: analysis['color'] as Color,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ...(analysis['monthlyTotals'] as Map<int, double>).entries
                                                  .map((entry) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 4),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(_getMonthName(entry.key)),
                                                        Text(
                                                          NumberFormatter.formatCurrency(entry.value),
                                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                                        ),
                                                      ],
                                                    ),
                                                  ))
                                                  .toList(),
                                              const SizedBox(height: 16),
                                            ],
                                            Text(
                                              'Sugerencias de ahorro:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: analysis['color'] as Color,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            ...(analysis['suggestions'] as List<String>).map((suggestion) => 
                                              Padding(
                                                padding: const EdgeInsets.only(bottom: 8),
                                                child: Text(suggestion),
                                              ),
                                            ).toList(),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: (analysis['color'] as Color).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.savings, size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Ahorro potencial: ${NumberFormatter.formatCurrency(analysis['potentialSaving'] as double)}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  tooltip: 'Ver sugerencias de ahorro',
                                ),
                              ],
                            ),
                            Text(
                              isAnnualView
                                ? '${analysis['count']} transacciones • Promedio mensual: ${NumberFormatter.formatCurrency(analysis['average'] as double)}'
                                : '${analysis['count']} transacciones • Promedio: ${NumberFormatter.formatCurrency(analysis['average'] as double)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Total: ${NumberFormatter.formatCurrency(analysis['total'] as double)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (analysis['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.savings, 
                          color: analysis['color'] as Color,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ahorro potencial: ${NumberFormatter.formatCurrency(analysis['potentialSaving'] as double)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              )).toList(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consejo:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAnnualView
                        ? 'Los gastos hormiga pueden sumar grandes cantidades a lo largo del año. '
                          'Revisa regularmente tus patrones de gasto y ajusta tus hábitos según sea necesario.'
                        : 'Los gastos hormiga son pequeños gastos que suman grandes cantidades. '
                          'Identifica tus patrones de gasto y establece límites diarios o semanales '
                          'para cada categoría.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableStatisticItem extends StatelessWidget {
  final String title;
  final String value;
  final String amount;
  final IconData icon;
  final VoidCallback onTap;

  const _ExpandableStatisticItem({
    required this.title,
    required this.value,
    required this.amount,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Ver detalles',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AhorroPotencialItem extends StatelessWidget {
  final String amount;
  final VoidCallback onTap;

  const _AhorroPotencialItem({
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Regla 50/30/20',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Distribución de ingresos',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Ver detalles',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GastosHormigaItem extends StatelessWidget {
  final String amount;
  final VoidCallback onTap;

  const _GastosHormigaItem({
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.purple.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics,
                color: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Análisis de Gastos Hormiga',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Oportunidades de ahorro',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Ver detalles',
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final String title;
  final String value;
  final String amount;
  final IconData icon;
  final Color? color;

  const _StatisticItem({
    required this.title,
    required this.value,
    required this.amount,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color ?? Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _CategoryLegendItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;

  const _CategoryLegendItem({
    required this.icon,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryItem extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;
  final String currentAmount;
  final String recommendedAmount;
  final VoidCallback onInfoTap;
  final List<dynamic>? antTransactions;

  const _BudgetCategoryItem({
    required this.title,
    required this.color,
    required this.items,
    required this.currentAmount,
    required this.recommendedAmount,
    required this.onInfoTap,
    this.antTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.info_outline, color: color, size: 20),
                onPressed: onInfoTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Ver detalles',
              ),
            ],
          ),
          const SizedBox(height: 2),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 1),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 5,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            item,
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (title == '30% Gastos Personales' && item == 'Gastos hormiga' && antTransactions != null) ...[
                            const Spacer(),
                            Text(
                              NumberFormatter.formatCurrency(
                                antTransactions!
                                  .where((t) => t.type == AntTransactionType.expense)
                                  .fold(0.0, (sum, t) => sum + t.amount),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
          const SizedBox(height: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actual: $currentAmount',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                'Recomendado: $recommendedAmount',
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncomeSummaryItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String amount;

  const _IncomeSummaryItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

void showBudgetRuleDialog(BuildContext context, AppState appState, DateTime selectedDate, bool isAnnualView) {
  // Filtrar transacciones según la vista seleccionada
  final filteredFixedTransactions = appState.fixedTransactions.where((t) {
    if (isAnnualView) {
      return t.date.year == selectedDate.year;
    } else {
      return t.date.year == selectedDate.year && 
             t.date.month == selectedDate.month;
    }
  }).toList();

  // Filtrar transacciones hormiga según la vista seleccionada
  final filteredAntTransactions = appState.antTransactions.where((t) {
    if (isAnnualView) {
      return t.date.year == selectedDate.year;
    } else {
      return t.date.year == selectedDate.year && 
             t.date.month == selectedDate.month;
    }
  }).toList();

  // Calcular total de gastos hormiga
  final totalAntExpenses = filteredAntTransactions
      .where((t) => t.type == AntTransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  // Calcular ingresos fijos totales según la vista
  final totalFixedIncome = filteredFixedTransactions
      .where((t) => t.type == FixedTransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  // Calcular ingresos hormiga totales según la vista
  final totalAntIncome = filteredAntTransactions
      .where((t) => t.type == AntTransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  // Usar la suma de ambos ingresos para los cálculos recomendados
  final totalIncome = totalFixedIncome + totalAntIncome;

  // Calcular gastos actuales por categoría según la regla 50/30/20
  double necesidadesBasicas = 0.0;
  double gastosPersonales = 0.0;
  double ahorroInversion = 0.0;

  // Clasificar gastos fijos en categorías según la regla 50/30/20
  for (var transaction in filteredFixedTransactions) {
    if (transaction.type == FixedTransactionType.expense) {
      // Necesidades Básicas (50%)
      if (transaction.category.id == 'housing' || // Vivienda
          transaction.category.id == 'main_food' || // Alimentación Principal
          transaction.category.id == 'main_transport' || // Transporte Principal
          transaction.category.id == 'health') { // Salud
        necesidadesBasicas += transaction.amount;
      }
      // Gastos Personales (30%)
      else if (transaction.category.id == 'personal_services' || // Servicios Personales
               transaction.category.id == 'other_fixed' || // Otros Gastos Fijos
               transaction.category.id == 'financial_obligations') { // Obligaciones Financieras
        gastosPersonales += transaction.amount;
      }
      // Ahorro e Inversión (20%) - No hay categorías específicas para esto
      // ya que son gastos que deberían ser manejados manualmente
    }
  }

  // Sumar gastos hormiga a los gastos personales (30%)
  gastosPersonales += totalAntExpenses;

  // Calcular montos recomendados según la regla 50/30/20
  final necesidadesBasicasRecomendado = totalIncome * 0.5;
  final gastosPersonalesRecomendado = totalIncome * 0.3;
  final ahorroInversionRecomendado = totalIncome * 0.2;

  showDialog(
    context: context,
    builder: (context) => _BaseDialog(
      title: 'Regla 50/30/20',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'La regla 50/30/20 es una estrategia de presupuesto que divide tus ingresos en tres categorías:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Mostrar totales de ingresos fijos y hormiga en vertical
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IncomeSummaryItem(
                  icon: Icons.account_balance_wallet,
                  color: Colors.green,
                  label: 'Ingresos Fijos',
                  amount: NumberFormatter.formatCurrency(
                    filteredFixedTransactions
                      .where((t) => t.type == FixedTransactionType.income)
                      .fold(0.0, (sum, t) => sum + t.amount),
                  ),
                ),
                SizedBox(height: 8),
                _IncomeSummaryItem(
                  icon: Icons.trending_up,
                  color: Colors.purple,
                  label: 'Ingresos Hormiga',
                  amount: NumberFormatter.formatCurrency(
                    filteredAntTransactions
                      .where((t) => t.type == AntTransactionType.income)
                      .fold(0.0, (sum, t) => sum + t.amount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BudgetCategoryItem(
              title: '50% Necesidades Básicas',
              color: Colors.blue,
              items: _mainBudgetCategories['Necesidades Básicas (50%)']!.map((e) => e['name']!).toList(),
              currentAmount: NumberFormatter.formatCurrency(necesidadesBasicas),
              recommendedAmount: NumberFormatter.formatCurrency(necesidadesBasicasRecomendado),
              onInfoTap: () {
                showDialog(
                  context: context,
                  builder: (context) => _BaseDialog(
                    title: 'Necesidades Básicas (50%)',
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Esta categoría incluye los gastos esenciales para tu vida diaria:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const _CategoryLegendItem(
                            icon: Icons.home,
                            name: 'Vivienda',
                            description: 'Arriendo, administracion, hipoteca, servicios publicos, internet fijo y mantenimiento',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.restaurant,
                            name: 'Alimentación',
                            description: 'Compras de supermercado y comidas esenciales',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.water_drop,
                            name: 'Servicios básicos',
                            description: 'Agua, electricidad, gas, internet y telefonía básica',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.directions_bus,
                            name: 'Transporte',
                            description: 'Gasolina, transporte público y mantenimiento del vehículo',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.medical_services,
                            name: 'Salud',
                            description: 'Medicina prepagada, medicamentos, consultas, exámenes, odontología',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.child_care,
                            name: 'Hijos',
                            description: 'Educación, cuidado, vestimenta, alimentación',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.elderly,
                            name: 'Padres',
                            description: 'Cuidado, vestimenta, alimentación, regalos',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.pets,
                            name: 'Mascotas',
                            description: 'Cuidado, alimentación, veterinaria',
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Consejo: Prioriza estos gastos ya que son esenciales para tu bienestar diario. Busca formas de optimizarlos sin comprometer tu calidad de vida.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _BudgetCategoryItem(
              title: '30% Gastos Personales',
              color: Colors.orange,
              items: _mainBudgetCategories['Gastos Personales (30%)']!.map((e) => e['name']!).toList(),
              currentAmount: NumberFormatter.formatCurrency(gastosPersonales),
              recommendedAmount: NumberFormatter.formatCurrency(gastosPersonalesRecomendado),
              onInfoTap: () {
                showDialog(
                  context: context,
                  builder: (context) => _BaseDialog(
                    title: 'Gastos Personales (30%)',
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Esta categoría incluye gastos que mejoran tu calidad de vida y gastos hormiga:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const _CategoryLegendItem(
                            icon: Icons.person,
                            name: 'Servicios Personales',
                            description: 'Gimnasio, suscripciones, belleza, educación',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.credit_card,
                            name: 'Obligaciones Financieras',
                            description: 'Tarjetas de crédito, créditos personales',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.more_horiz,
                            name: 'Otros Gastos Fijos',
                            description: 'Gastos personales fijos varios',
                          ),
                          const _CategoryLegendItem(
                            icon: Icons.local_cafe,
                            name: 'Gastos Hormiga',
                            description: 'Cafés, snacks, comidas fuera, transporte ocasional, compras pequeñas',
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Consejo: Estos gastos son importantes para tu calidad de vida y bienestar emocional, pero mantén un balance. En ocasiones prioriza lo que realmente te hace feliz.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              antTransactions: filteredAntTransactions,
            ),
            const SizedBox(height: 16),
            _BudgetCategoryItem(
              title: '20% Ahorro e Inversión',
              color: Colors.green,
              items: _mainBudgetCategories['Ahorro e Inversión (20%)']!.map((e) => e['name']!).toList(),
              currentAmount: NumberFormatter.formatCurrency(ahorroInversion),
              recommendedAmount: NumberFormatter.formatCurrency(ahorroInversionRecomendado),
              onInfoTap: () {
                showDialog(
                  context: context,
                  builder: (context) => _BaseDialog(
                    title: 'Ahorro e Inversión (20%)',
                    content: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Esta sección está en desarrollo. Pronto podrás registrar y analizar tus ahorros e inversiones aquí.', style: TextStyle(fontSize: 15)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _BaseDialog extends StatelessWidget {
  final String title;
  final Widget content;

  const _BaseDialog({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
} 