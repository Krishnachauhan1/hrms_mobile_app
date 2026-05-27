import 'package:employee_app/app_color.dart';
import 'package:employee_app/hr_flow/controller/employee_detail_controller.dart';
import 'package:employee_app/hr_flow/models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EmployeeDetailsView extends GetView<EmployeeDetailsController> {
  const EmployeeDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final employee = controller.employee;

    if (employee == null) {
      return const Scaffold(body: Center(child: Text('No Employee Data')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Employee Details')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(employee),
            _currentLocationTop(),
            const SizedBox(height: 6),
            _card('Basic Info', [
              _row('Code', employee.employeeCode),
              _row('Department', employee.department),
              _row('Email', employee.email),
              _row('Phone', employee.phone),
            ]),
            _card('Salary', [
              _row(
                'Monthly',
                '₹ ${NumberFormat('#,##,###').format(employee.salary)}',
              ),
              _row(
                'Yearly',
                '₹ ${NumberFormat('#,##,###').format(employee.salary * 12)}',
              ),
            ]),
            _card('Leave', [
              _row('Total', employee.totalLeaves.toString()),
              _row('Used', employee.usedLeaves.toString()),
              _row('Remaining', employee.remainingLeaves.toString()),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: employee.usedLeaves / employee.totalLeaves,
              ),
            ]),
            _card('Login', [
              _row('Status', employee.isLoggedIn ? 'Logged In' : 'Logged Out'),
              if (employee.lastLoginTime != null)
                _row(
                  'Last Login',
                  DateFormat('dd MMM yyyy hh:mm a')
                      .format(employee.lastLoginTime!),
                ),
            ]),
            _card('Contact', [
              _row('Address', employee.address),
              _row('Emergency', employee.emergencyContact),
            ]),
          ],
        ),
      ),
    );
  }

  /// Current location — sabse upar, auto refresh har 10 min
  Widget _currentLocationTop() {
    return GetBuilder<EmployeeDetailsController>(
      builder: (c) {
        final lat = c.latitude;
        final lng = c.longitude;
        final lastAt = c.lastLocationAt;
        final lastText = lastAt == null
            ? '—'
            : DateFormat('dd MMM yyyy, hh:mm a').format(lastAt);

        final hasCoords = lat != null && lng != null;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Current Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      c.isLoadingLocation ? '...' : 'Auto refresh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                hasCoords
                    ? '${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}'
                    : (c.locationError ?? 'Waiting for employee location...'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Employee location time: $lastText',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              if (c.lastFetchedAt != null)
                Text(
                  'Admin fetched: ${DateFormat('hh:mm a').format(c.lastFetchedAt!)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: c.isLoadingLocation ? null : c.fetchLatestLocation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh now'),
                ),
              ),
              if (c.locationHistory.length > 1) ...[
                const SizedBox(height: 12),
                const Text(
                  'Recent updates (newest first)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ...c.locationHistory.take(5).map((item) {
                  final t = item['created_at'] ?? item['updated_at'];
                  final time = t != null
                      ? DateFormat('dd MMM, hh:mm a')
                          .format(DateTime.parse(t.toString()).toLocal())
                      : '—';
                  final la = item['latitude'];
                  final ln = item['longitude'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$time — $la, $ln',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _header(Employee employee) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
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
    );
  }

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

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'On Leave':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
