import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/core/presentation/widgets/shared_widgets.dart';
import 'package:finanz_app/core/presentation/widgets/custom_date_picker.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import '../../domain/models/ant_category.dart';
import '../../domain/models/ant_transaction.dart';

class NewTransactionForm extends StatefulWidget {
  final Function(AntTransaction) onSave;
  final VoidCallback? onCancel;
  final AntTransactionType? initialType;

  const NewTransactionForm({
    super.key,
    required this.onSave,
    this.onCancel,
    this.initialType,
  });

  @override
  State<NewTransactionForm> createState() => _NewTransactionFormState();
}

class _NewTransactionFormState extends State<NewTransactionForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionFocusNode = FocusNode();
  final _amountFocusNode = FocusNode();
  
  AntTransactionType _selectedType = AntTransactionType.expense;
  AntCategory? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    _selectedCategory = AntCategory.getCategoriesByType(_selectedType).first;
    
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
  void didUpdateWidget(NewTransactionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambia el tipo inicial, actualizar el tipo y la categoría
    if (widget.initialType != null && widget.initialType != _selectedType) {
      setState(() {
        _selectedType = widget.initialType!;
        _selectedCategory = AntCategory.getCategoriesByType(_selectedType).first;
      });
    }
  }

  void _handleTypeChange(AntTransactionType type) {
    setState(() {
      _selectedType = type;
      _selectedCategory = AntCategory.getCategoriesByType(type).first;
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

        final transaction = AntTransaction.create(
          description: description,
          amount: amount,
          category: _selectedCategory!,
          type: _selectedType,
          date: _selectedDate,
        );

        widget.onSave(transaction);
        await _animationController.reverse();
        
        _descriptionController.clear();
        _amountController.clear();
        setState(() {
          _selectedCategory = AntCategory.getCategoriesByType(_selectedType).first;
          _selectedDate = DateTime.now();
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

          // Descripción con animación
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

          // Monto con animación
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
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  items: AntCategory.getCategoriesByType(_selectedType).map((category) {
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
                  onChanged: (AntCategory? value) {
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
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _selectedCategory!.legend,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botones con animación
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