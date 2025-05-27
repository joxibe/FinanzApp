import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_transaction.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:finanz_app/features/balance/domain/models/ant_transaction.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

// Clase utilitaria para funciones comunes
class _Utils {
  static String getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}

// Widget base para diálogos
class _BaseDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;

  const _BaseDialog({
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(title: title),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: content,
              ),
            ),
            if (actions != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final String title;

  const _DialogHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

// Widget base para tarjetas de estadísticas
class _BaseCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _BaseCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isAnnualView = false;

  @override
  void initState() {
    super.initState();
  }

  List<int> _getAvailableYears(AppState appState) {
    final Set<int> years = {};
    final currentYear = DateTime.now().year;
    
    // Agregar años de transacciones fijas
    for (var transaction in appState.fixedTransactions) {
      if (transaction.date.year <= currentYear) {
        years.add(transaction.date.year);
      }
    }

    // Agregar años de transacciones hormiga
    for (var transaction in appState.antTransactions) {
      if (transaction.date.year <= currentYear) {
        years.add(transaction.date.year);
      }
    }

    // Si no hay años disponibles, agregar el año actual
    if (years.isEmpty) {
      years.add(currentYear);
    }

    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  List<DateTime> _getAvailableMonths(AppState appState) {
    final Set<DateTime> months = {};
    final now = DateTime.now();
    
    // Agregar meses de transacciones fijas
    for (var transaction in appState.fixedTransactions) {
      if (transaction.date.year == _selectedDate.year) {
        months.add(DateTime(_selectedDate.year, transaction.date.month));
      }
    }

    // Agregar meses de transacciones hormiga
    for (var transaction in appState.antTransactions) {
      if (transaction.date.year == _selectedDate.year) {
        months.add(DateTime(_selectedDate.year, transaction.date.month));
      }
    }

    // Si es el año actual, agregar el mes actual si no hay datos
    if (_selectedDate.year == now.year && months.isEmpty) {
      months.add(DateTime(now.year, now.month));
    }

    return months.toList()..sort((a, b) => b.compareTo(a));
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _toggleView() {
    setState(() {
      _isAnnualView = !_isAnnualView;
      // Si cambiamos a vista anual, ajustamos la fecha al primer día del año
      if (_isAnnualView) {
        _selectedDate = DateTime(_selectedDate.year, 1, 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _BalanceCard(
              selectedDate: _selectedDate,
              isAnnualView: _isAnnualView,
            ),
            const SizedBox(height: 16),
            _StatisticsCard(
              selectedDate: _selectedDate,
              isAnnualView: _isAnnualView,
              onShowGastosHormigaAnalysis: _showGastosHormigaAnalysis,
            ),
            const SizedBox(height: 16),
            _CategoryExpensesCard(
              selectedDate: _selectedDate,
              isAnnualView: _isAnnualView,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Obtener meses con registros
        final monthsWithData = _getMonthsWithData(appState);
        
        // Ordenar meses de más reciente a más antiguo
        monthsWithData.sort((a, b) => b.compareTo(a));

        // Verificar si el mes actual es el último disponible
        final now = DateTime.now();
        final currentMonth = DateTime(now.year, now.month);
        final isLastMonth = monthsWithData.isNotEmpty && 
                          monthsWithData.first.year == currentMonth.year && 
                          monthsWithData.first.month == currentMonth.month;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Selector de vista (Mensual/Anual)
            _buildViewSelector(context),
            // Selector de fecha
            _buildDateSelector(context),
          ],
        );
      },
    );
  }

  Widget _buildViewSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildViewButton(
          context,
          'Mensual',
          Icons.calendar_month,
          !_isAnnualView,
          () => setState(() => _isAnnualView = false),
        ),
        const SizedBox(width: 8),
        _buildViewButton(
          context,
          'Anual',
          Icons.calendar_view_month,
          _isAnnualView,
          () => setState(() => _isAnnualView = true),
        ),
      ],
    );
  }

  Widget _buildViewButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: isSelected ? Colors.white : colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : colorScheme.primary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? colorScheme.primary : Colors.transparent,
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.5),
          width: isSelected ? 0 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showDatePicker(context),
          icon: Icon(
            _isAnnualView ? Icons.calendar_today : Icons.calendar_month,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: Text(
            _isAnnualView
                ? _selectedDate.year.toString()
                : '${_Utils.getMonthName(_selectedDate.month)} ${_selectedDate.year}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    if (_isAnnualView) {
      final availableYears = _getAvailableYears(context.read<AppState>());
      if (!mounted) return;
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar Año'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableYears.length,
              itemBuilder: (context, index) {
                final year = availableYears[index];
                final isSelected = year == _selectedDate.year;
                
                return ListTile(
                  title: Text(
                    year.toString(),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : null,
                      color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : null,
                    ),
                  ),
                  trailing: isSelected 
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime(year, _selectedDate.month);
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    } else {
      final availableMonths = _getAvailableMonths(context.read<AppState>());
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar Mes'),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final date = DateTime(_selectedDate.year, month);
                final isAvailable = availableMonths.any((m) => 
                  m.year == date.year && m.month == date.month
                );
                final isSelected = month == _selectedDate.month;
                
                return OutlinedButton(
                  onPressed: isAvailable ? () {
                    setState(() {
                      _selectedDate = date;
                    });
                    Navigator.pop(context);
                  } : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.transparent,
                    side: BorderSide(
                      color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : isAvailable 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  child: Text(
                    _Utils.getMonthName(month),
                    style: TextStyle(
                      color: isSelected 
                        ? Colors.white 
                        : isAvailable 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      );
    }
  }

  List<DateTime> _getMonthsWithData(AppState appState) {
    final Set<DateTime> months = {};

    // Agregar meses de transacciones fijas
    for (var transaction in appState.fixedTransactions) {
      months.add(DateTime(transaction.date.year, transaction.date.month));
    }

    // Agregar meses de transacciones hormiga
    for (var transaction in appState.antTransactions) {
      months.add(DateTime(transaction.date.year, transaction.date.month));
    }

    return months.toList();
  }

  void _showGastosHormigaAnalysis(BuildContext context, AppState appState, DateTime selectedDate, bool isAnnualView) {
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

    // Calcular totales y sugerencias por categoría
    final List<Map<String, dynamic>> categoryAnalysis = [];
    transactionsByCategory.forEach((category, transactions) {
      final total = transactions.fold<double>(0, (sum, t) => sum + t.amount);
      final count = transactions.length;
      final average = total / count;

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
                      'Total gastos hormiga: ${NumberFormatter.formatCurrency(filteredTransactions.where((t) => t.type == AntTransactionType.expense).fold<double>(0, (sum, t) => sum + t.amount))}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
                              '${analysis['count']} transacciones • Promedio: ${NumberFormatter.formatCurrency(analysis['average'] as double)}',
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

class _BalanceCard extends StatelessWidget {
  final DateTime selectedDate;
  final bool isAnnualView;

  const _BalanceCard({
    required this.selectedDate,
    required this.isAnnualView,
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

        final filteredAntTransactions = appState.antTransactions.where((t) {
          if (isAnnualView) {
            return t.date.year == selectedDate.year;
          } else {
            return t.date.year == selectedDate.year && 
                   t.date.month == selectedDate.month;
          }
        }).toList();

        // Calcular totales de transacciones fijas
        final totalFixedIncome = filteredFixedTransactions
            .where((t) => t.type == FixedTransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);

        final totalFixedExpenses = filteredFixedTransactions
            .where((t) => t.type == FixedTransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

        // Calcular totales de transacciones hormiga
        final totalAntIncome = filteredAntTransactions
            .where((t) => t.type == AntTransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);

        final totalAntExpenses = filteredAntTransactions
            .where((t) => t.type == AntTransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);

        // Calcular totales generales
        final totalIncome = totalFixedIncome + totalAntIncome;
        final totalExpenses = totalFixedExpenses + totalAntExpenses;
        final balance = totalIncome - totalExpenses;

        // Calcular promedios para vista anual
        final monthlyIncome = isAnnualView ? totalIncome / 12 : totalIncome;
        final monthlyExpenses = isAnnualView ? totalExpenses / 12 : totalExpenses;
        final monthlyBalance = isAnnualView ? balance / 12 : balance;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAnnualView ? 'Balance Anual' : 'Balance Mensual',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (isAnnualView)
                      Text(
                        'Promedio mensual',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Balance general
                Center(
                  child: Column(
                    children: [
                      Text(
                        NumberFormatter.formatCurrency(balance),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: balance >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAnnualView ? 'Balance Anual' : 'Balance Mensual',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (isAnnualView) ...[
                        const SizedBox(height: 8),
                        Text(
                          NumberFormatter.formatCurrency(monthlyBalance),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: monthlyBalance >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        Text(
                          'Promedio mensual',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                // Desglose de ingresos y gastos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BalanceItem(
                      title: isAnnualView ? 'Ingresos Anuales' : 'Ingresos Totales',
                      amount: NumberFormatter.formatCurrency(totalIncome),
                      icon: Icons.arrow_upward,
                      color: Colors.green,
                      subtitle: [
                        'Fijos: ${NumberFormatter.formatCurrency(totalFixedIncome)}',
                        'Hormiga: ${NumberFormatter.formatCurrency(totalAntIncome)}',
                        if (isAnnualView)
                          'Promedio mensual: ${NumberFormatter.formatCurrency(monthlyIncome)}',
                      ],
                    ),
                    _BalanceItem(
                      title: isAnnualView ? 'Gastos Anuales' : 'Gastos Totales',
                      amount: NumberFormatter.formatCurrency(totalExpenses),
                      icon: Icons.arrow_downward,
                      color: Colors.red,
                      subtitle: [
                        'Fijos: ${NumberFormatter.formatCurrency(totalFixedExpenses)}',
                        'Hormiga: ${NumberFormatter.formatCurrency(totalAntExpenses)}',
                        if (isAnnualView)
                          'Promedio mensual: ${NumberFormatter.formatCurrency(monthlyExpenses)}',
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final DateTime selectedDate;
  final bool isAnnualView;
  final Function(BuildContext, AppState, DateTime, bool) onShowGastosHormigaAnalysis;

  // Constantes para las categorías de presupuesto
  static const Map<String, List<String>> _budgetCategories = {
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
    ],
    'Ahorro e Inversión (20%)': [
      'Fondo de emergencia',
      'Ahorro a largo plazo',
      'Inversiones',
      'Deudas',
    ],
  };

  const _StatisticsCard({
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
        final totalFixedIncome = filteredFixedTransactions
            .where((t) => t.type == FixedTransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);

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

        return _BaseCard(
          title: 'Estadísticas',
          children: [
            // Día con más gastos - Versión simplificada
            _ExpandableStatisticItem(
              title: isAnnualView ? 'Gastos por Mes' : 'Gastos por Día',
              value: isAnnualView ? 'Año ${selectedDate.year}' : 'Mes actual',
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
                            : 'Resumen de ${_Utils.getMonthName(selectedDate.month)} ${selectedDate.year}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (isAnnualView) ...[
                          // Mostrar gastos por mes para vista anual
                          ...List.generate(12, (index) {
                            final monthDate = DateTime(selectedDate.year, index + 1);
                            final monthStats = _calculateDailyStats(
                              appState.antTransactions,
                              monthDate,
                              false
                            );
                            return _StatisticItem(
                              title: _Utils.getMonthName(index + 1),
                              value: '${monthStats['count'] ?? 0} transacciones',
                              amount: NumberFormatter.formatCurrency(monthStats['total'] ?? 0),
                              icon: Icons.calendar_month,
                            );
                          }),
                        ] else ...[
                          // Mostrar gastos por día para vista mensual
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
                              ? '${stats['maxDate']!.day} de ${_Utils.getMonthName(stats['maxDate']!.month)}'
                              : 'Sin datos',
                            amount: NumberFormatter.formatCurrency(stats['maxAmount'] ?? 0),
                            icon: Icons.arrow_upward,
                          ),
                          const SizedBox(height: 8),
                          _StatisticItem(
                            title: 'Día con menos gastos',
                            value: stats['minDate'] != null 
                              ? '${stats['minDate']!.day} de ${_Utils.getMonthName(stats['minDate']!.month)}'
                              : 'Sin datos',
                            amount: NumberFormatter.formatCurrency(stats['minAmount'] ?? 0),
                            icon: Icons.arrow_downward,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isAnnualView
                              ? 'Consejo: Revisa los meses con gastos más altos y busca patrones que puedas optimizar.'
                              : 'Consejo: Mantén un registro diario de tus gastos para identificar días con gastos excesivos.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Regla 50/30/20
            _AhorroPotencialItem(
              amount: NumberFormatter.formatCurrency(totalFixedIncome),
              onTap: () {
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
                          _BudgetCategoryItem(
                            title: '50% Necesidades Básicas',
                            color: Colors.blue,
                            items: _budgetCategories['Necesidades Básicas (50%)']!,
                            currentAmount: NumberFormatter.formatCurrency(necesidadesBasicas),
                            recommendedAmount: NumberFormatter.formatCurrency(necesidadesBasicasRecomendado),
                            onInfoTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => _BaseDialog(
                                  title: 'Necesidades Básicas (50%)',
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Esta categoría incluye los gastos esenciales para tu vida diaria:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 16),
                                      _CategoryLegendItem(
                                        icon: Icons.home,
                                        name: 'Vivienda',
                                        description: 'Arriendo, administracion, hipoteca, servicios publicos, internet fijo y mantenimiento',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.restaurant,
                                        name: 'Alimentación',
                                        description: 'Compras de supermercado y comidas esenciales',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.water_drop,
                                        name: 'Servicios básicos',
                                        description: 'Agua, electricidad, gas, internet y telefonía básica',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.directions_bus,
                                        name: 'Transporte',
                                        description: 'Gasolina, transporte público y mantenimiento del vehículo',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.medical_services,
                                        name: 'Salud',
                                        description: 'Medicina prepagada, medicamentos, consultas, exámenes, odontología',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.person,
                                        name: 'Hijos',
                                        description: 'Educación, cuidado, vestimenta, alimentación',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.personal_injury,
                                        name: 'Padres',
                                        description: 'Cuidado, vestimenta, alimentación, regalos',
                                      ),
                                      _CategoryLegendItem(
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
                                          'Consejo: Prioriza estos gastos ya que son esenciales para tu bienestar diario. '
                                          'Busca formas de optimizarlos sin comprometer tu calidad de vida.',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _BudgetCategoryItem(
                            title: '30% Gastos Personales',
                            color: Colors.orange,
                            items: _budgetCategories['Gastos Personales (30%)']!,
                            currentAmount: NumberFormatter.formatCurrency(gastosPersonales),
                            recommendedAmount: NumberFormatter.formatCurrency(gastosPersonalesRecomendado),
                            onInfoTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => _BaseDialog(
                                  title: 'Gastos Personales (30%)',
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Esta categoría incluye gastos que mejoran tu calidad de vida:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 16),
                                      _CategoryLegendItem(
                                        icon: Icons.movie,
                                        name: 'Entretenimiento',
                                        description: 'Cine, streaming, eventos y actividades recreativas',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.shopping_bag,
                                        name: 'Compras',
                                        description: 'Ropa, tecnología, artículos personales y otros bienes',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.subscriptions,
                                        name: 'Suscripciones',
                                        description: 'Servicios premium, membresías y suscripciones digitales',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.credit_card,
                                        name: 'Tarjeas de credito',
                                        description: 'Imprevistos, compras anticipadas, viajes',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.monetization_on,
                                        name: 'Creditos',
                                        description: 'Moto, carro, casa',
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Consejo: Estos gastos son importantes para tu bienestar emocional, '
                                          'pero mantén un balance. Prioriza lo que realmente te hace feliz.',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _BudgetCategoryItem(
                            title: '20% Ahorro e Inversión',
                            color: Colors.green,
                            items: _budgetCategories['Ahorro e Inversión (20%)']!,
                            currentAmount: NumberFormatter.formatCurrency(ahorroInversion),
                            recommendedAmount: NumberFormatter.formatCurrency(ahorroInversionRecomendado),
                            onInfoTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => _BaseDialog(
                                  title: 'Ahorro e Inversión (20%)',
                                  content: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'Esta categoría es crucial para tu seguridad financiera futura:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 16),
                                      _CategoryLegendItem(
                                        icon: Icons.savings,
                                        name: 'Fondo de emergencia',
                                        description: 'Ahorro para imprevistos (3-6 meses de gastos)',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.trending_up,
                                        name: 'Ahorro a largo plazo',
                                        description: 'Metas financieras futuras y jubilación',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.account_balance,
                                        name: 'Inversiones',
                                        description: 'Inversiones en bolsa, fondos o bienes raíces',
                                      ),
                                      _CategoryLegendItem(
                                        icon: Icons.credit_card,
                                        name: 'Deudas',
                                        description: 'Pago de deudas de alto interés',
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Consejo: Esta categoría es fundamental para tu futuro financiero. '
                                          'Mantén la disciplina de ahorrar regularmente, incluso en meses difíciles.'
                                          'Esta funcionalidad esta en desarrollo, por lo que no es 100% precisa.',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
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
              },
            ),
            const SizedBox(height: 12),
            // Análisis de Gastos Hormiga
            _GastosHormigaItem(
              amount: NumberFormatter.formatCurrency(_calculateTotalPotentialSaving(appState, selectedDate, isAnnualView)),
              onTap: () => onShowGastosHormigaAnalysis(context, appState, selectedDate, isAnnualView),
            ),
          ],
        );
      },
    );
  }

  double _calculateTotalPotentialSaving(AppState appState, DateTime selectedDate, bool isAnnualView) {
    // Filtrar transacciones según la vista seleccionada
    final filteredTransactions = appState.antTransactions.where((t) {
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
      double savingPercentage = 0.15; // default

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
          savingPercentage = 0.15; // default para otras categorías
      }

      totalPotentialSaving += total * savingPercentage;
    });

    return totalPotentialSaving;
  }

  String _calculateDailyAverage(List<AntTransaction> transactions, DateTime selectedDate, bool isAnnualView) {
    // Filtrar transacciones según la vista seleccionada
    final filteredTransactions = transactions.where((t) {
      if (isAnnualView) {
        return t.date.year == selectedDate.year;
      } else {
        return t.date.year == selectedDate.year && 
               t.date.month == selectedDate.month;
      }
    }).toList();

    if (filteredTransactions.isEmpty) return NumberFormatter.formatCurrency(0);

    // Calcular el total de gastos
    final totalExpenses = filteredTransactions
        .where((t) => t.type == AntTransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    // Calcular el promedio diario
    final daysInPeriod = isAnnualView ? 365 : DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final average = totalExpenses / daysInPeriod;
    return NumberFormatter.formatCurrency(average);
  }

  Map<String, dynamic> _calculateDailyStats(List<AntTransaction> transactions, DateTime selectedDate, bool isAnnualView) {
    // Filtrar transacciones según la vista seleccionada
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

    // Agrupar gastos por día
    final Map<DateTime, double> dailyExpenses = {};
    for (var transaction in filteredTransactions.where((t) => t.type == AntTransactionType.expense)) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyExpenses[date] = (dailyExpenses[date] ?? 0) + transaction.amount;
    }

    // Calcular estadísticas
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

    // Calcular el promedio diario
    final daysInPeriod = isAnnualView ? 365 : DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final average = totalExpenses / daysInPeriod;

    return {
      'average': average,
      'minAmount': minAmount,
      'minDate': minDate,
      'maxAmount': maxAmount,
      'maxDate': maxDate,
      'total': totalExpenses,
      'count': filteredTransactions.where((t) => t.type == AntTransactionType.expense).length,
    };
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

class _BudgetCategoryItem extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;
  final String currentAmount;
  final String recommendedAmount;
  final VoidCallback onInfoTap;

  const _BudgetCategoryItem({
    required this.title,
    required this.color,
    required this.items,
    required this.currentAmount,
    required this.recommendedAmount,
    required this.onInfoTap,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: color),
                onPressed: onInfoTap,
                tooltip: 'Información sobre ${title.split('%')[0]}',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 16,
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
                    Text(
                      item,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actual: $currentAmount',
                style: const TextStyle(fontSize: 11),
              ),
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

class _CategoryExpensesCard extends StatelessWidget {
  final DateTime selectedDate;
  final bool isAnnualView;

  const _CategoryExpensesCard({
    required this.selectedDate,
    required this.isAnnualView,
  });

  Color _getFixedColor(FixedCategory category) {
    // Usar directamente el color definido en la categoría
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

        return _BaseCard(
          title: 'Gastos por Categoría',
          children: [
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
                height: 280, // Aumentamos la altura para dar espacio a las etiquetas
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
                          titlePositionPercentageOffset: 1.35, // Más separado del sector
                          badgeWidget: null,
                        ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    startDegreeOffset: 270, // Inicia desde las 12 en punto
                    // PieChart de fl_chart es antihorario por defecto
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Opcional: manejar toques en el gráfico
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Leyenda sin porcentajes
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
        );
      },
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;
  final List<String> subtitle;

  const _BalanceItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.subtitle = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...subtitle.map((text) => Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )),
        ],
      ],
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

// Widget común para elementos de lista
class _ListItem extends StatelessWidget {
  final String leading;
  final String title;
  final String trailing;
  final Color? trailingColor;
  final IconData? categoryIcon;
  final Color? categoryColor;

  const _ListItem({
    required this.leading,
    required this.title,
    required this.trailing,
    this.trailingColor,
    this.categoryIcon,
    this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: categoryIcon != null 
        ? Icon(
            categoryIcon,
            color: categoryColor,
            size: 24,
          )
        : null,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
          height: 1.2,
        ),
      ),
      subtitle: Text(
        leading,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
      trailing: Text(
        trailing,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: trailingColor ?? Theme.of(context).colorScheme.primary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      dense: true,
    );
  }
}

// Widget para elementos de la leyenda
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
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