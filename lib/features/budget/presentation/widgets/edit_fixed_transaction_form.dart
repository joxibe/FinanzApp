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
  FixedCategory? _selectedCategory;
  late int _selectedDay;
  late FixedTransactionStatus _selectedStatus;
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
    _selectedStatus = widget.transaction.status;
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
        (cat) => cat.id == _selectedCategory?.id,
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
          restrictToCurrentMonth: true,
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
          ? _selectedCategory?.name 
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
        category: _selectedCategory!,
        date: updatedDate,
        type: _selectedType,
        status: _selectedStatus,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 8),
              Text(
                'Selecciona el día del mes en que se realizará esta transacción fija. Este día se mantendrá para los meses siguientes.',
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
                DropdownButtonFormField<FixedCategory>(
                  value: _selectedCategory,
                  items: FixedCategory.getCategoriesByType(_selectedType).map((category) {
                    return DropdownMenuItem<FixedCategory>(
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
                if (_selectedCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            String? regla;
                            if (['housing', 'main_food', 'main_transport', 'health'].contains(_selectedCategory!.id)) {
                              regla = 'Pertenece a: 50% Necesidades básicas';
                            } else if (['personal_services', 'financial_obligations', 'other_fixed'].contains(_selectedCategory!.id)) {
                              regla = 'Pertenece a: 30% Gastos personales';
                            } else if (_selectedCategory!.id == 'saving') {
                              regla = 'Pertenece a: 20% Ahorro (en desarrollo)';
                            }
                            return regla != null
                                ? Text(
                                    regla,
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                        if (_selectedCategory!.legend.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              _selectedCategory!.legend,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Estado
          DropdownButtonFormField<FixedTransactionStatus>(
            value: _selectedStatus,
            items: FixedTransactionStatus.values.map((status) {
              return DropdownMenuItem<FixedTransactionStatus>(
                value: status,
                child: Text(status == FixedTransactionStatus.pendiente ? 'Pendiente' : 'Pagado'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Estado',
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