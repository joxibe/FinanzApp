import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/presentation/widgets/shared_widgets.dart';
import 'package:finanz_app/features/balance/domain/models/ant_transaction.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_transaction.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import '../widgets/new_transaction_form.dart';
import '../widgets/edit_transaction_form.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  bool _showForm = false;
  AntTransactionType? _selectedTransactionType;

  void _toggleForm(AntTransactionType? type) {
    setState(() {
      if (_selectedTransactionType == type) {
        _showForm = false;
        _selectedTransactionType = null;
      } else {
        _showForm = true;
        _selectedTransactionType = type;
      }
    });
  }

  void _showEditTransactionForm(BuildContext context, AntTransaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Editar Transacción'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: EditTransactionForm(
                transaction: transaction,
                onSave: (updatedTransaction) {
                  try {
                    context.read<AppState>().updateAntTransaction(updatedTransaction);
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transacción actualizada con éxito'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al actualizar: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, AntTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Transacción'),
        content: const Text('¿Estás seguro de que deseas eliminar esta transacción? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AppState>().deleteAntTransaction(transaction);
    }
  }

  List<AntTransaction> _sortTransactions(List<AntTransaction> transactions, AppState appState) {
    final sortedList = List<AntTransaction>.from(transactions);
    
    sortedList.sort((a, b) {
      int comparison;
      
      switch (appState.balanceSortType) {
        case SortType.amount:
          comparison = a.amount.compareTo(b.amount);
          break;
        case SortType.date:
          comparison = a.date.compareTo(b.date);
          break;
      }
      
      return appState.balanceSortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    
    return sortedList;
  }

  Widget _buildFilterButton(AppState appState) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      tooltip: 'Filtros',
      onSelected: (value) async {
        final type = value.startsWith('amount') ? SortType.amount : SortType.date;
        final order = value.endsWith('asc') ? SortOrder.ascending : SortOrder.descending;
        await appState.updateBalanceSort(type, order);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'amount_asc',
          child: Row(
            children: [
              const Icon(Icons.trending_up),
              const SizedBox(width: 8),
              const Text('Monto: Menor a Mayor'),
              if (appState.balanceSortType == SortType.amount && appState.balanceSortOrder == SortOrder.ascending)
                const Spacer(),
              if (appState.balanceSortType == SortType.amount && appState.balanceSortOrder == SortOrder.ascending)
                const Icon(Icons.check, color: Colors.green),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'amount_desc',
          child: Row(
            children: [
              const Icon(Icons.trending_down),
              const SizedBox(width: 8),
              const Text('Monto: Mayor a Menor'),
              if (appState.balanceSortType == SortType.amount && appState.balanceSortOrder == SortOrder.descending)
                const Spacer(),
              if (appState.balanceSortType == SortType.amount && appState.balanceSortOrder == SortOrder.descending)
                const Icon(Icons.check, color: Colors.green),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'date_asc',
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 8),
              const Text('Fecha: Más Antigua'),
              if (appState.balanceSortType == SortType.date && appState.balanceSortOrder == SortOrder.ascending)
                const Spacer(),
              if (appState.balanceSortType == SortType.date && appState.balanceSortOrder == SortOrder.ascending)
                const Icon(Icons.check, color: Colors.green),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'date_desc',
          child: Row(
            children: [
              const Icon(Icons.calendar_today),
              const SizedBox(width: 8),
              const Text('Fecha: Más Reciente'),
              if (appState.balanceSortType == SortType.date && appState.balanceSortOrder == SortOrder.descending)
                const Spacer(),
              if (appState.balanceSortType == SortType.date && appState.balanceSortOrder == SortOrder.descending)
                const Icon(Icons.check, color: Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        _buildFilterButton(appState),
      ],
    );
  }

  Widget _buildTransactionsList(List<AntTransaction> transactions, AppState appState) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Text(
              'No hay transacciones registradas',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final sortedTransactions = _sortTransactions(transactions, appState);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTransactions.length,
      itemBuilder: (context, index) {
        final transaction = sortedTransactions[index];
        return TransactionItem(
          transaction: transaction,
          onEdit: () => _showEditTransactionForm(context, transaction),
          onDelete: () => _showDeleteConfirmation(context, transaction),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month);
          
          // Filtrar transacciones del mes actual
          final fixedTransactions = appState.fixedTransactions.where((t) =>
            t.date.year == currentMonth.year && 
            t.date.month == currentMonth.month
          ).toList();
          
          final antTransactions = appState.antTransactions.where((t) =>
            t.date.year == currentMonth.year && 
            t.date.month == currentMonth.month
          ).toList();
          
          // Separar transacciones por tipo
          final incomeTransactions = antTransactions
              .where((t) => t.type == AntTransactionType.income)
              .toList();
          
          final expenseTransactions = antTransactions
              .where((t) => t.type == AntTransactionType.expense)
              .toList();
          
          // Calcular balances
          final initialBalance = fixedTransactions
              .where((t) => t.type == FixedTransactionType.income)
              .fold(0.0, (sum, t) => sum + t.amount)
            - fixedTransactions
              .where((t) => t.type == FixedTransactionType.expense)
              .fold(0.0, (sum, t) => sum + t.amount);
          
          final totalAntIncome = incomeTransactions
              .fold(0.0, (sum, t) => sum + t.amount);
          final totalAntExpenses = expenseTransactions
              .fold(0.0, (sum, t) => sum + t.amount);
          final currentBalance = initialBalance + totalAntIncome - totalAntExpenses;

          return Stack(
            children: [
              AnimatedPadding(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Resumen de balance
                        BalanceSummaryCard(
                          currentBalance: currentBalance,
                          initialBalance: initialBalance,
                          totalIncome: totalAntIncome,
                          totalExpenses: totalAntExpenses,
                          incomeColor: const Color(0xFF48BB78),
                          expenseColor: const Color(0xFFED8936),
                          balanceColor: currentBalance >= 0 
                            ? const Color(0xFF48BB78)
                            : const Color(0xFFED8936),
                        ),
                        const SizedBox(height: 12),
                        
                        // Botones de tipo de transacción
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _toggleForm(AntTransactionType.income),
                                icon: Icon(
                                  Icons.arrow_upward,
                                  color: _selectedTransactionType == AntTransactionType.income
                                      ? const Color(0xFF48BB78)
                                      : null,
                                ),
                                label: Text(
                                  'Ingreso',
                                  style: TextStyle(
                                    color: _selectedTransactionType == AntTransactionType.income
                                        ? const Color(0xFF48BB78)
                                        : null,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                    color: _selectedTransactionType == AntTransactionType.income
                                        ? const Color(0xFF48BB78)
                                        : Theme.of(context).colorScheme.outline,
                                  ),
                                  backgroundColor: _selectedTransactionType == AntTransactionType.income
                                      ? const Color(0xFF48BB78).withOpacity(0.1)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _toggleForm(AntTransactionType.expense),
                                icon: Icon(
                                  Icons.arrow_downward,
                                  color: _selectedTransactionType == AntTransactionType.expense
                                      ? const Color(0xFFED8936)
                                      : null,
                                ),
                                label: Text(
                                  'Gasto',
                                  style: TextStyle(
                                    color: _selectedTransactionType == AntTransactionType.expense
                                        ? const Color(0xFFED8936)
                                        : null,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                    color: _selectedTransactionType == AntTransactionType.expense
                                        ? const Color(0xFFED8936)
                                        : Theme.of(context).colorScheme.outline,
                                  ),
                                  backgroundColor: _selectedTransactionType == AntTransactionType.expense
                                      ? const Color(0xFFED8936).withOpacity(0.1)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Formulario de nueva transacción
                        if (_showForm) ...[
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: NewTransactionForm(
                                initialType: _selectedTransactionType,
                                onSave: (transaction) {
                                  if (transaction.id.isNotEmpty) {
                                    Provider.of<AppState>(context, listen: false)
                                        .addAntTransaction(transaction);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Transacción guardada con éxito'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    _toggleForm(null);
                                  }
                                },
                                onCancel: () => _toggleForm(null),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        
                        // Sección de Ingresos Hormiga
                        _buildSectionHeader('Ingresos Hormiga', appState),
                        const SizedBox(height: 8),
                        _buildTransactionsList(incomeTransactions, appState),
                        
                        const SizedBox(height: 16),
                        
                        // Sección de Gastos Hormiga
                        _buildSectionHeader('Gastos Hormiga', appState),
                        const SizedBox(height: 8),
                        _buildTransactionsList(expenseTransactions, appState),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _BalanceItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
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
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final AntTransaction transaction;

  const _TransactionItem({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == AntTransactionType.expense;
    final color = isExpense 
      ? const Color(0xFFED8936)
      : const Color(0xFF48BB78);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: transaction.category.color.withOpacity(0.2),
          child: Icon(
            transaction.category.icon,
            color: transaction.category.color,
            size: 16,
          ),
        ),
        title: Text(
          transaction.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} - ${transaction.category.name}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          NumberFormatter.formatCurrency(transaction.amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}