import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:face_time_keeping/common/utils/log_util.dart';
import 'package:face_time_keeping/data/local/local_service.dart';
import 'package:face_time_keeping/di/injection.dart';

import 'package:face_time_keeping/entities/employee.dart';
import 'package:face_time_keeping/entities/face_data.dart';
import 'package:face_time_keeping/entities/register_employee.dart';
import 'package:face_time_keeping/entities/sync_response.dart';
import 'package:flutter/material.dart';

import 'package:injectable/injectable.dart';

import '../../common/api_client/api_client.dart';
import '../../common/api_client/api_response.dart';
import '../../common/api_client/data_state.dart';
import 'api_endpoint.dart';
import 'package:http/http.dart' as http;

abstract class UserService {
  Future<DataState<List<Employee>>> getEmployees();
  Future<DataState<bool>> syncCheckInOutData({String? url});
  Future<DateTime> fetchWorldTime({String timezone = 'Etc/UTC'});
  Future<DataState<Employee>> registerEmployee(
      RegisterEmployee registerEmployee);
  Future<void> testFunction();
  Future<DataState<String>> pushFaceData({String? url});
  Future<DataState<String>> pullFaceData({String? url});
}

@LazySingleton(as: UserService)
class UserServiceImplement implements UserService {
  UserServiceImplement(this._apiClient, this._localService);

  final ApiClient _apiClient;
  final LocalService _localService;

  @override
  Future<void> testFunction() async {
    try {
      final response =
          await _apiClient.get(path: "/web/content/411?download=true");
      if (response.isSuccess()) {
        return response.data;
      }
    } catch (e) {
      await pushLog('Error in testFunction: $e');
    }
  }

  @override
  Future<DataState<String>> pullFaceData({String? url}) async {
    try {
      final DateTime? latestTime =
          await _localService.getLatestTimePullFaceData();
      final Map<String, dynamic> queryParameters = {};
      if (latestTime != null) {
        queryParameters['from_date'] =
            latestTime.toIso8601String().split('.').first;
      }
      final response = await getIt<Dio>().request<dynamic>(
          url != null
              ? '$url${ApiEndpoint.pullFaceData}'
              : ApiEndpoint.pullFaceData,
          queryParameters: queryParameters,
          options: Options(
            method: 'GET',
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          ));
      final data = response.data as List<dynamic>;
      if (data.isNotEmpty) {
        final now = DateTime.now();
        final faceDataList = data.map((e) => FaceData.fromJson(e)).toList();
        await _localService.importFaceData(faceDataList);
        await _localService.saveLatestTimePullFaceData(now);
      }
      return DataSuccess<String>(
          response.statusMessage ?? 'Cập nhật dữ liệu thành công');
    } catch (e) {
      await pushLog('Error in pullFaceData: $e');
      return DataFailed<String>(e.toString());
    }
  }

  @override
  Future<DataState<String>> pushFaceData({String? url}) async {
    try {
      final newPersons = await _localService.getPersonsUnSynced();
      if (newPersons.isEmpty) {
        return const DataSuccess<String>('Không có dữ liệu để đồng bộ');
      }
      final listPushedPersonIds = newPersons.map((e) => e.employeeId).toList();
      final file =
          await _localService.exportModelToJsonFile(persons: newPersons);
      final multiPartFile = await MultipartFile.fromFile(file.path,
          filename: file.uri.pathSegments.last);
      final formData = FormData.fromMap({
        'file': multiPartFile,
      });
      final response = await _apiClient.put(
        path: url != null
            ? '$url${ApiEndpoint.pushFaceData}'
            : ApiEndpoint.pushFaceData,
        data: formData,
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      );
      debugPrint('response: ${response.data}');
      if (response.isSuccess()) {
        final listSkippedPersonIds =
            response.data['data']['skipped'] as List<dynamic>? ?? [];
        final listSkippedPersonIdsInt =
            listSkippedPersonIds.map((e) => e as int).toList();
        for (final personId in listPushedPersonIds) {
          if (!listSkippedPersonIdsInt.contains(personId)) {
            await _localService.setPersonSynced(personId);
          }
        }
        return DataSuccess<String>(response.data['message']);
      }
      return DataFailed<String>(response.error);
    } catch (e) {
      await pushLog('Error in pushFaceData: $e');
      return DataFailed<String>(e.toString());
    }
  }

  @override
  Future<DateTime> fetchWorldTime({String timezone = 'Etc/UTC'}) async {
    try {
      final res = await http
          .get(Uri.parse('https://worldtimeapi.org/api/timezone/$timezone'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return DateTime.parse(data['utc_datetime']);
      }
    } catch (e) {
      await pushLog('Error in fetchWorldTime: $e');
    }
    return DateTime.now();
  }

  @override
  Future<DataState<Employee>> registerEmployee(
      RegisterEmployee registerEmployee) async {
    try {
      final json = await registerEmployee.toJson();
      FormData formData = FormData.fromMap(json);

      final ApiResponse response = await _apiClient.post(
        path: ApiEndpoint.registerEmployee,
        data: formData,
        // headers: {
        //   'Content-Type': 'multipart/form-data',
        // },
      );

      if (response.isSuccess()) {
        final employeeData = response.data as Map<String, dynamic>;
        final employee = Employee.fromJson(employeeData['data']);
        return DataSuccess<Employee>(employee);
      } else {
        return DataFailed<Employee>(response.error ?? 'Registration failed');
      }
    } catch (e) {
      await pushLog('Error in registerEmployee: $e');
      return DataFailed<Employee>(e.toString());
    }
  }

  @override
  Future<DataState<bool>> syncCheckInOutData({String? url}) async {
    try {
      final bulkUsers = await _localService.getBulkUsers();
      if (bulkUsers == null || bulkUsers.isEmpty) {
        return const DataFailed<bool>('Không còn dữ liệu để đồng bộ');
      }
      // Format the payload according to the required structure
      final List<Map<String, dynamic>> bulkUsersPayload = bulkUsers
          .map((bulkUser) => {
                'employee_id': bulkUser.employeeId,
                'io': bulkUser.checkInOuts
                    .map((checkInOut) => checkInOut.toSmallJson())
                    .toList(),
              })
          .toList();

      final Map<String, dynamic> requestPayload = {
        'bulk_users': bulkUsersPayload,
      };
      // final encode = jsonEncode(requestPayload);
      // Make the API call
      ApiResponse response;
      if (url != null) {
        response = await _apiClient.post(
          path: '$url${ApiEndpoint.syncCheckInOutData}',
          data: requestPayload,
        );
      } else {
        response = await _apiClient.post(
          path: ApiEndpoint.syncCheckInOutData,
          data: requestPayload,
        );
      }

      if (response.isSuccess()) {
        debugPrint('Sync completed successfully: ${response.data}');
        final responseData = response.data as Map<String, dynamic>;
        final dataList = responseData['data'] as List<dynamic>;
        final data = dataList.cast<Map<String, dynamic>>();

        for (final item in data) {
          final syncResponse = SyncResponse.fromJson(item);
          if (syncResponse.success) {
            debugPrint('Sync completed successfully: ${syncResponse.message}');
            await _localService.handleSyncResponse(syncResponse);
          } else {
            debugPrint('Sync failed for item: ${syncResponse.message}');
          }
        }
        return const DataSuccess<bool>(true);
      } else {
        debugPrint('Sync failed: ${response.error}');
        return DataFailed<bool>(response.error);
      }
    } on DioError catch (e) {
      await pushLog('Error in syncCheckInOutData: $e');
      debugPrint('Dio error during sync: ${e.message}');
      return DataFailed<bool>(e.message);
    } catch (e) {
      await pushLog('Error in syncCheckInOutData: $e');
      debugPrint('General error during sync: $e');
      return DataFailed<bool>(e.toString());
    }
  }

  @override
  Future<DataState<List<Employee>>> getEmployees() async {
    try {
      final ApiResponse response =
          await _apiClient.get(path: ApiEndpoint.employees);
      if (response.isSuccess()) {
        final json = response.data;
        debugPrint('json: $json');
        final realData = json['data'];
        final employeesData = realData['employees'] as List<dynamic>;
        final employees =
            employeesData.map((e) => Employee.fromJson(e)).toList();
        return DataSuccess<List<Employee>>(employees);
      }
      return DataFailed<List<Employee>>(response.error);
    } on DioError catch (e) {
      await pushLog('Error in getEmployees: $e');
      return DataFailed<List<Employee>>(e.message);
    } catch (e, stackTrace) {
      await pushLog('Error in getEmployees: $e');
      debugPrint('General error in getEmployees: $e\n$stackTrace');
      return DataFailed<List<Employee>>(e.toString());
    }
  }

  // @override
  // Future<DataState<Employee>> getEmployee(String code) async {
  //   try {
  //     final ApiResponse response = await _apiClient.get(
  //       path: '${ApiEndpoint.employee}/$code',
  //     );
  //     if (response.isSuccess()) {
  //       return DataSuccess<Employee>(Employee.fromJson(response.data));
  //     }
  //     return DataFailed<Employee>(response.error);
  //   } on DioError catch (e) {
  //     await pushLog('Error in getEmployee: $e');
  //     return DataFailed<Employee>(e.message);
  //   } on Exception catch (e) {
  //     await pushLog('Error in getEmployee: $e');
  //     return DataFailed<Employee>(e.toString());
  //   }
  // }
}
