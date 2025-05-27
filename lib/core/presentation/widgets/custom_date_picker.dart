import 'package:flutter/material.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback onCancel;
  final bool showMonthOnly;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
    required this.onCancel,
    this.showMonthOnly = false,
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
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
  ];

  final List<String> _dayNames = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];

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

  Future<void> _onCancel() async {
    await _animationController.reverse();
    widget.onCancel();
  }

  void _onOk() async {
    await _animationController.reverse();
    widget.onDateSelected(_selectedDate);
  }

  String _formatSelectedDate() {
    final weekDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final months = _monthNames;
    
    return '${weekDays[_selectedDate.weekday % 7]}, ${months[_selectedDate.month - 1]} ${_selectedDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
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
                          'Seleccionar fecha',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _onCancel,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Fecha seleccionada
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _formatSelectedDate(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de mes y año
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _previousMonth,
                        ),
                        GestureDetector(
                          onTap: _toggleYearPicker,
                          child: Text(
                            '$_monthName $_currentYear',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Días de la semana
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _dayNames.map((day) => SizedBox(
                        width: 32,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),

                    // Calendario
                    if (!_showYearPicker) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1,
                        ),
                        itemCount: _firstDayOfWeek + _daysInMonth,
                        itemBuilder: (context, index) {
                          if (index < _firstDayOfWeek) return const SizedBox();
                          
                          final day = index - _firstDayOfWeek + 1;
                          final isSelected = _selectedDate.year == _currentYear &&
                              _selectedDate.month == _currentMonth &&
                              _selectedDate.day == day;

                          return InkWell(
                            onTap: () => _selectDay(day),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  day.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).colorScheme.onSurface,
                                    fontWeight: isSelected ? FontWeight.bold : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      // Selector de año
                      AnimatedBuilder(
                        animation: _yearPickerAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _yearPickerAnimation.value,
                            child: SizedBox(
                              height: 200,
                              child: GridView.builder(
                                shrinkWrap: true,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  childAspectRatio: 2,
                                ),
                                itemCount: _availableYears.length,
                                itemBuilder: (context, index) {
                                  final year = _availableYears[index];
                                  final isSelected = year == _currentYear;

                                  return InkWell(
                                    onTap: () => _selectYear(year),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          year.toString(),
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Theme.of(context).colorScheme.onSurface,
                                            fontWeight: isSelected ? FontWeight.bold : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _onCancel,
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _onOk,
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
} 