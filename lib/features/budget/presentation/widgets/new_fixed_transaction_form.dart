import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/core/presentation/widgets/shared_widgets.dart';
import 'package:finanz_app/core/presentation/widgets/custom_date_picker.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import '../../domain/models/fixed_category.dart';
import '../../domain/models/fixed_transaction.dart';

class NewFixedTransactionForm extends StatefulWidget {
  final Function(FixedTransaction) onSave;
  final VoidCallback? onCancel;
  final FixedTransactionType? initialType;

  const NewFixedTransactionForm({
    super.key,
    required this.onSave,
    this.onCancel,
    this.initialType,
  });

  @override
  State<NewFixedTransactionForm> createState() => _NewFixedTransactionFormState();
}

class _NewFixedTransactionFormState extends State<NewFixedTransactionForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  
  FixedTransactionType _selectedType = FixedTransactionType.expense;
  FixedCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  FixedTransactionStatus _selectedStatus = FixedTransactionStatus.pendiente;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    _selectedCategory = FixedCategory.getCategoriesByType(_selectedType).first;
    
    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _descriptionFocusNode.dispose();
    _amountFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NewFixedTransactionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el tipo inicial, actualizar el tipo y la categoría
    if (widget.initialType != null && widget.initialType != _selectedType) {
      setState(() {
        _selectedType = widget.initialType!;
        _selectedCategory = FixedCategory.getCategoriesByType(_selectedType).first;
      });
    }
  }

  void _handleTypeChange(FixedTransactionType type) {
    setState(() {
      _selectedType = type;
      _selectedCategory = FixedCategory.getCategoriesByType(type).first;
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
          showMonthOnly: true,
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
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona una categoría'),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final description = _descriptionController.text.trim().isEmpty 
            ? _selectedCategory!.name 
            : _descriptionController.text;

        final cleanAmount = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
        final amount = double.parse(cleanAmount);

        final transaction = FixedTransaction.create(
          description: description,
          amount: amount,
          category: _selectedCategory!,
          dayOfMonth: _selectedDate.day,
          type: _selectedType,
          status: _selectedStatus,
        );

        await widget.onSave(transaction);
        await _animationController.reverse();
        
        _descriptionController.clear();
        _amountController.clear();
        setState(() {
          _selectedDate = DateTime.now();
          _selectedCategory = FixedCategory.getCategoriesByType(_selectedType).first;
          _selectedStatus = FixedTransactionStatus.pendiente;
        });

        widget.onCancel?.call();
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
                    labelText: 'Día del mes',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  child: Text(
                    'Día ${_selectedDate.day}',
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
                    String? regla;
                    if (['housing', 'main_food', 'main_transport', 'health'].contains(category.id)) {
                      regla = '50% Necesidades básicas';
                    } else if (['personal_services', 'financial_obligations', 'other_fixed'].contains(category.id)) {
                      regla = '30% Gastos personales';
                    } else if (category.id == 'saving') {
                      regla = '20% Ahorro (en desarrollo)';
                    }
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

          // Botón
          AnimatedFormButton(
            onPressed: _handleSubmit,
            isLoading: _isLoading,
            child: const Text('Guardar'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}