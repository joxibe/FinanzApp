import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/core/presentation/widgets/shared_widgets.dart';
import 'package:finanz_app/core/presentation/widgets/custom_date_picker.dart';
import '../../domain/models/fixed_category.dart';
import '../../domain/models/fixed_transaction.dart';

class EditFixedTransactionForm extends StatefulWidget {
  final FixedTransaction transaction;
  final Function(FixedTransaction) onSave;

  const EditFixedTransactionForm({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  @override
  State<EditFixedTransactionForm> createState() => _EditFixedTransactionFormState();
}

class _EditFixedTransactionFormState extends State<EditFixedTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  
  late FixedTransactionType _selectedType;
  late FixedCategory _selectedCategory;
  late int _selectedDay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.transaction.description;
    _amountController.text = NumberFormatter.formatCurrency(widget.transaction.amount);
    _selectedType = widget.transaction.type;
    final categories = FixedCategory.getCategoriesByType(_selectedType);
    _selectedCategory = categories.firstWhere(
      (cat) => cat.id == widget.transaction.category.id,
      orElse: () => categories.first,
    );
    _selectedDay = widget.transaction.date.day;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _descriptionFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _handleTypeChange(FixedTransactionType type) {
    setState(() {
      _selectedType = type;
      final categories = FixedCategory.getCategoriesByType(type);
      _selectedCategory = categories.firstWhere(
        (cat) => cat.id == _selectedCategory.id,
        orElse: () => categories.first,
      );
    });
  }

  Future<void> _selectDay(BuildContext context) async {
    final result = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CustomDatePicker(
          initialDate: DateTime(DateTime.now().year, DateTime.now().month, _selectedDay),
          onDateSelected: (DateTime date) {
            Navigator.of(context).pop(date);
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
          showMonthOnly: true,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDay = result.day;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final description = _descriptionController.text.trim().isEmpty 
          ? _selectedCategory.name 
          : _descriptionController.text;

      final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
      final amount = double.parse(cleanAmount);

      // Mantener el mismo mes y año, solo actualizar el día
      final updatedDate = DateTime(
        widget.transaction.date.year,
        widget.transaction.date.month,
        _selectedDay,
      );

      final updatedTransaction = widget.transaction.copyWith(
        description: description,
        amount: amount,
        category: _selectedCategory,
        date: updatedDate,
        type: _selectedType,
      );

      // Llamar a onSave y esperar a que termine
      await widget.onSave(updatedTransaction);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tipo de transacción
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: SegmentedButton<FixedTransactionType>(
              segments: const [
                ButtonSegment<FixedTransactionType>(
                  value: FixedTransactionType.expense,
                  label: Text('Gasto'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment<FixedTransactionType>(
                  value: FixedTransactionType.income,
                  label: Text('Ingreso'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<FixedTransactionType> selected) {
                _handleTypeChange(selected.first);
              },
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return _selectedType == FixedTransactionType.expense
                        ? const Color(0xFFED8936).withOpacity(0.1)
                        : const Color(0xFF48BB78).withOpacity(0.1);
                  }
                  return Colors.transparent;
                }),
                foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return _selectedType == FixedTransactionType.expense
                        ? const Color(0xFFED8936)
                        : const Color(0xFF48BB78);
                  }
                  return Theme.of(context).colorScheme.onSurfaceVariant;
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Descripción
          AnimatedFormField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            label: 'Descripción',
            hint: '¿En qué gastaste o recibiste? (opcional)',
            prefixIcon: Icons.description,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => _amountFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Monto
          AnimatedFormField(
            controller: _amountController,
            focusNode: _amountFocusNode,
            label: 'Monto',
            hint: 'Ingrese el monto en COP',
            prefixIcon: Icons.attach_money,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa un monto';
              }
              final cleanAmount = value.replaceAll(RegExp(r'[^\d]'), '');
              final amount = double.tryParse(cleanAmount);
              if (amount == null || amount <= 0) {
                return 'Ingresa un monto válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Día del mes
          InkWell(
            onTap: () => _selectDay(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Día del mes',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              child: Text(
                'Día $_selectedDay',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Categoría
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<FixedCategory>(
                  value: FixedCategory.getCategoriesByType(_selectedType).firstWhere(
                    (cat) => cat.id == _selectedCategory.id,
                    orElse: () => FixedCategory.getCategoriesByType(_selectedType).first,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  items: FixedCategory.getCategoriesByType(_selectedType).map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(category.icon, color: category.color),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (FixedCategory? value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor selecciona una categoría';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _selectedCategory.legend,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botones
          Row(
            children: [
              Expanded(
                child: AnimatedFormButton(
                  onPressed: () => Navigator.pop(context),
                  isPrimary: false,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedFormButton(
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 