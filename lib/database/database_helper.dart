import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/product.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'wholemarket.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            selling_price REAL NOT NULL,
            unit_cost REAL NOT NULL,
            stock_quantity INTEGER NOT NULL,
            expiration_date TEXT NOT NULL,
            season TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE categories (
            name TEXT PRIMARY KEY COLLATE NOCASE
          )
        ''');
      },
    );

    return _database!;
  }

  Future<void> insertProduct(Product product) async {
    final db = await database;

    await db.insert(
      'products',
      _productToMap(product),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await database;

    await db.update(
      'products',
      _productToMap(product),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;

    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getProducts() async {
    final db = await database;

    final rows = await db.query('products', orderBy: 'name ASC');

    return rows.map((row) {
      return Product(
        id: row['id'] as String,
        name: row['name'] as String,
        category: row['category'] as String,
        sellingPrice: (row['selling_price'] as num).toDouble(),
        unitCost: (row['unit_cost'] as num).toDouble(),
        stockQuantity: row['stock_quantity'] as int,
        expirationDate: DateTime.parse(row['expiration_date'] as String),
        season: row['season'] as String,
      );
    }).toList();
  }

  Future<void> insertCategory(String name) async {
    final db = await database;
    final category = name.trim();

    if (category.isEmpty) return;

    await db.insert('categories', {
      'name': category,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<String>> getCategories() async {
    final db = await database;

    final rows = await db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map((row) => row['name'] as String).toList();
  }

  Map<String, Object?> _productToMap(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'category': product.category,
      'selling_price': product.sellingPrice,
      'unit_cost': product.unitCost,
      'stock_quantity': product.stockQuantity,
      'expiration_date': product.expirationDate.toIso8601String(),
      'season': product.season,
    };
  }
}
