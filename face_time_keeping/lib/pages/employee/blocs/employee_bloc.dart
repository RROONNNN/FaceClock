import 'dart:developer';

import 'package:face_time_keeping/common/utils/extensions/string_extension.dart';
import 'package:face_time_keeping/common/utils/log_util.dart';
import 'package:face_time_keeping/data/remote/user_service.dart';
import 'package:face_time_keeping/entities/employee.dart';
import 'package:face_time_keeping/entities/register_employee.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../common/api_client/data_state.dart';
import '../../../common/event/event_bus_mixin.dart';
import '../../widgets/content_widget.dart';
import '../helper/event.dart';
import 'employee_state.dart';

@Injectable()
class EmployeeBloc extends Cubit<EmployeeState> with EventBusMixin {
  EmployeeBloc(this._userRepository) : super(const EmployeeState()) {
    listenEvent<DidChangeEmployeeEvent>((e) => _didUpdateEmp(e.employee));
  }

  final UserService _userRepository;
  List<Employee> _savedEmployees = [];

  void init() {
    _fetchEmployees();
  }

  void _didUpdateEmp(Employee? emp) {
    final List<Employee> newValues = List.from(state.employees ?? []);
    final index = newValues.indexWhere((element) => element.id == emp?.id);
    if (index >= 0) {
      newValues[index] = emp!;
      emit(state.copyWith(employees: newValues));
    }
  }

  Future<void> onRefresh() async {
    emit(state.copyWith(status: DataSourceStatus.refreshing));
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      final DataState<List<Employee>> result =
          await _userRepository.getEmployees();
      if (result.isSuccess) {
        _savedEmployees = result.data ?? [];
        emit(state.copyWith(
            employees: result.data,
            status: (result.data ?? []).isEmpty
                ? DataSourceStatus.empty
                : DataSourceStatus.success));
      } else {
        emit(state.copyWith(status: DataSourceStatus.failed));
      }
    } catch (e) {
      await pushLog('Error in fetchEmployees: $e');
      emit(state.copyWith(status: DataSourceStatus.failed));
    }
  }

  void onSearch(String? text) {
    if (text?.isEmpty ?? true) {
      emit(state.copyWith(employees: _savedEmployees));
      return;
    }
    final textLower = text!.removeVietnameseDiacritics().toLowerCase();
    log('textLower: $textLower');
    final results = List<Employee>.from(_savedEmployees)
        .where((element) => element.name
            .removeVietnameseDiacritics()
            .contains(text!.removeVietnameseDiacritics()))
        .toList();
    emit(state.copyWith(employees: results));
  }

  Future<void> onRegisterEmployee(RegisterEmployee registerEmployee) async {
    final DataState<Employee> result =
        await _userRepository.registerEmployee(registerEmployee);
    if (result.isSuccess) {
      final List<Employee> newValues = List.from(state.employees ?? []);
      newValues.add(result.data!);
      emit(state.copyWith(
          employees: newValues, status: DataSourceStatus.success));
    } else {
      emit(state.copyWith(
          status: DataSourceStatus.failed,
          error: result.error,
          employees: state.employees));
    }
  }
}
