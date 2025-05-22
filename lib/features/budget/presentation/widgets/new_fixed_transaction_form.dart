import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/utils/number_formatter.dart';
import 'package:finanz_app/core/presentation/widgets/shared_widgets.dart';
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
        );

        widget.onSave(transaction);
        await _animationController.reverse();
        
        _descriptionController.clear();
        _amountController.clear();
        setState(() {
          _selectedDate = DateTime.now();
          _selectedCategory = FixedCategory.getCategoriesByType(_selectedType).first;
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
                'Día ${_selectedDate.day}',
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
                  value: _selectedCategory,
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

// Selector de fecha personalizado
class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onCancel;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    required this.onCancel,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> with TickerProviderStateMixin {
  late DateTime _selectedDate;
  late int _currentMonth;
  late int _currentYear;
  bool _showYearPicker = false;
  late AnimationController _animationController;
  late AnimationController _yearPickerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _yearPickerAnimation;

  final List<String> _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final List<String> _dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = _selectedDate.month;
    _currentYear = _selectedDate.year;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _yearPickerController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _yearPickerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _yearPickerController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _yearPickerController.dispose();
    super.dispose();
  }

  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(currentYear - 2017 + 1, (index) => 2017 + index);
  }

  String get _monthName => _monthNames[_currentMonth - 1];

  int get _daysInMonth {
    return DateTime(_currentYear, _currentMonth + 1, 0).day;
  }

  int get _firstDayOfWeek {
    return DateTime(_currentYear, _currentMonth, 1).weekday % 7;
  }

  void _previousMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
    });
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDate = DateTime(_currentYear, _currentMonth, day);
    });
  }

  void _toggleYearPicker() {
    setState(() {
      _showYearPicker = !_showYearPicker;
    });
    if (_showYearPicker) {
      _yearPickerController.forward();
    } else {
      _yearPickerController.reverse();
    }
  }

  void _selectYear(int year) {
    setState(() {
      _currentYear = year;
      _showYearPicker = false;
    });
    _yearPickerController.reverse();
  }

  Future <void> _onCancel() async {
    await _animationController.reverse();
    widget.onCancel();
  }

  void _onOk() async {
    await _animationController.reverse();
    widget.onDateSelected(_selectedDate);
  }

  String _formatSelectedDate() {
    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    return '${weekDays[_selectedDate.weekday % 7]}, ${months[_selectedDate.month - 1]} ${_selectedDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _onCancel();
        return false;
      },
      child: GestureDetector(
        onTap: _onCancel,
        child: Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5),
          body: Center(
            child: GestureDetector(
              onTap: () {}, // Prevenir que el tap llegue al Scaffold
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Select date',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                              
                              // Selected date
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatSelectedDate(),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Divider
                              const Divider(height: 24),
                              
                              // Month/Year selector and navigation
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: _previousMonth,
                                    icon: const Icon(Icons.chevron_left),
                                    iconSize: 28,
                                  ),
                                  
                                  Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: _toggleYearPicker,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '$_monthName $_currentYear',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                _showYearPicker ? Icons.expand_less : Icons.expand_more,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      // Year picker dropdown
                                      if (_showYearPicker)
                                        Positioned(
                                          top: 40,
                                          child: AnimatedBuilder(
                                            animation: _yearPickerAnimation,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: _yearPickerAnimation.value,
                                                alignment: Alignment.topCenter,
                                                child: Opacity(
                                                  opacity: _yearPickerAnimation.value,
                                                  child: Material(
                                                    elevation: 4,
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Container(
                                                      height: 200,
                                                      width: 120,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).colorScheme.surface,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(
                                                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                                        ),
                                                      ),
                                                      child: ListView.builder(
                                                        itemCount: _availableYears.length,
                                                        itemBuilder: (context, index) {
                                                          final year = _availableYears[index];
                                                          final isSelected = year == _currentYear;
                                                          return InkWell(
                                                            onTap: () => _selectYear(year),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                              color: isSelected 
                                                                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                                                  : null,
                                                              child: Center(
                                                                child: Text(
                                                                  year.toString(),
                                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                                                    color: isSelected 
                                                                        ? Theme.of(context).colorScheme.primary
                                                                        : null,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                  
                                  IconButton(
                                    onPressed: _nextMonth,
                                    icon: const Icon(Icons.chevron_right),
                                    iconSize: 28,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Days of week header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: _dayNames.map((day) {
                                  return Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    child: Text(
                                      day,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Calendar grid
                              SizedBox(
                                height: 220,
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 7,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: 42, // 6 weeks
                                  itemBuilder: (context, index) {
                                    final dayOffset = index - _firstDayOfWeek;
                                    
                                    if (dayOffset < 0 || dayOffset >= _daysInMonth) {
                                      return const SizedBox();
                                    }
                                    
                                    final day = dayOffset + 1;
                                    final isSelected = day == _selectedDate.day && 
                                                     _currentMonth == _selectedDate.month && 
                                                     _currentYear == _selectedDate.year;
                                    final isToday = day == DateTime.now().day && 
                                                   _currentMonth == DateTime.now().month && 
                                                   _currentYear == DateTime.now().year;
                                    
                                    return GestureDetector(
                                      onTap: () => _selectDay(day),
                                      child: Container(
                                        margin: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: isSelected 
                                              ? Theme.of(context).colorScheme.primary
                                              : isToday
                                                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                                  : null,
                                          borderRadius: BorderRadius.circular(18),
                                          border: isToday && !isSelected
                                              ? Border.all(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  width: 1,
                                                )
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            day.toString(),
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: isSelected 
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : isToday
                                                      ? Theme.of(context).colorScheme.primary
                                                      : null,
                                              fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _onCancel,
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: _onOk,
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
}