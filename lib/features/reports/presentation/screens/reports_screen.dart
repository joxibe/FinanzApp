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
import 'package:finanz_app/features/reports/presentation/screens/reports_screen_stats.dart';
import 'package:finanz_app/features/reports/presentation/screens/reports_screen_categories.dart';

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
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          minWidth: 300,
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
            StatisticsCard(
              selectedDate: _selectedDate,
              isAnnualView: _isAnnualView,
              onShowGastosHormigaAnalysis: StatisticsCard.showGastosHormigaAnalysis,
            ),
            const SizedBox(height: 16),
            CategoryExpensesCard(
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