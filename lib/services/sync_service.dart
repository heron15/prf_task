import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/employee.dart';
import 'database_service.dart';

enum SyncStatus { idle, syncing, success, error, offline }

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Server configuration
  static const String _baseUrl = 'http://203.76.113.66';
  static const String _database = 'dbEmp1';
  static const String _userId = 'test1';
  static const String _password = 'test12345';
  static const String _tableName = 'dbo.tbl_emp';

  SyncStatus _syncStatus = SyncStatus.idle;
  String _lastError = '';
  final List<String> _pendingRequests = [];

  SyncStatus get syncStatus => _syncStatus;
  String get lastError => _lastError;
  List<String> get pendingRequests => List.unmodifiable(_pendingRequests);

  // Check internet connectivity
  Future<bool> _isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Perform sync operation
  Future<void> syncData() async {
    if (!await _isConnected()) {
      _syncStatus = SyncStatus.offline;
      _lastError = 'No internet connection';
      return;
    }

    _syncStatus = SyncStatus.syncing;
    _lastError = '';

    try {
      // Get unsynced employees
      final unsyncedEmployees = await _databaseService.getUnsyncedEmployees();

      if (unsyncedEmployees.isEmpty) {
        _syncStatus = SyncStatus.success;
        return;
      }

      // Sync each employee
      for (final employee in unsyncedEmployees) {
        await _syncEmployee(employee);
      }

      _syncStatus = SyncStatus.success;
    } catch (e) {
      _syncStatus = SyncStatus.error;
      _lastError = e.toString();
    }
  }

  // Sync individual employee
  Future<void> _syncEmployee(Employee employee) async {
    try {
      if (employee.isDeleted) {
        // Handle deletion
        await _deleteEmployeeFromServer(employee);
      } else {
        // Check if employee exists on server
        final serverEmployee = await _getEmployeeFromServer(employee.empId);

        if (serverEmployee != null) {
          // Handle conflict resolution
          await _resolveConflict(employee, serverEmployee);
        } else {
          // Insert new employee
          await _insertEmployeeToServer(employee);
        }
      }

      // Mark as synced
      await _databaseService.markAsSynced(employee.id!);
    } catch (e) {
      // Add to pending requests for retry
      _pendingRequests.add(
        jsonEncode({
          'action': employee.isDeleted ? 'delete' : 'upsert',
          'employee': employee.toMap(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      throw e;
    }
  }

  // Insert employee to server
  Future<void> _insertEmployeeToServer(Employee employee) async {
    final url = Uri.parse('$_baseUrl/api/employees');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_userId:$_password'))}',
      },
      body: jsonEncode(employee.toServerMap()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to insert employee: ${response.body}');
    }
  }

  // Update employee on server
  Future<void> _updateEmployeeOnServer(Employee employee) async {
    final url = Uri.parse('$_baseUrl/api/employees/${employee.empId}');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('$_userId:$_password'))}',
      },
      body: jsonEncode(employee.toServerMap()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update employee: ${response.body}');
    }
  }

  // Delete employee from server
  Future<void> _deleteEmployeeFromServer(Employee employee) async {
    final url = Uri.parse('$_baseUrl/api/employees/${employee.empId}');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Basic ${base64Encode(utf8.encode('$_userId:$_password'))}'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete employee: ${response.body}');
    }
  }

  // Get employee from server
  Future<Map<String, dynamic>?> _getEmployeeFromServer(String empId) async {
    try {
      final url = Uri.parse('$_baseUrl/api/employees/$empId');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Basic ${base64Encode(utf8.encode('$_userId:$_password'))}'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get employee: ${response.body}');
      }
    } catch (e) {
      // If server is not reachable, assume employee doesn't exist
      rethrow;
    }
  }

  // Resolve conflicts between local and server data
  Future<void> _resolveConflict(Employee localEmployee, Map<String, dynamic> serverEmployee) async {
    // Simple conflict resolution: use the most recent modification
    final localModified = localEmployee.lastModified ?? DateTime.now();
    final serverModified = DateTime.parse(serverEmployee['last_modified'] ?? DateTime.now().toIso8601String());

    if (localModified.isAfter(serverModified)) {
      // Local changes are newer, update server
      await _updateEmployeeOnServer(localEmployee);
    } else {
      // Server changes are newer, update local
      final updatedEmployee = Employee(
        id: localEmployee.id,
        empId: serverEmployee['Emp_ID'].toString(),
        name: serverEmployee['Emp_name'],
        gender: serverEmployee['Emp_gender'],
        dateOfBirth: DateTime.parse(serverEmployee['Emp_DOB']),
        lastModified: serverModified,
        isSynced: true,
      );
      await _databaseService.updateEmployee(updatedEmployee);
    }
  }

  // Retry pending requests
  Future<void> retryPendingRequests() async {
    if (!await _isConnected()) {
      _syncStatus = SyncStatus.offline;
      return;
    }

    final requestsToRetry = List<String>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final requestJson in requestsToRetry) {
      try {
        final request = jsonDecode(requestJson);
        final employee = Employee.fromMap(request['employee']);

        if (request['action'] == 'delete') {
          await _deleteEmployeeFromServer(employee);
        } else {
          await _syncEmployee(employee);
        }
      } catch (e) {
        // Add back to pending requests if it fails
        _pendingRequests.add(requestJson);
      }
    }
  }

  // Get sync status message
  String getStatusMessage() {
    switch (_syncStatus) {
      case SyncStatus.idle:
        return 'Ready to sync';
      case SyncStatus.syncing:
        return 'Syncing data...';
      case SyncStatus.success:
        return 'Sync completed successfully';
      case SyncStatus.error:
        return 'Sync failed: $_lastError';
      case SyncStatus.offline:
        return 'Offline mode - changes will be synced when online';
    }
  }

  // Reset sync status
  void resetStatus() {
    _syncStatus = SyncStatus.idle;
    _lastError = '';
  }
}
