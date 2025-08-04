import 'package:flutter/material.dart';
import '../widgets/sync_status_widget.dart';
import 'employee_list_screen.dart';
import 'collect_user_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.green, title: const Text('Employee Management System'), elevation: 2),
      body: Column(
        children: [
          const SyncStatusWidget(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 100, color: Colors.green),
                  const SizedBox(height: 24),
                  const Text(
                    'Employee Management',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Manage your employee data with offline support and automatic synchronization',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const EmployeeListScreen()));
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('View All Employees', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CollectUserData()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Employee', style: TextStyle(fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
