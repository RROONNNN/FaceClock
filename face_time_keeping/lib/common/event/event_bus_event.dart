import 'package:face_time_keeping/data/models/logging_model.dart';

bool showLogout = false;

class LogoutEvent {
  String? message;

  LogoutEvent({
    this.message,
  });
}

class NetworkStatusChangeEvent {
  NetworkStatusChangeEvent({this.status = true});
  final bool status;
}

class LoggingEvent {
  LoggingEvent({required this.apiInfo});
  final ApiInfo apiInfo;
}

class SyncDataEvent {}
