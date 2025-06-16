import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_transaction.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:finanz_app/features/balance/domain/models/ant_transaction.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';
import 'package:finanz_app/core/theme/app_theme.dart';
import 'package:finanz_app/core/data/repositories/fixed_transaction_repository.dart';
import 'package:finanz_app/core/data/repositories/ant_transaction_repository.dart';
import 'package:finanz_app/core/data/repositories/fixed_category_repository.dart';
import 'package:finanz_app/core/data/repositories/ant_category_repository.dart';

// Enumeraciones para el filtrado
enum SortType { amount, date }
enum SortOrder { ascending, descending }

/// Estado global de la aplicación
class AppState extends ChangeNotifier {
  final FixedTransactionRepository _fixedTransactionRepo = FixedTransactionRepository();
  final AntTransactionRepository _antTransactionRepo = AntTransactionRepository();
  final FixedCategoryRepository _fixedCategoryRepo = FixedCategoryRepository();
  final AntCategoryRepository _antCategoryRepo = AntCategoryRepository();

  // Lista de transacciones fijas (presupuesto)
  List<FixedTransaction> _fixedTransactions = [];
  
  // Lista de transacciones hormiga (balance)
  List<AntTransaction> _antTransactions = [];

  // Lista de categorías fijas
  List<FixedCategory> _fixedCategories = [];

  // Lista de categorías hormiga
  List<AntCategory> _antCategories = [];

  // Estados de filtrado
  SortType _budgetSortType = SortType.date;
  SortOrder _budgetSortOrder = SortOrder.descending;
  SortType _balanceSortType = SortType.date;
  SortOrder _balanceSortOrder = SortOrder.descending;

  // Getters y setters para los estados de filtrado
  SortType get budgetSortType => _budgetSortType;
  SortOrder get budgetSortOrder => _budgetSortOrder;
  SortType get balanceSortType => _balanceSortType;
  SortOrder get balanceSortOrder => _balanceSortOrder;

  // Control del mes actual que se está visualizando
  DateTime _currentViewMonth = DateTime.now();
  DateTime get currentViewMonth => _currentViewMonth;

  // Getters para las transacciones y categorías
  List<FixedTransaction> get fixedTransactions => List.unmodifiable(_fixedTransactions);
  List<AntTransaction> get antTransactions => List.unmodifiable(_antTransactions);
  List<FixedCategory> get fixedCategories => List.unmodifiable(_fixedCategories);
  List<AntCategory> get antCategories => List.unmodifiable(_antCategories);

  // Transacciones fijas filtradas para el mes en visualización
  List<FixedTransaction> get currentMonthFixedTransactions {
    return _fixedTransactions.where((transaction) => 
      transaction.date.year == _currentViewMonth.year && 
      transaction.date.month == _currentViewMonth.month
    ).toList();
  }

  // Transacciones hormiga filtradas para el mes en visualización
  List<AntTransaction> get currentMonthAntTransactions {
    return _antTransactions.where((transaction) => 
      transaction.date.year == _currentViewMonth.year && 
      transaction.date.month == _currentViewMonth.month
    ).toList();
  }

  // Calcular el saldo inicial (ingresos fijos - gastos fijos) para el mes actual
  double get initialBalance {
    final transactions = currentMonthFixedTransactions;
    
    final totalFixedIncome = transactions
        .where((t) => t.type == FixedTransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalFixedExpenses = transactions
        .where((t) => t.type == FixedTransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return totalFixedIncome - totalFixedExpenses;
  }

  // Calcular el balance actual (saldo inicial - gastos hormiga + ingresos hormiga) para el mes actual
  double get currentBalance {
    final antTransactions = currentMonthAntTransactions;
    
    final totalAntExpenses = antTransactions
        .where((t) => t.type == AntTransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalAntIncome = antTransactions
        .where((t) => t.type == AntTransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    return initialBalance - totalAntExpenses + totalAntIncome;
  }

  // Cambiar el mes que se está visualizando
  Future<void> changeViewMonth(DateTime newMonth) async {
    try {
      // Validar que la fecha no sea anterior a 2017
      if (newMonth.year < 2017) {
        throw Exception('No se pueden ver datos anteriores a 2017');
      }
      
      // Validar que la fecha no sea más de 2 años en el futuro
      final now = DateTime.now();
      final maxFutureDate = DateTime(now.year + 2, 12, 31);
      if (newMonth.isAfter(maxFutureDate)) {
        throw Exception('No se pueden ver datos más allá de ${maxFutureDate.year}');
      }

      _currentViewMonth = DateTime(newMonth.year, newMonth.month, 1);
      await _ensureMonthHasFixedTransactions(_currentViewMonth);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cambiar el mes: $e');
      rethrow;
    }
  }

  // Cargar datos iniciales
  Future<void> loadInitialData() async {
    await Future.wait([
      _loadFixedTransactions(),
      _loadAntTransactions(),
      _loadFixedCategories(),
      _loadAntCategories(),
      _loadSortPreferences(),
    ]);
    
    await _ensureMonthHasFixedTransactions(_currentViewMonth);
    notifyListeners();
  }

  // Asegura que el mes especificado tenga transacciones fijas
  Future<void> _ensureMonthHasFixedTransactions(DateTime month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final monthKey = '${month.year}-${month.month}';
      final processedMonths = prefs.getStringList('processed_fixed_months') ?? [];
      
      // Si el mes ya fue procesado, no hacer nada
      if (processedMonths.contains(monthKey)) {
        return;
      }
      
      // Buscar transacciones del mes anterior
      final previousMonth = DateTime(
        month.month == 1 ? month.year - 1 : month.year,
        month.month == 1 ? 12 : month.month - 1,
      );
      
      // Obtener transacciones del mes anterior
      final previousMonthTransactions = _fixedTransactions.where((tx) =>
        tx.date.year == previousMonth.year && 
        tx.date.month == previousMonth.month
      ).toList();
      
      // Verificar si ya existen transacciones para este mes
      final currentMonthTransactions = _fixedTransactions.where((tx) => 
        tx.date.year == month.year && 
        tx.date.month == month.month
      ).toList();
      
      // Si no hay transacciones para este mes y hay transacciones del mes anterior
      if (currentMonthTransactions.isEmpty && previousMonthTransactions.isNotEmpty) {
        // Copiar cada transacción del mes anterior al mes actual
        for (final tx in previousMonthTransactions) {
          final newTx = FixedTransaction.create(
            description: tx.description,
            amount: tx.amount,
            category: tx.category,
            dayOfMonth: tx.dayOfMonth,
            type: tx.type,
          );
          
          // Ajustar la fecha al mes actual
          final newDate = DateTime(month.year, month.month, tx.dayOfMonth);
          final adjustedTx = newTx.copyWith(date: newDate);
          
          await _fixedTransactionRepo.addTransaction(adjustedTx);
        }
        
        // Recargar transacciones
        await _loadFixedTransactions();
      }
      
      // Marcar este mes como procesado
      if (processedMonths.length > 100) {
        // Mantener solo los últimos 100 meses procesados para evitar crecimiento indefinido
        processedMonths.removeRange(0, processedMonths.length - 100);
      }
      processedMonths.add(monthKey);
      await prefs.setStringList('processed_fixed_months', processedMonths);
    } catch (e) {
      debugPrint('Error al procesar transacciones fijas del mes: $e');
      rethrow;
    }
  }

  Future<void> _loadFixedTransactions() async {
    _fixedTransactions = await _fixedTransactionRepo.getAllTransactions();
  }

  Future<void> _loadAntTransactions() async {
    _antTransactions = await _antTransactionRepo.getAllTransactions();
  }

  Future<void> _loadFixedCategories() async {
    _fixedCategories = await _fixedCategoryRepo.getAllCategories();
  }

  Future<void> _loadAntCategories() async {
    _antCategories = await _antCategoryRepo.getAllCategories();
  }

  // Cargar preferencias de ordenamiento
  Future<void> _loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    _budgetSortType = SortType.values[prefs.getInt('budgetSortType') ?? SortType.date.index];
    _budgetSortOrder = SortOrder.values[prefs.getInt('budgetSortOrder') ?? SortOrder.descending.index];
    _balanceSortType = SortType.values[prefs.getInt('balanceSortType') ?? SortType.date.index];
    _balanceSortOrder = SortOrder.values[prefs.getInt('balanceSortOrder') ?? SortOrder.descending.index];
  }

  // Actualizar preferencias de ordenamiento para el presupuesto
  Future<void> updateBudgetSort(SortType type, SortOrder order) async {
    _budgetSortType = type;
    _budgetSortOrder = order;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('budgetSortType', type.index);
    await prefs.setInt('budgetSortOrder', order.index);
    
    notifyListeners();
  }

  // Actualizar preferencias de ordenamiento para el balance
  Future<void> updateBalanceSort(SortType type, SortOrder order) async {
    _balanceSortType = type;
    _balanceSortOrder = order;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('balanceSortType', type.index);
    await prefs.setInt('balanceSortOrder', order.index);
    
    notifyListeners();
  }

  // Agregar una transacción fija
  Future<void> addFixedTransaction(FixedTransaction transaction) async {
    await _fixedTransactionRepo.addTransaction(transaction);
    await _loadFixedTransactions();
    notifyListeners();
  }

  // Agregar una transacción hormiga
  Future<void> addAntTransaction(AntTransaction transaction) async {
    await _antTransactionRepo.addTransaction(transaction);
    await _loadAntTransactions();
    notifyListeners();
  }

  // Actualizar una transacción fija
  Future<void> updateFixedTransaction(FixedTransaction updatedTransaction) async {
    await _fixedTransactionRepo.updateTransaction(updatedTransaction);
    await _loadFixedTransactions();
    notifyListeners();
  }

  // Actualizar una transacción hormiga
  Future<void> updateAntTransaction(AntTransaction updatedTransaction) async {
    await _antTransactionRepo.updateTransaction(updatedTransaction);
    await _loadAntTransactions();
    notifyListeners();
  }

  // Eliminar una transacción fija
  Future<void> deleteFixedTransaction(FixedTransaction transaction) async {
    await _fixedTransactionRepo.deleteTransaction(transaction);
    await _loadFixedTransactions();
    notifyListeners();
  }

  // Eliminar una transacción hormiga
  Future<void> deleteAntTransaction(AntTransaction transaction) async {
    await _antTransactionRepo.deleteTransaction(transaction);
    await _loadAntTransactions();
    notifyListeners();
  }

  // Agregar una categoría fija
  Future<void> addFixedCategory(FixedCategory category) async {
    await _fixedCategoryRepo.addCategory(category);
    await _loadFixedCategories();
    notifyListeners();
  }

  // Agregar una categoría hormiga
  Future<void> addAntCategory(AntCategory category) async {
    await _antCategoryRepo.addCategory(category);
    await _loadAntCategories();
    notifyListeners();
  }

  // Actualizar una categoría fija
  Future<void> updateFixedCategory(FixedCategory category) async {
    await _fixedCategoryRepo.updateCategory(category);
    await _loadFixedCategories();
    notifyListeners();
  }

  // Actualizar una categoría hormiga
  Future<void> updateAntCategory(AntCategory category) async {
    await _antCategoryRepo.updateCategory(category);
    await _loadAntCategories();
    notifyListeners();
  }

  // Eliminar una categoría fija
  Future<void> deleteFixedCategory(FixedCategory category) async {
    await _fixedCategoryRepo.deleteCategory(category);
    await _loadFixedCategories();
    notifyListeners();
  }

  // Eliminar una categoría hormiga
  Future<void> deleteAntCategory(AntCategory category) async {
    await _antCategoryRepo.deleteCategory(category);
    await _loadAntCategories();
    notifyListeners();
  }

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  set selectedIndex(int value) {
    _selectedIndex = value;
    notifyListeners();
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  AppState({
    List<AntTransaction>? antTransactions,
    List<FixedTransaction>? fixedTransactions,
    List<AntCategory>? antCategories,
    List<FixedCategory>? fixedCategories,
  }) {
    if (antTransactions != null) _antTransactions = antTransactions;
    if (fixedTransactions != null) _fixedTransactions = fixedTransactions;
    if (antCategories != null) _antCategories = antCategories;
    if (fixedCategories != null) _fixedCategories = fixedCategories;
    
    _loadThemePreference();
    if (antTransactions == null && fixedTransactions == null && 
        antCategories == null && fixedCategories == null) {
      loadInitialData();
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Actualizar el estado de la app con datos importados
  Future<void> updateFromImport(AppState importedState) async {
    try {
      // Validar datos importados
      if (importedState.fixedCategories.isEmpty || importedState.antCategories.isEmpty) {
        throw Exception('Los datos importados deben contener al menos una categoría de cada tipo');
      }

      // Limpiar datos actuales
      await Future.wait([
        _fixedTransactionRepo.deleteAllTransactions(),
        _antTransactionRepo.deleteAllTransactions(),
        _fixedCategoryRepo.deleteAllCategories(),
        _antCategoryRepo.deleteAllCategories(),
      ]);

      // Importar nuevas categorías
      for (final category in importedState.fixedCategories) {
        await _fixedCategoryRepo.addCategory(category);
      }
      for (final category in importedState.antCategories) {
        await _antCategoryRepo.addCategory(category);
      }

      // Importar nuevas transacciones
      for (final transaction in importedState.fixedTransactions) {
        await _fixedTransactionRepo.addTransaction(transaction);
      }
      for (final transaction in importedState.antTransactions) {
        await _antTransactionRepo.addTransaction(transaction);
      }

      // Recargar todos los datos
      await loadInitialData();
    } catch (e) {
      debugPrint('Error al importar datos: $e');
      rethrow;
    }
  }

  // Eliminar todas las transacciones del mes actual (fijas y/o hormiga)
  Future<void> deleteCurrentMonthTransactions({bool deleteFixed = true, bool deleteAnt = true}) async {
    if (deleteFixed) {
      final fixedToDelete = currentMonthFixedTransactions;
      for (final tx in fixedToDelete) {
        await _fixedTransactionRepo.deleteTransaction(tx);
      }
      await _loadFixedTransactions();
    }
    if (deleteAnt) {
      final antToDelete = currentMonthAntTransactions;
      for (final tx in antToDelete) {
        await _antTransactionRepo.deleteTransaction(tx);
      }
      await _loadAntTransactions();
    }
    notifyListeners();
  }
}