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

  CategoryExpensesCard({
    super.key,
    required this.selectedDate,
    required this.isAnnualView,
  });

  Color _getFixedColor(FixedCategory category) {
    return category.color;
  }

  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
        final fijoTotal = legendFijos.fold<double>(0, (sum, cat) => sum + cat['amount']);
        final hormigaTotal = legendHormiga.fold<double>(0, (sum, cat) => sum + cat['amount']);

        // Colores adaptativos para modo oscuro
        final fixedLabelColor = isDark ? const Color(0xFF8BA4FF) : Colors.blue[700]!;
        final hormigaLabelColor = isDark ? const Color(0xFFDDA0DD) : Colors.purple[700]!;
        final fixedBgColor = isDark 
          ? const Color(0xFF8BA4FF).withOpacity(0.15) 
          : Colors.blue.shade100.withOpacity(0.35);
        final hormigaBgColor = isDark 
          ? const Color(0xFFDDA0DD).withOpacity(0.15) 
          : Colors.purple.shade100.withOpacity(0.35);

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
                  StatefulBuilder(
                    builder: (context, setState) {
                      final overlayTextColor = isDark ? Colors.white : Colors.black;
                      
                      return Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Overlay para porcentaje
                              if (touchedIndex >= 0 && touchedIndex < categories.length)
                                Positioned(
                                  top: -10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark 
                                          ? const Color(0xFF2C2D31).withOpacity(0.9)
                                          : Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '${(categories[touchedIndex]['percentage'] as double).toStringAsFixed(1)}%',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: overlayTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // Etiquetas mejoradas
                              Positioned(
                                left: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: hormigaBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: hormigaLabelColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Gasto Hormiga',
                                    style: TextStyle(
                                      color: hormigaLabelColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: fixedBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: fixedLabelColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Gasto Fijo',
                                    style: TextStyle(
                                      color: fixedLabelColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),

                              // Donut exterior
                              SizedBox(
                                height: 280,
                                width: 280,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 100,
                                    startDegreeOffset: 270,
                                    sections: [
                                      PieChartSectionData(
                                        value: fijoTotal,
                                        color: fixedLabelColor.withOpacity(0.2),
                                        showTitle: false,
                                        radius: 10,
                                      ),
                                      PieChartSectionData(
                                        value: hormigaTotal,
                                        color: hormigaLabelColor.withOpacity(0.2),
                                        showTitle: false,
                                        radius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Donut interno con GestureDetector
                              GestureDetector(
                                onTapDown: (details) {
                                  // Convertir coordenadas locales a coordenadas del centro del gráfico
                                  final center = Offset(130, 130); // Centro del widget de 260x260
                                  final tapPosition = details.localPosition - center;
                                  
                                  // Calcular la distancia desde el centro
                                  final distance = tapPosition.distance;
                                  
                                  // Verificar si el toque está dentro del donut (entre radio 40 y 90)
                                  if (distance >= 40 && distance <= 90) {
                                    // Calcular el ángulo del toque
                                    double angle = (tapPosition.direction * 180 / 3.14159 + 360 + 90) % 360;
                                    
                                    // Calcular qué sección fue tocada
                                    double currentAngle = 0;
                                    int tappedSection = -1;
                                    
                                    for (int i = 0; i < categories.length; i++) {
                                      final sectionAngle = (categories[i]['amount'] as double) / totalExpenses * 360;
                                      if (angle >= currentAngle && angle < currentAngle + sectionAngle) {
                                        tappedSection = i;
                                        break;
                                      }
                                      currentAngle += sectionAngle;
                                    }
                                    
                                    if (tappedSection != -1) {
                                      setState(() {
                                        // Toggle: si tocamos la misma sección, la deseleccionamos
                                        if (touchedIndex == tappedSection) {
                                          touchedIndex = -1;
                                        } else {
                                          // Si tocamos una sección diferente, la seleccionamos
                                          touchedIndex = tappedSection;
                                        }
                                      });
                                    }
                                  }
                                },
                                child: SizedBox(
                                  height: 260,
                                  width: 260,
                                  child: PieChart(
                                    PieChartData(
                                      sections: [
                                        for (int i = 0; i < categories.length; i++)
                                          PieChartSectionData(
                                            color: categories[i]['color'] as Color,
                                            value: categories[i]['amount'] as double,
                                            title: '',
                                            radius: touchedIndex == i ? 65 : 60,
                                            titleStyle: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black,
                                            ),
                                            titlePositionPercentageOffset: 1.3,
                                          ),
                                      ],
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 40,
                                      startDegreeOffset: 270,
                                      pieTouchData: PieTouchData(
                                        enabled: false, // Deshabilitamos el touch nativo
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  NumberFormatter.formatCurrency(totalExpenses),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  
                  // Sección de gastos fijos
                  if (legendFijos.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: fixedBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: fixedLabelColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: fixedLabelColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gastos fijos',
                            style: TextStyle(
                              color: fixedLabelColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...legendFijos.map((cat) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: cat['color'] as Color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (cat['color'] as Color).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Text(
                              cat['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${(cat['percentage'] as double).toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              NumberFormatter.formatCurrency(cat['amount'] as double),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  
                  // Sección de gastos hormiga
                  if (legendHormiga.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hormigaBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hormigaLabelColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: hormigaLabelColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gastos hormiga',
                            style: TextStyle(
                              color: hormigaLabelColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...legendHormiga.map((cat) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: cat['color'] as Color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (cat['color'] as Color).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: Text(
                              cat['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${(cat['percentage'] as double).toStringAsFixed(1)}%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              NumberFormatter.formatCurrency(cat['amount'] as double),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
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