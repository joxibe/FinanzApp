import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/features/balance/domain/models/ant_transaction.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_transaction.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';

/// Widget reutilizable para mostrar un ítem de balance (saldo, ingresos, gastos)
class BalanceItem extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const BalanceItem({
    super.key,
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
          NumberFormatter.formatCurrency(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// Widget reutilizable para mostrar una transacción en una lista
class TransactionItem extends StatelessWidget {
  final AntTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == AntTransactionType.expense;
    final color = isExpense ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Icono de categoría
              CircleAvatar(
                backgroundColor: transaction.category.color.withOpacity(0.2),
                child: Icon(
                  transaction.category.icon,
                  color: transaction.category.color,
                ),
              ),
              const SizedBox(width: 16),
              // Información de la transacción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${transaction.date.day}/${transaction.date.month}/${transaction.date.year} - ${transaction.category.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Monto
              Text(
                NumberFormatter.formatCurrency(transaction.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Botones de acción
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('¿Eliminar transacción?'),
                            content: const Text('Esta acción no se puede deshacer.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete?.call();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget reutilizable para mostrar una transacción fija en una lista
class FixedTransactionItem extends StatelessWidget {
  final FixedTransaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FixedTransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == FixedTransactionType.expense;
    final color = isExpense ? Colors.red : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Icono de categoría
              CircleAvatar(
                backgroundColor: transaction.category.color.withOpacity(0.2),
                child: Icon(
                  transaction.category.icon,
                  color: transaction.category.color,
                ),
              ),
              const SizedBox(width: 16),
              // Información de la transacción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Día ${transaction.date.day} - ${transaction.category.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              // Monto
              Text(
                NumberFormatter.formatCurrency(transaction.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Botones de acción
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('¿Eliminar transacción fija?'),
                            content: const Text('Esta acción no se puede deshacer.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onDelete?.call();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                        break;
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget reutilizable para mostrar un resumen de balance
class BalanceSummaryCard extends StatelessWidget {
  final double currentBalance;
  final double initialBalance;
  final double totalIncome;
  final double totalExpenses;
  final Color incomeColor;
  final Color expenseColor;
  final Color balanceColor;

  const BalanceSummaryCard({
    super.key,
    required this.currentBalance,
    required this.initialBalance,
    required this.totalIncome,
    required this.totalExpenses,
    this.incomeColor = const Color(0xFF48BB78), // Verde por defecto
    this.expenseColor = const Color(0xFFED8936), // Naranja por defecto
    this.balanceColor = const Color(0xFF48BB78), // Verde por defecto
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
              'Balance General',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Balance actual más prominente
            Center(
              child: Column(
                children: [
                  Text(
                    NumberFormatter.formatCurrency(currentBalance),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: balanceColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Balance Actual',
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
            // Ingresos y gastos en una fila
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BalanceItem(
                  title: 'Ingresos',
                  amount: NumberFormatter.formatCurrency(totalIncome),
                  icon: Icons.arrow_upward,
                  color: incomeColor,
                ),
                _BalanceItem(
                  title: 'Gastos',
                  amount: NumberFormatter.formatCurrency(totalExpenses),
                  icon: Icons.arrow_downward,
                  color: expenseColor,
                ),
                _BalanceItem(
                  title: 'Saldo Inicial',
                  amount: NumberFormatter.formatCurrency(initialBalance),
                  icon: Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
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

/// Widget reutilizable para mostrar un mensaje cuando no hay datos
class EmptyStateMessage extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onButtonPressed;

  const EmptyStateMessage({
    super.key,
    required this.message,
    required this.buttonLabel,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add),
                label: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget base para formularios modales con animaciones suaves
class AnimatedFormModal extends StatefulWidget {
  final Widget child;
  final String title;
  final VoidCallback? onClose;

  const AnimatedFormModal({
    super.key,
    required this.child,
    required this.title,
    this.onClose,
  });

  @override
  State<AnimatedFormModal> createState() => _AnimatedFormModalState();
}

class _AnimatedFormModalState extends State<AnimatedFormModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _handleClose();
        return false;
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 100 * _slideAnimation.value),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barra de título
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                widget.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _handleClose,
                                style: IconButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Contenido del formulario
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                              left: 16,
                              right: 16,
                              top: 16,
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Widget para campos de formulario con animaciones y validación visual
class AnimatedFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final TextInputAction? textInputAction;
  final void Function(String)? onChanged;

  const AnimatedFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.autofocus = false,
    this.focusNode,
    this.onEditingComplete,
    this.textInputAction,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffix: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autofocus: autofocus,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      textInputAction: textInputAction,
      onChanged: onChanged,
    );
  }
}

/// Widget para botones de formulario con animaciones
class AnimatedFormButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool isPrimary;
  final bool isLoading;

  const AnimatedFormButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isPrimary = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isPrimary
        ? FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );

    return isPrimary
        ? FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : child,
            ),
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : child,
            ),
          );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Si el texto está vacío, permitir la operación
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Obtener solo los dígitos del texto actual
    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Si no hay cambios en los dígitos, retornar el valor actual
    if (oldDigits == newDigits) {
      return newValue;
    }

    // Calcular la posición del cursor en el texto sin formato
    final oldCursorPos = oldValue.selection.baseOffset;
    int digitsBeforeCursor = 0;
    int nonDigitsBeforeCursor = 0;
    for (int i = 0; i < oldCursorPos; i++) {
      if (oldValue.text[i].contains(RegExp(r'[0-9]'))) {
        digitsBeforeCursor++;
      } else {
        nonDigitsBeforeCursor++;
      }
    }

    // Determinar si se está borrando o insertando
    final isDeleting = oldDigits.length > newDigits.length;
    final isInserting = newDigits.length > oldDigits.length;

    // Formatear el nuevo valor
    final number = int.tryParse(newDigits) ?? 0;
    final formatted = NumberFormatter.formatCurrency(number.toDouble())
        .replaceAll(RegExp(r'[^\d.,]'), '');

    // Calcular la nueva posición del cursor
    int newCursorPos = 0;
    if (isDeleting) {
      // Al borrar, mantener el cursor en la posición relativa al último dígito
      int currentDigits = 0;
      int currentNonDigits = 0;
      
      for (int i = 0; i < formatted.length; i++) {
        if (formatted[i].contains(RegExp(r'[0-9]'))) {
          currentDigits++;
          if (currentDigits == digitsBeforeCursor) {
            // Encontrar la posición del siguiente separador
            for (int j = i + 1; j < formatted.length; j++) {
              if (!formatted[j].contains(RegExp(r'[0-9]'))) {
                newCursorPos = j;
                break;
              }
            }
            // Si no hay separador después, usar la posición actual
            if (newCursorPos == 0) {
              newCursorPos = i + 1;
            }
            break;
          }
        } else {
          currentNonDigits++;
        }
      }
      
      // Si no se encontró una posición válida, usar la longitud del texto
      if (newCursorPos == 0) {
        newCursorPos = formatted.length;
      }
    } else if (isInserting) {
      // Al insertar, mover el cursor después del dígito insertado
      int digitsCount = 0;
      for (int i = 0; i < formatted.length; i++) {
        if (formatted[i].contains(RegExp(r'[0-9]'))) {
          digitsCount++;
          if (digitsCount > digitsBeforeCursor) {
            newCursorPos = i + 1;
            break;
          }
        }
      }
      // Si no se encontró una posición después del dígito insertado, poner al final
      if (newCursorPos == 0) {
        newCursorPos = formatted.length;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
} 