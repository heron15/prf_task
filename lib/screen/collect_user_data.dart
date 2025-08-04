import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import 'employee_list_screen.dart';

class CollectUserData extends StatefulWidget {
  final Employee? employeeToEdit;

  const CollectUserData({super.key, this.employeeToEdit});

  @override
  State<CollectUserData> createState() => _CollectUserDataState();
}

class _CollectUserDataState extends State<CollectUserData> {
  final _formKey = GlobalKey<FormState>();
  final _empIdController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedGender = 'Male';
  DateTime? _selectedDate;

  final DatabaseService _databaseService = DatabaseService();
  final SyncService _syncService = SyncService();

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.employeeToEdit != null;
    if (_isEditing) {
      _empIdController.text = widget.employeeToEdit!.empId;
      _nameController.text = widget.employeeToEdit!.name;
      _selectedGender = widget.employeeToEdit!.gender;
      _selectedDate = widget.employeeToEdit!.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _empIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date of birth')));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final employee = Employee(
        id: _isEditing ? widget.employeeToEdit!.id : null,
        empId: _empIdController.text.trim(),
        name: _nameController.text.trim(),
        gender: _selectedGender,
        dateOfBirth: _selectedDate!,
      );

      if (_isEditing) {
        await _databaseService.updateEmployee(employee);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee updated successfully')));
        }
      } else {
        await _databaseService.insertEmployee(employee);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee added successfully')));
        }
      }

      // Try to sync data
      await _syncService.syncData();

      // Navigate back to list
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EmployeeListScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(_isEditing ? 'Edit Employee' : 'Add Employee'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _syncService.syncData();
              setState(() {
                _isLoading = false;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_syncService.getStatusMessage())));
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Employee ID Field
                    TextFormField(
                      controller: _empIdController,
                      decoration: const InputDecoration(
                        labelText: 'Employee ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      enabled: !_isEditing,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter employee ID';
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                          return 'Employee ID must be numeric';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter employee name';
                        }
                        if (value.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender Selection
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth Field
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate == null ? 'Select Date' : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _saveEmployee,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isEditing ? 'Update Employee' : 'Save Employee',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // View All Employees Button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeListScreen()));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('View All Employees', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
