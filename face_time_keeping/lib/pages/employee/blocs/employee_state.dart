import 'package:face_time_keeping/entities/employee.dart';

import '../../widgets/content_widget.dart';

class EmployeeState {
  final List<Employee>? employees;
  final DataSourceStatus status;
  final String? error;
  const EmployeeState({
    this.employees,
    this.status = DataSourceStatus.initial,
    this.error,
  });

  EmployeeState copyWith({
    List<Employee>? employees,
    DataSourceStatus? status,
    String? error,
  }) {
    return EmployeeState(
      employees: employees ?? this.employees,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}
