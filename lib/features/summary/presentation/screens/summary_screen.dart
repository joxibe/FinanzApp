import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/presentation/widgets/shared_widgets.dart';
import 'package:finanz_app/core/presentation/widgets/export_dialog.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/core/utils/export_service.dart';
import 'package:finanz_app/features/balance/domain/models/ant_transaction.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_transaction.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  int? _selectedYear;
  final Map<DateTime, bool> _expandedMonths = {};
  bool _isExpanded = false;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

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

    // Asegurarse de que el año actual siempre esté disponible
    years.add(currentYear);

    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  List<DateTime> _getMonthsWithData(AppState appState, int year) {
    final Set<DateTime> months = {};
    final now = DateTime.now();
    
    // Agregar meses de transacciones fijas
    for (var transaction in appState.fixedTransactions) {
      if (transaction.date.year == year) {
        months.add(DateTime(year, transaction.date.month));
      }
    }

    // Agregar meses de transacciones hormiga
    for (var transaction in appState.antTransactions) {
      if (transaction.date.year == year) {
        months.add(DateTime(year, transaction.date.month));
      }
    }

    // Si es el año actual, agregar el mes actual si no hay datos
    if (year == now.year && months.isEmpty) {
      months.add(DateTime(year, now.month));
    }

    return months.toList()..sort((a, b) => b.compareTo(a));
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[date.month - 1];
  }

  List<DateTime> _getLastMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (index) {
      final date = DateTime(now.year, now.month - index);
      return DateTime(date.year, date.month);
    });
  }

  Map<String, dynamic> _calculateMonthSummary(
    DateTime month,
    List<AntTransaction> antTransactions,
    List<FixedTransaction> fixedTransactions,
  ) {
    // Filtrar una sola vez con un solo recorrido para mejor rendimiento
    final monthAntTransactions = <AntTransaction>[];
    double totalAntIncome = 0.0;
    double totalAntExpenses = 0.0;
    
    for (final transaction in antTransactions) {
      if (transaction.date.year == month.year && transaction.date.month == month.month) {
        monthAntTransactions.add(transaction);
        if (transaction.type == AntTransactionType.income) {
          totalAntIncome += transaction.amount;
        } else {
          totalAntExpenses += transaction.amount;
        }
      }
    }

    // Hacer lo mismo con las transacciones fijas
    final monthFixedTransactions = <FixedTransaction>[];
    final fixedIncomeTransactions = <FixedTransaction>[];
    final fixedExpenseTransactions = <FixedTransaction>[];
    double totalFixedIncome = 0.0;
    double totalFixedExpenses = 0.0;
    
    for (final transaction in fixedTransactions) {
      if (transaction.date.year == month.year && transaction.date.month == month.month) {
        monthFixedTransactions.add(transaction);
        if (transaction.type == FixedTransactionType.income) {
          fixedIncomeTransactions.add(transaction);
          totalFixedIncome += transaction.amount;
        } else {
          fixedExpenseTransactions.add(transaction);
          totalFixedExpenses += transaction.amount;
        }
      }
    }

    // Calcular totales finales
    final totalIncome = totalAntIncome + totalFixedIncome;
    final totalExpenses = totalAntExpenses + totalFixedExpenses;
    
    return {
      'antTransactions': monthAntTransactions,
      'fixedTransactions': monthFixedTransactions,
      'fixedIncomeTransactions': fixedIncomeTransactions,
      'fixedExpenseTransactions': fixedExpenseTransactions,
      'totalAntIncome': totalAntIncome,
      'totalAntExpenses': totalAntExpenses,
      'totalFixedIncome': totalFixedIncome,
      'totalFixedExpenses': totalFixedExpenses,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'balance': totalIncome - totalExpenses,
    };
  }

  Widget _buildMonthCard(
    BuildContext context,
    DateTime month,
    Map<String, dynamic> summary,
    bool isCurrentMonth,
  ) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            final isDark = appState.isDarkMode;
            final cardColor = isDark 
              ? const Color(0xFF1E1E1E)  // Gris muy oscuro para modo oscuro
              : Colors.white;
            final currentMonthColor = isDark
              ? const Color(0xFF2B6CB0).withOpacity(0.15)  // Azul más suave para modo oscuro
              : const Color(0xFFF0F7FF);  // Azul muy suave para modo claro
            final textColor = isDark
              ? Colors.white.withOpacity(0.9)
              : const Color(0xFF2D3748);  // Gris más oscuro para mejor contraste
            final accentColor = isDark
              ? const Color(0xFF63B3ED)  // Azul más claro para modo oscuro
              : const Color(0xFF3182CE);  // Azul más suave para modo claro

            // Colores para los diferentes tipos de transacciones
            final fixedColor = isDark
              ? const Color(0xFF63B3ED)  // Azul más claro para modo oscuro
              : const Color(0xFF3182CE);  // Azul más suave para modo claro
            final antColor = isDark
              ? const Color(0xFFB794F4)  // Púrpura más claro para modo oscuro
              : const Color(0xFF805AD5);  // Púrpura más suave para modo claro
            final incomeColor = isDark
              ? const Color(0xFF68D391)  // Verde más claro para modo oscuro
              : const Color(0xFF48BB78);  // Verde más suave para modo claro
            final expenseColor = isDark
              ? const Color(0xFFFC8181)  // Rojo más claro para modo oscuro
              : const Color(0xFFED8936);  // Naranja más suave para modo claro

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark 
                    ? Colors.white.withOpacity(0.1)
                    : const Color(0xFFE2E8F0).withOpacity(0.5),
                  width: 1,
                ),
              ),
              color: isCurrentMonth ? currentMonthColor : cardColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado del mes
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedMonths[month] = !(_expandedMonths[month] ?? false);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  '${_getMonthName(month)} ${month.year}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isCurrentMonth)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Mes Actual',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expandedMonths[month] == true
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: accentColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Resumen del mes
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Balance General
                        Card(
                          elevation: 0,
                          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isDark 
                                ? Colors.white.withOpacity(0.1)
                                : const Color(0xFFE2E8F0).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Balance General',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryItem(
                                        context,
                                        'Ingresos',
                                        summary['totalIncome'],
                                        incomeColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        context,
                                        'Gastos',
                                        summary['totalExpenses'],
                                        expenseColor,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        context,
                                        'Balance',
                                        summary['balance'],
                                        summary['balance'] >= 0 
                                          ? incomeColor
                                          : expenseColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Gastos Fijos y Hormiga
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(right: 3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isDark 
                                      ? Colors.white.withOpacity(0.1)
                                      : const Color(0xFFE2E8F0).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_month,
                                            size: 14,
                                            color: fixedColor,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Gastos Fijos',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: fixedColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        NumberFormatter.formatCurrency(summary['totalFixedExpenses']),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: expenseColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(left: 3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isDark 
                                      ? Colors.white.withOpacity(0.1)
                                      : const Color(0xFFE2E8F0).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.savings,
                                            size: 14,
                                            color: antColor,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'GastosHormiga',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: antColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        NumberFormatter.formatCurrency(summary['totalAntExpenses']),
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: antColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Detalles de transacciones
                  if (_expandedMonths[month] == true)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: _buildTransactionDetails(
                        context,
                        summary['antTransactions'],
                        summary['fixedTransactions'],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormatter.formatCurrency(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionDetails(
    BuildContext context,
    List<AntTransaction> antTransactions,
    List<FixedTransaction> fixedTransactions,
  ) {
    if (antTransactions.isEmpty && fixedTransactions.isEmpty) {
      return const Center(
        child: Text(
          'No hay movimientos en este mes',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Color(0xFF718096),
          ),
        ),
      );
    }

    // Separar transacciones hormiga por tipo
    final antIncomeTransactions = antTransactions
        .where((t) => t.type == AntTransactionType.income)
        .toList();
    final antExpenseTransactions = antTransactions
        .where((t) => t.type == AntTransactionType.expense)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fixedTransactions.isNotEmpty) ...[
          // Gastos Fijos
          if (fixedTransactions.any((t) => t.type == FixedTransactionType.expense)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: const Color(0xFF2B6CB0),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Gastos Fijos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2B6CB0),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                  width: 1,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fixedTransactions.where((t) => t.type == FixedTransactionType.expense).length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                ),
                itemBuilder: (context, index) {
                  final transaction = fixedTransactions
                      .where((t) => t.type == FixedTransactionType.expense)
                      .elementAt(index);
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: transaction.category.color.withOpacity(0.1),
                      child: Icon(
                        transaction.category.icon,
                        color: transaction.category.color,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                    subtitle: Text(
                      'Día ${transaction.date.day} de cada mes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF718096),
                      ),
                    ),
                    trailing: Text(
                      NumberFormatter.formatCurrency(transaction.amount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFF56565),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          // Ingresos Fijos
          if (fixedTransactions.any((t) => t.type == FixedTransactionType.income)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 18,
                    color: const Color(0xFF48BB78),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ingresos Fijos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF48BB78),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                  width: 1,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fixedTransactions.where((t) => t.type == FixedTransactionType.income).length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                ),
                itemBuilder: (context, index) {
                  final transaction = fixedTransactions
                      .where((t) => t.type == FixedTransactionType.income)
                      .elementAt(index);
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: transaction.category.color.withOpacity(0.1),
                      child: Icon(
                        transaction.category.icon,
                        color: transaction.category.color,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                    subtitle: Text(
                      'Día ${transaction.date.day} de cada mes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF718096),
                      ),
                    ),
                    trailing: Text(
                      NumberFormatter.formatCurrency(transaction.amount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF48BB78),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
        if (antTransactions.isNotEmpty) ...[
          // Gastos Hormiga
          if (antExpenseTransactions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Icon(
                    Icons.savings,
                    size: 18,
                    color: const Color(0xFF805AD5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Gastos Hormiga',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF805AD5),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                  width: 1,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: antExpenseTransactions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                ),
                itemBuilder: (context, index) {
                  final transaction = antExpenseTransactions[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: transaction.category.color.withOpacity(0.1),
                      child: Icon(
                        transaction.category.icon,
                        color: transaction.category.color,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                    subtitle: Text(
                      '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF718096),
                      ),
                    ),
                    trailing: Text(
                      NumberFormatter.formatCurrency(transaction.amount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFF56565),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          // Ingresos Hormiga
          if (antIncomeTransactions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 18,
                    color: const Color(0xFF48BB78),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ingresos Hormiga',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF48BB78),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                  width: 1,
                ),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: antIncomeTransactions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: const Color(0xFFE2E8F0).withOpacity(0.5),
                ),
                itemBuilder: (context, index) {
                  final transaction = antIncomeTransactions[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: transaction.category.color.withOpacity(0.1),
                      child: Icon(
                        transaction.category.icon,
                        color: transaction.category.color,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                    subtitle: Text(
                      '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF718096),
                      ),
                    ),
                    trailing: Text(
                      NumberFormatter.formatCurrency(transaction.amount),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF48BB78),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildMonthlySummary(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlySummary(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final months = _getMonthsWithData(appState, _selectedYear ?? DateTime.now().year);
        
        if (months.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child: Text(
                  'No hay datos para el año ${_selectedYear ?? DateTime.now().year}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: months.map((month) {
            final summary = _calculateMonthSummary(
              month,
              appState.antTransactions,
              appState.fixedTransactions,
            );
            
            final now = DateTime.now();
            final isCurrentMonth = month.year == now.year && month.month == now.month;

            return _buildMonthCard(
              context,
              month,
              summary,
              isCurrentMonth,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final availableYears = _getAvailableYears(appState);
        final currentYear = DateTime.now().year;
        
        // Si no hay año seleccionado o el año seleccionado es mayor al actual,
        // usar el año actual
        if (_selectedYear == null || _selectedYear! > currentYear) {
          _selectedYear = currentYear;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
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
                              final isCurrentYear = year == currentYear;
                              final isSelected = year == _selectedYear;
                              
                              return ListTile(
                                title: Text(
                                  year.toString(),
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : null,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                subtitle: isCurrentYear 
                                  ? const Text('Año actual')
                                  : null,
                                trailing: isSelected 
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                                onTap: () {
                                  if (year <= currentYear) {
                                    setState(() {
                                      _selectedYear = year;
                                    });
                                    Navigator.pop(context);
                                  }
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
                  },
                  icon: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    _selectedYear.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: _selectedYear == currentYear
                        ? FontWeight.bold
                        : null,
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
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _MonthlyData {
  final DateTime date;
  final double income;
  final double expenses;

  _MonthlyData({
    required this.date,
    required this.income,
    required this.expenses,
  });
} 