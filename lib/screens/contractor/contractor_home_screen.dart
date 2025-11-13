import 'package:assetarchiverflutter/models/employee_model.dart';
import 'package:flutter/material.dart';

// This is just a placeholder screen so your app can compile.
// We can design this later.
class ContractorHomeScreen extends StatelessWidget {
  final Employee employee;
  const ContractorHomeScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contractor Dashboard'),
      ),
      body: Center(
        child: Text('Welcome, Contractor ${employee.displayName}!'),
      ),
    );
  }
}