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

  // Getters para las transacciones y categorías
  List<FixedTransaction> get fixedTransactions => List.unmodifiable(_fixedTransactions);
  List<AntTransaction> get antTransactions => List.unmodifiable(_antTransactions);
  List<FixedCategory> get fixedCategories => List.unmodifiable(_fixedCategories);
  List<AntCategory> get antCategories => List.unmodifiable(_antCategories);

  // Calcular el saldo inicial (ingresos fijos - gastos fijos)
  double get initialBalance {
    final totalFixedIncome = _fixedTransactions
        .where((t) => t.type == FixedTransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalFixedExpenses = _fixedTransactions
        .where((t) => t.type == FixedTransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return totalFixedIncome - totalFixedExpenses;
  }

  // Calcular el balance actual (saldo inicial - gastos hormiga + ingresos hormiga)
  double get currentBalance {
    final totalAntExpenses = _antTransactions
        .where((t) => t.type == AntTransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalAntIncome = _antTransactions
        .where((t) => t.type == AntTransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    return initialBalance - totalAntExpenses + totalAntIncome;
  }

  // Cargar datos iniciales
  Future<void> loadInitialData() async {
    await checkAndGenerateFixedTransactionsForNewMonth();
    await Future.wait([
      _loadFixedTransactions(),
      _loadAntTransactions(),
      _loadFixedCategories(),
      _loadAntCategories(),
    ]);
    notifyListeners();
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

  AppState() {
    _loadThemePreference();
    loadInitialData();
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

  // Cargar datos de prueba
  Future<void> loadMockData() async {
    // Primero eliminamos todos los datos existentes
    for (var transaction in _fixedTransactions) {
      await deleteFixedTransaction(transaction);
    }
    for (var transaction in _antTransactions) {
      await deleteAntTransaction(transaction);
    }
    for (var category in _fixedCategories) {
      await deleteFixedCategory(category);
    }
    for (var category in _antCategories) {
      await deleteAntCategory(category);
    }

    // Agregamos algunas categorías fijas de ejemplo
    final salario = FixedCategory(
      id: 'salary',
      name: 'Salario',
      legend: 'Ingreso mensual por trabajo',
      icon: Icons.work,
      color: Colors.green,
      type: FixedTransactionType.income,
    );

    final vivienda = FixedCategory(
      id: 'housing',
      name: 'Vivienda',
      legend: 'Gastos de vivienda',
      icon: Icons.home,
      color: Colors.blue,
      type: FixedTransactionType.expense,
    );

    final servicios = FixedCategory(
      id: 'services',
      name: 'Servicios',
      legend: 'Servicios básicos',
      icon: Icons.power,
      color: Colors.orange,
      type: FixedTransactionType.expense,
    );

    await addFixedCategory(salario);
    await addFixedCategory(vivienda);
    await addFixedCategory(servicios);

    // Agregamos algunas transacciones fijas de ejemplo
    final transaccionSalario = FixedTransaction(
      id: 'salario_1',
      description: 'Salario mensual',
      amount: 3000.0,
      date: DateTime.now(),
      category: salario,
      type: FixedTransactionType.income,
      dayOfMonth: 1,
    );

    final transaccionAlquiler = FixedTransaction(
      id: 'alquiler_1',
      description: 'Pago de alquiler',
      amount: 800.0,
      date: DateTime.now(),
      category: vivienda,
      type: FixedTransactionType.expense,
      dayOfMonth: 5,
    );

    final transaccionServicios = FixedTransaction(
      id: 'servicios_1',
      description: 'Pago de servicios',
      amount: 200.0,
      date: DateTime.now(),
      category: servicios,
      type: FixedTransactionType.expense,
      dayOfMonth: 10,
    );

    await addFixedTransaction(transaccionSalario);
    await addFixedTransaction(transaccionAlquiler);
    await addFixedTransaction(transaccionServicios);

    // Agregamos algunas categorías hormiga de ejemplo
    final comida = AntCategory(
      id: 'food',
      name: 'Alimentación y bebidas',
      legend: 'Comidas y bebidas',
      icon: Icons.restaurant,
      color: Colors.orange,
      type: AntTransactionType.expense,
    );

    final transporte = AntCategory(
      id: 'transport',
      name: 'Transporte y movilidad',
      legend: 'Transporte y viajes',
      icon: Icons.directions_car,
      color: Colors.blue,
      type: AntTransactionType.expense,
    );

    final entretenimiento = AntCategory(
      id: 'entertainment',
      name: 'Entretenimiento y ocio',
      legend: 'Diversión y recreación',
      icon: Icons.movie,
      color: Colors.purple,
      type: AntTransactionType.expense,
    );

    await addAntCategory(comida);
    await addAntCategory(transporte);
    await addAntCategory(entretenimiento);

    // Agregamos algunas transacciones hormiga de ejemplo
    final transaccionComida = AntTransaction(
      id: 'comida_1',
      description: 'Supermercado',
      amount: 50.0,
      date: DateTime.now(),
      category: comida,
      type: AntTransactionType.expense,
    );

    final transaccionTransporte = AntTransaction(
      id: 'transporte_1',
      description: 'Gasolina',
      amount: 30.0,
      date: DateTime.now(),
      category: transporte,
      type: AntTransactionType.expense,
    );

    final transaccionEntretenimiento = AntTransaction(
      id: 'entretenimiento_1',
      description: 'Cine',
      amount: 20.0,
      date: DateTime.now(),
      category: entretenimiento,
      type: AntTransactionType.expense,
    );

    await addAntTransaction(transaccionComida);
    await addAntTransaction(transaccionTransporte);
    await addAntTransaction(transaccionEntretenimiento);

    // Recargamos todos los datos
    await loadInitialData();
  }

  Future<void> checkAndGenerateFixedTransactionsForNewMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentMonthKey = '${now.year}-${now.month}';

    final lastProcessedMonth = prefs.getString('last_fixed_month');

    // Recarga las transacciones fijas antes de procesar
    await _loadFixedTransactions();

    if (lastProcessedMonth != currentMonthKey) {
      // Cargar transacciones fijas del mes anterior
      final previousMonth = DateTime(now.year, now.month - 1);
      final previousMonthTransactions = await _fixedTransactionRepo.getTransactionsByDateRange(
        DateTime(previousMonth.year, previousMonth.month, 1),
        DateTime(previousMonth.year, previousMonth.month + 1, 0),
      );

      // Por cada transacción fija del mes anterior, crear una nueva para el mes actual si no existe
      for (final tx in previousMonthTransactions) {
        final exists = _fixedTransactions.any((t) =>
          t.category.id == tx.category.id &&
          t.type == tx.type &&
          t.date.year == now.year &&
          t.date.month == now.month
        );
        if (!exists) {
          final newTx = tx.copyWith(
            id: null, // Genera un nuevo id
            date: DateTime(now.year, now.month, tx.dayOfMonth),
          );
          await _fixedTransactionRepo.addTransaction(newTx);
        }
      }

      // Actualiza el mes procesado
      await prefs.setString('last_fixed_month', currentMonthKey);
      // Recarga las transacciones
      await _loadFixedTransactions();
      notifyListeners();
    }
  }
} 