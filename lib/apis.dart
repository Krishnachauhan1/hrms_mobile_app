class Apis {
  static const String baseUrl = 'https://hrmsapi.nextlogicsolution.id/api';

  //empoyee login endpoint
  static const String login = '/login';
  static const String logout = '/logout';

  //employee attendance
  static const String attendanceLogin = '/attendance/login';
  static const String attendanceLogout = '/attendance/logout';
  static const String attendanceToday = '/employees-attendance/today';
  static const String attendanceMonthly = '/attendance/monthly';
  static const String attendanceTotal = '/attendance/total';
  static String attendanceStatus(int employeeId) =>
      '/employees/$employeeId/attendance-status';

  static String attendanceHistory(int employeeId) =>
      '/attendance/history?employee_id=$employeeId';

  //employee leave
  static const String leaveTypes = '/leave-types';
  static const String leaveApplications = '/leave-applications';
  static String leaveApplicationStatus(String id) =>
      '/leave-applications/$id/status';

  //salary
  static String employeeSalary(int employeeId) =>
      '/employees/$employeeId/salary';
}
