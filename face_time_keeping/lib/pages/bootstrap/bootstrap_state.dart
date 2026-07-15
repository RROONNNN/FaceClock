import '../../common/enums/request_status.dart';

enum BootstrapStatus { initial, authenticated, unauthenticated }

class BootstrapState {
  final BootstrapStatus status;
  final RequestStatus requestStatus;
  final String? cachedDomain;
  final String? loginID;
  final String? password;
  const BootstrapState({
    this.status = BootstrapStatus.initial,
    this.requestStatus = RequestStatus.initial,
    this.cachedDomain,
    this.loginID,
    this.password,
  });

  BootstrapState copyWith({
    BootstrapStatus? status,
    RequestStatus? requestStatus,
    String? cachedDomain,
    String? loginID,
    String? password,
  }) {
    return BootstrapState(
      status: status ?? BootstrapStatus.initial,
      requestStatus: requestStatus ?? RequestStatus.initial,
      cachedDomain: cachedDomain ?? this.cachedDomain,
      loginID: loginID ?? this.loginID,
      password: password ?? this.password,
    );
  }
}
