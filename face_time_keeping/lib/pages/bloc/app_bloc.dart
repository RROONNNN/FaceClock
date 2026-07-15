import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:face_time_keeping/common/utils/location_util.dart';

import 'package:face_time_keeping/common/utils/rsa_util.dart';
import 'package:face_time_keeping/data/local/local_service.dart';

import 'package:face_time_keeping/di/injection.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:injectable/injectable.dart';

import '../../common/event/event_bus_mixin.dart';

import 'app_state.dart';

@Singleton()
class AppBloc extends Cubit<AppState> with EventBusMixin {
  late final Timer? _timer;
  AppBloc() : super(const AppState()) {
    _getCurrentPosition();
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _getCurrentPosition();
    });
  }

  Future<bool> isExpiredLicenseKey({String? li_Key}) async {
    try {
      final licenseKey = li_Key ?? await getIt<LocalService>().getLicenseKey();
      final rsaUtil = await RSAUtil.fromAsset(
          publicAssetPath: "assets/public.pem",
          privateAssetPath: "assets/private.pem");
      final encryptedLicenseKey = rsaUtil.decryptFromBase64(licenseKey);
      final decode = (encryptedLicenseKey is Map<String, dynamic>)
          ? encryptedLicenseKey
          : json.decode(encryptedLicenseKey);
      final licenseExpiredDate = DateTime.parse(decode['licenseExpiredDate']);
      return licenseExpiredDate.isBefore(DateTime.now());
    } catch (e) {
      emit(state.copyWith(appStatus: AppStatus.license_not_registered));
      return true;
    }
  }

  void _getCurrentPosition() async {
    try {
      final position = await LocationUtil.getCurrentPosition();
      emit(state.copyWith(position: position));
    } catch (e) {
      log('Lỗi khi lấy vị trí: $e');
    }
  }

  void loadLicenseExpiredDate() async {
    final isExpired = await isExpiredLicenseKey();
    if (isExpired) {
      emit(state.copyWith(appStatus: AppStatus.license_expired));
    } else {
      emit(state.copyWith(appStatus: AppStatus.license_valid));
    }
  }

  void checkLicenseExpired() async {
    EasyDebounce.debounce('my-debouncer', const Duration(seconds: 3), () async {
      //        final currentTime = await getIt<UserService>().fetchWorldTime();
      // final localTime = DateTime.now();
      // final difference = currentTime.difference(localTime).inMinutes.abs();
      // if (difference > 5) {
      //   emit(state.copyWith(appStatus: AppStatus.wrong_time_local));
      //   return;
      // }
      final isExpired = await isExpiredLicenseKey();
      if (isExpired) {
        emit(state.copyWith(appStatus: AppStatus.license_expired));
      } else {
        emit(state.copyWith(appStatus: AppStatus.license_valid));
      }
    });
  }
}
