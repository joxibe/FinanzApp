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

class _BudgetScreenState extends State<BudgetScreen> with TickerProviderStateMixin {
  bool _showForm = false;
  FixedTransactionType? _selectedTransactionType;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleForm(FixedTransactionType? type) {
    setState(() {
      if (_selectedTransactionType == type) {
        _showForm = false;
        _selectedTransactionType = null;
        _animationController.reverse();
      } else {
        _showForm = true;
        _selectedTransactionType = type;
        _animationController.forward();
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
                onSave: (updatedTransaction) async {
                  await context.read<AppState>().updateFixedTransaction(updatedTransaction);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Transacción actualizada con éxito'),
                          ],
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            const Text('Eliminar Transacción'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta transacción fija? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AppState>().deleteFixedTransaction(transaction);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('Transacción eliminada'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  List<FixedTransaction> _sortTransactions(List<FixedTransaction> transactions, AppState appState) {
    final sortedList = List<FixedTransaction>.from(transactions);
    
    sortedList.sort((a, b) {
      int comparison;
      switch (appState.budgetSortType) {
        case SortType.amount:
          comparison = a.amount.compareTo(b.amount);
          break;
        case SortType.date:
          comparison = a.date.compareTo(b.date);
          break;
      }
      return appState.budgetSortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    
    return sortedList;
  }

  Widget _buildFilterButton(AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.tune,
          color: Theme.of(context).colorScheme.primary,
        ),
        tooltip: 'Filtros y ordenamiento',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: (value) async {
          final type = value.startsWith('amount') ? SortType.amount : SortType.date;
          final order = value.endsWith('asc') ? SortOrder.ascending : SortOrder.descending;
          await appState.updateBudgetSort(type, order);
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'amount_asc',
            child: _buildFilterOption(
              Icons.trending_up,
              'Monto: Menor a Mayor',
              appState.budgetSortType == SortType.amount && appState.budgetSortOrder == SortOrder.ascending,
            ),
          ),
          PopupMenuItem(
            value: 'amount_desc',
            child: _buildFilterOption(
              Icons.trending_down,
              'Monto: Mayor a Menor',
              appState.budgetSortType == SortType.amount && appState.budgetSortOrder == SortOrder.descending,
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'date_asc',
            child: _buildFilterOption(
              Icons.calendar_today,
              'Fecha: Más Antigua',
              appState.budgetSortType == SortType.date && appState.budgetSortOrder == SortOrder.ascending,
            ),
          ),
          PopupMenuItem(
            value: 'date_desc',
            child: _buildFilterOption(
              Icons.calendar_today,
              'Fecha: Más Reciente',
              appState.budgetSortType == SortType.date && appState.budgetSortOrder == SortOrder.descending,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(IconData icon, String text, bool isSelected) {
    return Row(
      children: [
        Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        if (isSelected)
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, AppState appState, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildFilterButton(appState),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<FixedTransaction> transactions, AppState appState) {
    final sortedTransactions = _sortTransactions(transactions, appState);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTransactions.length,
      itemBuilder: (context, index) {
        final transaction = sortedTransactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: FixedTransactionItem(
            transaction: transaction,
            onEdit: () => _showEditFixedTransactionForm(context, transaction),
            onDelete: () => _showDeleteConfirmation(context, transaction),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              FixedTransactionType.income,
              'Agregar Ingreso',
              Icons.add_circle_outline,
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              FixedTransactionType.expense,
              'Agregar Gasto',
              Icons.remove_circle_outline,
              Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    FixedTransactionType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedTransactionType == type;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: OutlinedButton.icon(
        onPressed: () => _toggleForm(type),
        style: OutlinedButton.styleFrom(
          foregroundColor: isSelected ? color : Theme.of(context).colorScheme.onSurface,
          side: BorderSide(
            color: isSelected ? color : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          icon,
          color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSummary(double totalFixedIncome, double totalFixedExpenses, double balance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Presupuesto Mensual',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Balance principal
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: balance >= 0 
                              ? const Color(0xFF48BB78).withOpacity(0.1)
                              : const Color(0xFFED8936).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: balance >= 0 
                                ? const Color(0xFF48BB78).withOpacity(0.3)
                                : const Color(0xFFED8936).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          NumberFormatter.formatCurrency(balance),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: balance >= 0 
                                  ? const Color(0xFF48BB78)
                                  : const Color(0xFFED8936),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Saldo disponible para gastos hormiga',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divider con estilo
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.outline.withOpacity(0.1),
                        Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        Theme.of(context).colorScheme.outline.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Resumen de ingresos y gastos
                Row(
                  children: [
                    Expanded(
                      child: _BudgetItem(
                        title: 'Ingresos Fijos',
                        amount: NumberFormatter.formatCurrency(totalFixedIncome),
                        icon: Icons.trending_up,
                        color: const Color(0xFF48BB78),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                    Expanded(
                      child: _BudgetItem(
                        title: 'Gastos Fijos',
                        amount: NumberFormatter.formatCurrency(totalFixedExpenses),
                        icon: Icons.trending_down,
                        color: const Color(0xFFED8936),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          
          final incomeTransactions = fixedTransactions
              .where((t) => t.type == FixedTransactionType.income)
              .toList();
          
          final expenseTransactions = fixedTransactions
              .where((t) => t.type == FixedTransactionType.expense)
              .toList();
          
          final totalFixedIncome = incomeTransactions
              .fold(0.0, (sum, t) => sum + t.amount);

          final totalFixedExpenses = expenseTransactions
              .fold(0.0, (sum, t) => sum + t.amount);

          final balance = totalFixedIncome - totalFixedExpenses;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumen del presupuesto
                  _buildBudgetSummary(totalFixedIncome, totalFixedExpenses, balance),
                  
                  // Botones de acción
                  _buildActionButtons(),
                  
                  // Formulario de nueva transacción con animación
                  if (_showForm) ...[
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.5),
                        end: Offset.zero,
                      ).animate(_slideAnimation),
                      child: FadeTransition(
                        opacity: _slideAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _selectedTransactionType == FixedTransactionType.income 
                                            ? Icons.add_circle_outline 
                                            : Icons.remove_circle_outline,
                                        color: _selectedTransactionType == FixedTransactionType.income 
                                            ? Theme.of(context).colorScheme.primary 
                                            : Theme.of(context).colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _selectedTransactionType == FixedTransactionType.income 
                                            ? 'Nuevo Ingreso Fijo' 
                                            : 'Nuevo Gasto Fijo',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  NewFixedTransactionForm(
                                    initialType: _selectedTransactionType,
                                    onSave: (transaction) {
                                      if (transaction.id.isNotEmpty) {
                                        Provider.of<AppState>(context, listen: false)
                                            .addFixedTransaction(transaction);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(Icons.check_circle, color: Colors.white),
                                                SizedBox(width: 12),
                                                Text('Transacción guardada con éxito'),
                                              ],
                                            ),
                                            backgroundColor: Theme.of(context).colorScheme.primary,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                        _toggleForm(null);
                                      }
                                    },
                                    onCancel: () => _toggleForm(null),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Sección de ingresos fijos
                  _buildSectionHeader('Ingresos Fijos', appState, Icons.trending_up),
                  incomeTransactions.isEmpty
                      ? _buildEmptyState('No hay ingresos fijos registrados', Icons.trending_up)
                      : _buildTransactionsList(incomeTransactions, appState),
                  
                  const SizedBox(height: 24),
                  
                  // Sección de gastos fijos
                  _buildSectionHeader('Gastos Fijos', appState, Icons.trending_down),
                  expenseTransactions.isEmpty
                      ? _buildEmptyState('No hay gastos fijos registrados', Icons.trending_down)
                      : _buildTransactionsList(expenseTransactions, appState),
                ],
              ),
            ),
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}