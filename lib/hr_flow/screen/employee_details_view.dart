import 'package:employee_app/hr_flow/controller/employee_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmployeeDetailsView extends GetView<EmployeeDetailsController> {
  const EmployeeDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final employee = controller.employee;

    if (employee == null) {
      return const Scaffold(body: Center(child: Text("No Employee Data")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Employee Details")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// ✅ HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Text(
                      employee.name[0],
                      style: const TextStyle(fontSize: 25),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    employee.name,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),

                  Text(
                    employee.designation,
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 5),

                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(employee.status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      employee.status,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// ✅ BASIC INFO
            _card("Basic Info", [
              _row("Code", employee.employeeCode),
              _row("Department", employee.department),
              _row("Email", employee.email),
              _row("Phone", employee.phone),
            ]),

            /// ✅ SALARY
            _card("Salary", [
              _row(
                "Monthly",
                "₹ ${NumberFormat('#,##,###').format(employee.salary)}",
              ),
              _row(
                "Yearly",
                "₹ ${NumberFormat('#,##,###').format(employee.salary * 12)}",
              ),
            ]),

            /// ✅ LEAVE
            _card("Leave", [
              _row("Total", employee.totalLeaves.toString()),
              _row("Used", employee.usedLeaves.toString()),
              _row("Remaining", employee.remainingLeaves.toString()),

              const SizedBox(height: 10),

              LinearProgressIndicator(
                value: employee.usedLeaves / employee.totalLeaves,
              ),
            ]),

            /// ✅ LOGIN
            _card("Login", [
              _row("Status", employee.isLoggedIn ? "Logged In" : "Logged Out"),

              if (employee.lastLoginTime != null)
                _row(
                  "Last Login",
                  DateFormat(
                    "dd MMM yyyy hh:mm a",
                  ).format(employee.lastLoginTime!),
                ),
            ]),

            /// ✅ CONTACT
            _card("Contact", [
              _row("Address", employee.address),
              _row("Emergency", employee.emergencyContact),
            ]),
          ],
        ),
      ),
    );
  }

  /// CARD
  Widget _card(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  /// ROW
  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Active":
        return Colors.green;
      case "On Leave":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
