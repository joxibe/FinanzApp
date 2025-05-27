import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_transaction.dart';
import 'package:finanz_app/features/balance/domain/models/ant_transaction.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryExpensesCard extends StatelessWidget {
  final DateTime selectedDate;
  final bool isAnnualView;

  const CategoryExpensesCard({
    super.key,
    required this.selectedDate,
    required this.isAnnualView,
  });

  Color _getFixedColor(FixedCategory category) {
    return category.color;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Filtrar transacciones según la vista seleccionada
        final filteredFixed = appState.fixedTransactions.where((t) {
          if (isAnnualView) {
            return t.date.year == selectedDate.year;
          } else {
            return t.date.year == selectedDate.year && 
                   t.date.month == selectedDate.month;
          }
        }).where((t) => t.type == FixedTransactionType.expense).toList();

        final filteredHormiga = appState.antTransactions.where((t) {
          if (isAnnualView) {
            return t.date.year == selectedDate.year;
          } else {
            return t.date.year == selectedDate.year && 
                   t.date.month == selectedDate.month;
          }
        }).where((t) => t.type == AntTransactionType.expense).toList();

        // Agrupar gastos por categoría y tipo
        final Map<String, Map<String, dynamic>> categoryTotals = {};
        double totalExpenses = 0;

        // Gastos fijos
        for (var tx in filteredFixed) {
          final key = 'Fijo:${tx.category.id}';
          categoryTotals[key] = {
            'name': tx.category.name,
            'amount': (categoryTotals[key]?['amount'] ?? 0) + tx.amount,
            'color': _getFixedColor(tx.category),
            'type': 'Fijo',
          };
          totalExpenses += tx.amount;
        }
        // Gastos hormiga
        for (var tx in filteredHormiga) {
          final key = 'Hormiga:${tx.category.id}';
          categoryTotals[key] = {
            'name': tx.category.name,
            'amount': (categoryTotals[key]?['amount'] ?? 0) + tx.amount,
            'color': tx.category.color,
            'type': 'Hormiga',
          };
          totalExpenses += tx.amount;
        }

        // Convertir a lista y ordenar por monto
        final List<Map<String, dynamic>> basicFixed = [];
        final List<Map<String, dynamic>> personalFixed = [];
        final List<Map<String, dynamic>> ahorroFixed = [];
        final List<Map<String, dynamic>> hormiga = [];
        for (var entry in categoryTotals.entries) {
          final percentage = totalExpenses > 0 ? (entry.value['amount'] / totalExpenses * 100) : 0.0;
          final catMap = {
            'name': entry.value['name'],
            'amount': entry.value['amount'],
            'percentage': percentage,
            'color': entry.value['color'],
            'type': entry.value['type'],
          };
          if (entry.key.startsWith('Fijo:')) {
            final id = entry.key.substring(5);
            if ([
              'housing', 'main_food', 'basic_services', 'main_transport', 'health', 'education'
            ].contains(id)) {
              basicFixed.add(catMap);
            } else if ([
              'entertainment', 'personal_shopping', 'subscriptions', 'other_fixed'
            ].contains(id)) {
              personalFixed.add(catMap);
            } else {
              ahorroFixed.add(catMap);
            }
          } else {
            hormiga.add(catMap);
          }
        }
        // Ordenar hormiga por monto descendente
        hormiga.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
        // Unir todos en el orden deseado
        final categories = [
          ...basicFixed,
          ...personalFixed,
          ...ahorroFixed,
          ...hormiga,
        ];

        // Separar categorías en fijos y hormiga para la leyenda
        final legendFijos = categories.where((cat) => cat['type'] == 'Fijo').toList();
        final legendHormiga = categories.where((cat) => cat['type'] == 'Hormiga').toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gastos por Categoría',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (categories.isEmpty)
                  Center(
                    child: Text(
                      'No hay gastos registrados en este período',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    height: 280,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          for (var cat in categories)
                            PieChartSectionData(
                              color: cat['color'] as Color,
                              value: cat['amount'] as double,
                              title: '${(cat['percentage'] as double).toStringAsFixed(1)}%',
                              radius: 60,
                              titleStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                              titlePositionPercentageOffset: 1.35,
                              badgeWidget: null,
                            ),
                        ],
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        startDegreeOffset: 270,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Opcional: manejar toques en el gráfico
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (legendFijos.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.blue, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Gastos fijos',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...legendFijos.map((cat) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: cat['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat['name'] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            NumberFormatter.formatCurrency(cat['amount'] as double),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                  ],
                  if (legendHormiga.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.purple, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Gastos hormiga',
                            style: TextStyle(
                              color: Colors.purple[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...legendHormiga.map((cat) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: cat['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat['name'] as String,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            NumberFormatter.formatCurrency(cat['amount'] as double),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
} 