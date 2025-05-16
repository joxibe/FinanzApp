import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/core/presentation/widgets/shared_widgets.dart';
import '../../domain/models/fixed_category.dart';
import '../../domain/models/fixed_transaction.dart';
import '../widgets/new_fixed_transaction_form.dart';
import '../widgets/edit_fixed_transaction_form.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _showForm = false;
  FixedTransactionType? _selectedTransactionType;

  void _toggleForm(FixedTransactionType? type) {
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

  void _showEditFixedTransactionForm(BuildContext context, FixedTransaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Editar Transacción Fija'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: EditFixedTransactionForm(
                transaction: transaction,
                onSave: (updatedTransaction) {
                  context.read<AppState>().updateFixedTransaction(updatedTransaction);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transacción fija actualizada con éxito'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, FixedTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Transacción Fija'),
        content: const Text('¿Estás seguro de que deseas eliminar esta transacción fija? Esta acción no se puede deshacer.'),
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
      context.read<AppState>().deleteFixedTransaction(transaction);
    }
  }

  String _getMonthName() {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[DateTime.now().month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final now = DateTime.now();
          final currentMonth = DateTime(now.year, now.month);
          
          // Filtrar transacciones fijas del mes actual
          final fixedTransactions = appState.fixedTransactions.where((t) =>
            t.date.year == currentMonth.year && 
            t.date.month == currentMonth.month
          ).toList();
          
          final totalFixedIncome = fixedTransactions
              .where((t) => t.type == FixedTransactionType.income)
              .fold(0.0, (sum, t) => sum + t.amount);

          final totalFixedExpenses = fixedTransactions
              .where((t) => t.type == FixedTransactionType.expense)
              .fold(0.0, (sum, t) => sum + t.amount);

          final balance = totalFixedIncome - totalFixedExpenses;

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Presupuesto Mensual',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      NumberFormatter.formatCurrency(balance),
                                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: balance >= 0 
                                              ? const Color(0xFF48BB78)
                                              : const Color(0xFFED8936),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Saldo disponible para gastos hormiga',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _BudgetItem(
                                    title: 'Ingresos Fijos',
                                    amount: NumberFormatter.formatCurrency(totalFixedIncome),
                                    icon: Icons.arrow_upward,
                                    color: const Color(0xFF48BB78),
                                  ),
                                  _BudgetItem(
                                    title: 'Gastos Fijos',
                                    amount: NumberFormatter.formatCurrency(totalFixedExpenses),
                                    icon: Icons.arrow_downward,
                                    color: const Color(0xFFED8936),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _toggleForm(FixedTransactionType.income),
                              icon: Icon(
                                Icons.arrow_upward,
                                color: _selectedTransactionType == FixedTransactionType.income
                                    ? const Color(0xFF48BB78)
                                    : null,
                              ),
                              label: Text(
                                'Ingreso',
                                style: TextStyle(
                                  color: _selectedTransactionType == FixedTransactionType.income
                                      ? const Color(0xFF48BB78)
                                      : null,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: _selectedTransactionType == FixedTransactionType.income
                                      ? const Color(0xFF48BB78)
                                      : Theme.of(context).colorScheme.outline,
                                ),
                                backgroundColor: _selectedTransactionType == FixedTransactionType.income
                                    ? const Color(0xFF48BB78).withOpacity(0.1)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _toggleForm(FixedTransactionType.expense),
                              icon: Icon(
                                Icons.arrow_downward,
                                color: _selectedTransactionType == FixedTransactionType.expense
                                    ? const Color(0xFFED8936)
                                    : null,
                              ),
                              label: Text(
                                'Gasto',
                                style: TextStyle(
                                  color: _selectedTransactionType == FixedTransactionType.expense
                                      ? const Color(0xFFED8936)
                                      : null,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: _selectedTransactionType == FixedTransactionType.expense
                                      ? const Color(0xFFED8936)
                                      : Theme.of(context).colorScheme.outline,
                                ),
                                backgroundColor: _selectedTransactionType == FixedTransactionType.expense
                                    ? const Color(0xFFED8936).withOpacity(0.1)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showForm) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: NewFixedTransactionForm(
                              initialType: _selectedTransactionType,
                              onSave: (transaction) {
                                if (transaction.id.isNotEmpty) {
                                  Provider.of<AppState>(context, listen: false)
                                      .addFixedTransaction(transaction);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Transacción fija guardada con éxito'),
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
                      Text(
                        'Ingresos Fijos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (fixedTransactions.where((t) => t.type == FixedTransactionType.income).isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                              child: Text(
                                'No hay ingresos fijos registrados',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: fixedTransactions.where((t) => t.type == FixedTransactionType.income).length,
                          itemBuilder: (context, index) {
                            final incomeTransactions = fixedTransactions.where((t) => t.type == FixedTransactionType.income).toList();
                            final transaction = incomeTransactions[index];
                            return FixedTransactionItem(
                              transaction: transaction,
                              onEdit: () => _showEditFixedTransactionForm(context, transaction),
                              onDelete: () => _showDeleteConfirmation(context, transaction),
                            );
                          },
                        ),
                      const SizedBox(height: 16),

                      // Sección de gastos fijos
                      Text(
                        'Gastos Fijos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (fixedTransactions.where((t) => t.type == FixedTransactionType.expense).isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Center(
                              child: Text(
                                'No hay gastos fijos registrados',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: fixedTransactions.where((t) => t.type == FixedTransactionType.expense).length,
                          itemBuilder: (context, index) {
                            final expenseTransactions = fixedTransactions.where((t) => t.type == FixedTransactionType.expense).toList();
                            final transaction = expenseTransactions[index];
                            return FixedTransactionItem(
                              transaction: transaction,
                              onEdit: () => _showEditFixedTransactionForm(context, transaction),
                              onDelete: () => _showDeleteConfirmation(context, transaction),
                            );
                          },
                        ),
                    ],
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

class _BudgetItem extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _BudgetItem({
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
        const SizedBox(height: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 3),
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