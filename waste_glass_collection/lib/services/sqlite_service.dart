import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:waste_glass_collection/models/collection_record_model.dart';

class SqliteService {
  static final SqliteService _instance = SqliteService._internal();
  factory SqliteService() => _instance;
  SqliteService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'waste_glass.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collections (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            supplier_id TEXT    NOT NULL,
            clear_kg    REAL    NOT NULL,
            coloured_kg REAL    NOT NULL,
            condition   TEXT    NOT NULL,
            timestamp   TEXT    NOT NULL,
            synced      INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<void> insertCollection(CollectionRecord record) async {
    final db = await database;
    await db.insert('collections', record.toMap());
  }

  Future<List<CollectionRecord>> getAllCollections() async {
    final db   = await database;
    final maps = await db.query('collections');
    return maps.map((m) => CollectionRecord.fromMap(m)).toList();
  }

  Future<List<CollectionRecord>> getUnsyncedCollections() async {
    final db   = await database;
    final maps = await db.query(
      'collections',
      where:     'synced = ?',
      whereArgs: [0],
    );
    return maps.map((m) => CollectionRecord.fromMap(m)).toList();
  }

  Future<void> markSynced(int localId) async {
    final db = await database;
    await db.update(
      'collections',
      {'synced': 1},
      where:     'id = ?',
      whereArgs: [localId],
    );
  }
}