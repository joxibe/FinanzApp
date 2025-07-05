import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:finanz_app/features/budget/domain/models/fixed_category.dart';
import 'package:finanz_app/features/balance/domain/models/ant_category.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<void> init() async {
    await database; // Esto inicializará la base de datos si no está inicializada
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'finanz_app_v2.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de categorías fijas
    await db.execute('''
      CREATE TABLE fixed_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        legend TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Tabla de categorías hormiga
    await db.execute('''
      CREATE TABLE ant_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        legend TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Tabla de transacciones fijas
    await db.execute('''
      CREATE TABLE fixed_transactions (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        dayOfMonth INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT "pendiente",
        FOREIGN KEY (category_id) REFERENCES fixed_categories (id)
          ON DELETE CASCADE
      )
    ''');

    // Tabla de transacciones hormiga
    await db.execute('''
      CREATE TABLE ant_transactions (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES ant_categories (id)
          ON DELETE CASCADE
      )
    ''');

    // Insertar categorías por defecto
    await _insertDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar nuevos campos a las tablas existentes
      await db.execute('ALTER TABLE fixed_categories ADD COLUMN legend TEXT NOT NULL DEFAULT "Sin descripción"');
      await db.execute('ALTER TABLE fixed_categories ADD COLUMN type TEXT NOT NULL DEFAULT "expense"');
      await db.execute('ALTER TABLE ant_categories ADD COLUMN legend TEXT NOT NULL DEFAULT "Sin descripción"');
      await db.execute('ALTER TABLE fixed_transactions ADD COLUMN dayOfMonth INTEGER NOT NULL DEFAULT 1');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE fixed_transactions ADD COLUMN status TEXT NOT NULL DEFAULT "pendiente"');
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    // Insertar todas las categorías fijas del modelo
    for (final category in FixedCategory.expenseCategories) {
      await db.insert('fixed_categories', {
        'id': category.id,
        'name': category.name,
        'legend': category.legend,
        'icon': category.iconName,
        'color': category.color.value,
        'type': category.type.toString().split('.').last,
      });
    }
    for (final category in FixedCategory.incomeCategories) {
      await db.insert('fixed_categories', {
        'id': category.id,
        'name': category.name,
        'legend': category.legend,
        'icon': category.iconName,
        'color': category.color.value,
        'type': category.type.toString().split('.').last,
      });
    }
    // Insertar todas las categorías hormiga del modelo
    for (final category in AntCategory.expenseCategories) {
      await db.insert('ant_categories', {
        'id': category.id,
        'name': category.name,
        'legend': category.legend,
        'icon': category.iconName,
        'color': category.color.value,
        'type': category.type.toString().split('.').last,
      });
    }
    for (final category in AntCategory.incomeCategories) {
      await db.insert('ant_categories', {
        'id': category.id,
        'name': category.name,
        'legend': category.legend,
        'icon': category.iconName,
        'color': category.color.value,
        'type': category.type.toString().split('.').last,
      });
    }
  }

  // Métodos de utilidad para operaciones CRUD
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
} 