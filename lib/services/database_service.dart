import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/employee.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'employee_database.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        emp_id TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        gender TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        last_modified TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');
  }

  // Insert employee
  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    final employeeWithTimestamp = employee.copyWith(lastModified: DateTime.now(), isSynced: false);
    return await db.insert('employees', employeeWithTimestamp.toMap());
  }

  // Get all employees
  Future<List<Employee>> getAllEmployees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('employees', where: 'is_deleted = ?', whereArgs: [0]);
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  // Get unsynced employees
  Future<List<Employee>> getUnsyncedEmployees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('employees', where: 'is_synced = ?', whereArgs: [0]);
    return List.generate(maps.length, (i) => Employee.fromMap(maps[i]));
  }

  // Update employee
  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    final employeeWithTimestamp = employee.copyWith(lastModified: DateTime.now(), isSynced: false);
    return await db.update('employees', employeeWithTimestamp.toMap(), where: 'id = ?', whereArgs: [employee.id]);
  }

  // Delete employee (soft delete)
  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.update(
      'employees',
      {'is_deleted': 1, 'is_synced': 0, 'last_modified': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mark employee as synced
  Future<int> markAsSynced(int id) async {
    final db = await database;
    return await db.update('employees', {'is_synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // Check if employee ID exists
  Future<bool> employeeIdExists(String empId) async {
    final db = await database;
    final result = await db.query('employees', where: 'emp_id = ? AND is_deleted = ?', whereArgs: [empId, 0]);
    return result.isNotEmpty;
  }

  // Get employee by ID
  Future<Employee?> getEmployeeById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'id = ? AND is_deleted = ?',
      whereArgs: [id, 0],
    );
    if (maps.isNotEmpty) {
      return Employee.fromMap(maps.first);
    }
    return null;
  }

  // Get employee by employee ID
  Future<Employee?> getEmployeeByEmpId(String empId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'emp_id = ? AND is_deleted = ?',
      whereArgs: [empId, 0],
    );
    if (maps.isNotEmpty) {
      return Employee.fromMap(maps.first);
    }
    return null;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
