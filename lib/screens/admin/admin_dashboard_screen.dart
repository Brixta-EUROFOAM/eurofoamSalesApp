import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';

// This is just a placeholder screen so your app can compile.
// We can design this later.
class AdminDashboardScreen extends StatelessWidget {
  final Employee employee;
  const AdminDashboardScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Center(
        child: Text('Welcome, Admin ${employee.displayName}!'),
      ),
    );
  }
}