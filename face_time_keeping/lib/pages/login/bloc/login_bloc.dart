import 'dart:io';

import 'package:face_native/face_native.dart';
import 'package:face_time_keeping/common/api_client/data_state.dart';
import 'package:face_time_keeping/common/enums/request_status.dart';
import 'package:face_time_keeping/common/utils/log_util.dart';
import 'package:face_time_keeping/data/local/hive_service.dart';
import 'package:face_time_keeping/data/local/local_service.dart';
import 'package:face_time_keeping/data/remote/authentication/login_request.dart';
import 'package:face_time_keeping/data/remote/authentication_service.dart';
import 'package:face_time_keeping/di/injection.dart';
import 'package:face_time_keeping/pages/login/bloc/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@Injectable()
class LoginBloc extends Cubit<LoginState> {
  LoginBloc(this._authenticationService, this._localService)
      : super(LoginState());
  final AuthenticationService _authenticationService;
  final LocalService _localService;
  void onChangeUsername(String? value) {
    emit(state.copyWith(username: value));
  }

  void onChangePass(String? value) {
    emit(state.copyWith(password: value));
  }

  int extractUserId(Map<String, dynamic> decoded) {
    // final Map<String, dynamic> decoded = json.decode(jsonString);
    return decoded['user_settings']['user_id']['id'] as int;
  }

  Future<void> onLogin() async {
    try {
      emit(state.copyWith(requestStatus: RequestStatus.requesting));
      final database = await _localService.getDbName();
      if (database.isEmpty ||
          state.username == null ||
          state.password == null) {
        emit(state.copyWith(
            requestStatus: RequestStatus.failed,
            message: "Vui lòng nhập đầy đủ thông tin"));
        return;
      }
      final userId = await _authenticationService.authenticateDatabase(
          state.username!, state.password!, database);
      if (userId.isSuccess) {
        _localService.saveUserId(userId.data!);
      } else {
        emit(state.copyWith(
            requestStatus: RequestStatus.failed, message: userId.error));
        return;
      }
      final result = await _authenticationService.login(LoginRequest(
          username: state.username,
          password: state.password,
          database: database));
      if (result.isSuccess) {
        _localService.saveToken(result.data?.token);
        _localService.saveLoginId(state.username);
        final tenantId = await _localService.getTenantIdOrSaveTenant(
            _localService.getDomain(), database);
        _localService.saveTenantId(tenantId);
        // if platform == android
        if (Platform.isAndroid) {
          await FaceNative().initObjectBox(tenantId.toString());
        }
        await getIt<HiveService>().init(tenantId.toString());
        emit(state.copyWith(requestStatus: RequestStatus.success));
      } else {
        emit(state.copyWith(
            requestStatus: RequestStatus.failed, message: result.error));
      }
    } catch (e) {
      await pushLog('Error in onLogin: $e');
      emit(state.copyWith(requestStatus: RequestStatus.failed));
    }
  }
}
