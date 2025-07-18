import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/core/presentation/widgets/shared_widgets.dart';
import 'package:finanz_app/core/presentation/widgets/custom_date_picker.dart';
import '../../domain/models/ant_category.dart';
import '../../domain/models/ant_transaction.dart';

class EditTransactionForm extends StatefulWidget {
  final AntTransaction transaction;
  final Function(AntTransaction) onSave;

  const EditTransactionForm({
    super.key,
    required this.transaction,
    required this.onSave,
  });

  @override
  State<EditTransactionForm> createState() => _EditTransactionFormState();
}

class _EditTransactionFormState extends State<EditTransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  
  late AntTransactionType _selectedType;
  AntCategory? _selectedCategory;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.transaction.description;
    _amountController.text = NumberFormatter.formatCurrency(widget.transaction.amount);
    _selectedType = widget.transaction.type;
    final categories = AntCategory.getCategoriesByType(_selectedType);
    _selectedCategory = categories.firstWhere(
      (cat) => cat.id == widget.transaction.category.id,
      orElse: () => categories.first,
    );
    _selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _descriptionFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _handleTypeChange(AntTransactionType type) {
    setState(() {
      _selectedType = type;
      final categories = AntCategory.getCategoriesByType(type);
      _selectedCategory = categories.firstWhere(
        (cat) => cat.id == _selectedCategory?.id,
        orElse: () => categories.first,
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final result = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return CustomDatePicker(
          initialDate: _selectedDate,
          onDateSelected: (DateTime date) {
            Navigator.of(context).pop(date);
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
          restrictToCurrentMonth: true,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final description = _descriptionController.text.trim().isEmpty 
          ? _selectedCategory?.name 
          : _descriptionController.text;

      final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
      final amount = double.parse(cleanAmount);

      final updatedTransaction = widget.transaction.copyWith(
        description: description,
        amount: amount,
        category: _selectedCategory!,
        date: _selectedDate,
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
            child: SegmentedButton<AntTransactionType>(
              segments: const [
                ButtonSegment<AntTransactionType>(
                  value: AntTransactionType.expense,
                  label: Text('Gasto'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment<AntTransactionType>(
                  value: AntTransactionType.income,
                  label: Text('Ingreso'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<AntTransactionType> selected) {
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
                    return _selectedType == AntTransactionType.expense
                        ? const Color(0xFFED8936).withOpacity(0.1)
                        : const Color(0xFF48BB78).withOpacity(0.1);
                  }
                  return Colors.transparent;
                }),
                foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return _selectedType == AntTransactionType.expense
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

          // Fecha
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Solo se pueden editar transacciones en el mes actual. Para ver meses anteriores, consulta la sección de Informes > Gastos por categoría > Gastos hormiga.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categoría
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<AntCategory>(
                  value: _selectedCategory,
                  items: AntCategory.getCategoriesByType(_selectedType).map((category) {
                    return DropdownMenuItem<AntCategory>(
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
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                  ),
                  validator: (value) => value == null ? 'Selecciona una categoría' : null,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _selectedCategory?.legend ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (_selectedCategory != null && _selectedCategory!.type == AntTransactionType.expense)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Text(
                      'Pertenece a: 30% Gastos personales',
                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
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