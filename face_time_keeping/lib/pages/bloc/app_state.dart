import 'package:face_time_keeping/common/utils/location_util.dart';
import 'package:geolocator/geolocator.dart';

enum AppStatus {
  license_valid,
  license_expired,
  license_not_registered,
  wrong_time_local,
}

class AppState {
  final AppStatus appStatus;
  final DateTime? licenseExpiredDate;

  final Position? position;
  const AppState({
    this.appStatus = AppStatus.license_not_registered,
    this.licenseExpiredDate,
    this.position,
  });
  AppState copyWith({
    AppStatus? appStatus,
    DateTime? licenseExpiredDate,
    Position? position,
    LocationPermissionStatus? locationPermissionStatus,
  }) {
    return AppState(
      appStatus: appStatus ?? this.appStatus,
      licenseExpiredDate: licenseExpiredDate ?? this.licenseExpiredDate,
      position: position ?? this.position,
    );
  }
}
