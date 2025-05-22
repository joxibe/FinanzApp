import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/features/balance/domain/models/ant_transaction.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_transaction.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static const String CSV_TRANSACTIONS_HEADER = "ID,Tipo,Descripción,Categoría,Monto,Fecha";
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  // Exportar transacciones a CSV para el año y mes seleccionados
  static Future<String> exportToCSV({
    required List<AntTransaction> antTransactions, 
    required List<FixedTransaction> fixedTransactions,
    int? year,
    int? month,
  }) async {
    try {
      // Validar que haya datos para exportar
      final filteredAntTransactions = _filterAntTransactionsByDate(antTransactions, year ?? DateTime.now().year, month);
      final filteredFixedTransactions = _filterFixedTransactionsByDate(fixedTransactions, year ?? DateTime.now().year, month);
      
      if (filteredAntTransactions.isEmpty && filteredFixedTransactions.isEmpty) {
        throw Exception('No hay transacciones para exportar en el período seleccionado');
      }

      final DateTime now = DateTime.now();
      final int selectedYear = year ?? now.year;
      final String fileName = month != null 
          ? 'finanzapp_${selectedYear}_${month}.csv'
          : 'finanzapp_${selectedYear}.csv';

      // Convertir transacciones a formato CSV
      List<List<dynamic>> rows = [];
      
      // Añadir encabezado
      rows.add(CSV_TRANSACTIONS_HEADER.split(','));
      
      // Añadir transacciones hormiga
      for (final transaction in filteredAntTransactions) {
        rows.add([
          transaction.id,
          transaction.type == AntTransactionType.income ? 'Ingreso Hormiga' : 'Gasto Hormiga',
          transaction.description,
          transaction.category.name,
          transaction.amount,
          _dateFormatter.format(transaction.date),
        ]);
      }
      
      // Añadir transacciones fijas
      for (final transaction in filteredFixedTransactions) {
        rows.add([
          transaction.id,
          transaction.type == FixedTransactionType.income ? 'Ingreso Fijo' : 'Gasto Fijo',
          transaction.description,
          transaction.category.name,
          transaction.amount,
          _dateFormatter.format(transaction.date),
        ]);
      }

      // Convertir a string CSV
      String csv = const ListToCsvConverter().convert(rows);

      // Validar que el CSV no esté vacío
      if (csv.trim().isEmpty) {
        throw Exception('Error al generar el archivo CSV: el contenido está vacío');
      }

      // Guardar archivo
      String filePath = await _saveFile(fileName, csv);
      
      // Validar que el archivo se haya creado correctamente
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Error al guardar el archivo CSV: no se pudo crear el archivo');
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Error al guardar el archivo CSV: el archivo está vacío');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error en exportToCSV: $e');
      }
      rethrow;
    }
  }

  // Exportar todas las transacciones a JSON (para respaldo)
  static Future<String> exportToJSON(AppState appState) async {
    try {
      // Validar que haya datos para exportar
      if (appState.antTransactions.isEmpty && 
          appState.fixedTransactions.isEmpty && 
          appState.antCategories.isEmpty && 
          appState.fixedCategories.isEmpty) {
        throw Exception('No hay datos para exportar en el respaldo');
      }

      final DateTime now = DateTime.now();
      final String fileName = 'finanzapp_backup_${now.millisecondsSinceEpoch}.json';

      // Crear mapa con todos los datos de la app
      final Map<String, dynamic> appData = {
        'antTransactions': appState.antTransactions.map((t) => t.toJson()).toList(),
        'fixedTransactions': appState.fixedTransactions.map((t) => t.toJson()).toList(),
        'antCategories': appState.antCategories.map((c) => c.toJson()).toList(),
        'fixedCategories': appState.fixedCategories.map((c) => c.toJson()).toList(),
        'exportDate': now.toIso8601String(),
        'appVersion': '1.0.0',
      };

      // Convertir a JSON string con formato
      String jsonStr = const JsonEncoder.withIndent('  ').convert(appData);

      // Validar que el JSON no esté vacío
      if (jsonStr.trim().isEmpty) {
        throw Exception('Error al generar el archivo JSON: el contenido está vacío');
      }

      // Guardar archivo
      String filePath = await _saveFile(fileName, jsonStr);
      
      // Validar que el archivo se haya creado correctamente
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Error al guardar el archivo JSON: no se pudo crear el archivo');
      }
      
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Error al guardar el archivo JSON: el archivo está vacío');
      }

      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Error en exportToJSON: $e');
      }
      rethrow;
    }
  }

  // Compartir archivo
  static Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      // Validar que el archivo exista
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('El archivo a compartir no existe');
      }

      // Validar que el archivo no esté vacío
      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('El archivo a compartir está vacío');
      }

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Datos de FinanzApp',
      );
      
      if (kDebugMode) {
        print('Resultado del compartir: ${result.status}');
      }

      // Validar que el compartir fue exitoso
      if (result.status == ShareResultStatus.dismissed) {
        throw Exception('La operación de compartir fue cancelada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al compartir archivo: $e');
      }
      rethrow;
    }
  }

  // Guardar archivo en el almacenamiento local
  static Future<String> _saveFile(String fileName, String content) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final File file = File(filePath);
    await file.writeAsBytes(utf8.encode(content));
    return filePath;
  }

  // Filtrar transacciones hormiga por año y mes
  static List<AntTransaction> _filterAntTransactionsByDate(
    List<AntTransaction> transactions, 
    int year, 
    int? month,
  ) {
    return transactions.where((t) {
      if (month != null) {
        return t.date.year == year && t.date.month == month;
      }
      return t.date.year == year;
    }).toList();
  }

  // Filtrar transacciones fijas por año y mes
  static List<FixedTransaction> _filterFixedTransactionsByDate(
    List<FixedTransaction> transactions, 
    int year, 
    int? month,
  ) {
    return transactions.where((t) {
      if (month != null) {
        return t.date.year == year && t.date.month == month;
      }
      return t.date.year == year;
    }).toList();
  }

  // Importar datos desde un archivo JSON
  static Future<AppState> importFromJSON(String jsonContent) async {
    try {
      // Validar que el contenido no esté vacío
      if (jsonContent.trim().isEmpty) {
        throw Exception('El archivo JSON está vacío');
      }

      // Intentar decodificar el JSON
      Map<String, dynamic> appData;
      try {
        appData = json.decode(jsonContent);
      } catch (e) {
        throw Exception('El archivo JSON no tiene un formato válido');
      }
      
      // Validar campos requeridos
      if (!appData.containsKey('appVersion') || !appData.containsKey('exportDate')) {
        throw Exception('El archivo JSON no contiene la información necesaria (versión o fecha de exportación)');
      }

      // Validar versión y fecha de exportación
      final String appVersion = appData['appVersion'] as String;
      final String exportDate = appData['exportDate'] as String;
      
      if (kDebugMode) {
        print('Importando respaldo de la versión $appVersion del $exportDate');
      }

      // Validar que existan los datos necesarios
      if (!appData.containsKey('antTransactions') || 
          !appData.containsKey('fixedTransactions') || 
          !appData.containsKey('antCategories') || 
          !appData.containsKey('fixedCategories')) {
        throw Exception('El archivo JSON no contiene todos los datos necesarios');
      }

      // Convertir JSON a objetos
      List<AntTransaction> antTransactions;
      List<FixedTransaction> fixedTransactions;
      List<AntCategory> antCategories;
      List<FixedCategory> fixedCategories;

      try {
        antTransactions = (appData['antTransactions'] as List)
            .map((t) => AntTransaction.fromJson(t as Map<String, dynamic>))
            .toList();
            
        fixedTransactions = (appData['fixedTransactions'] as List)
            .map((t) => FixedTransaction.fromJson(t as Map<String, dynamic>))
            .toList();
            
        antCategories = (appData['antCategories'] as List)
            .map((c) => AntCategory.fromJson(c as Map<String, dynamic>))
            .toList();
            
        fixedCategories = (appData['fixedCategories'] as List)
            .map((c) => FixedCategory.fromJson(c as Map<String, dynamic>))
            .toList();
      } catch (e) {
        throw Exception('Error al convertir los datos del JSON: formato inválido en los datos');
      }

      // Validar que haya al menos una categoría de cada tipo
      if (antCategories.isEmpty || fixedCategories.isEmpty) {
        throw Exception('El archivo JSON debe contener al menos una categoría de cada tipo');
      }

      // Crear nuevo estado de la app
      return AppState(
        antTransactions: antTransactions,
        fixedTransactions: fixedTransactions,
        antCategories: antCategories,
        fixedCategories: fixedCategories,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error en importFromJSON: $e');
      }
      rethrow;
    }
  }

  // Leer archivo JSON
  static Future<String> readJSONFile(String filePath) async {
    try {
      final File file = File(filePath);
      return await file.readAsString();
    } catch (e) {
      if (kDebugMode) {
        print('Error al leer archivo JSON: $e');
      }
      rethrow;
    }
  }
} 