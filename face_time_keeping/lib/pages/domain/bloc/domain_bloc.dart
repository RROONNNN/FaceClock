import 'package:face_time_keeping/data/remote/authentication_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../configs/build_config.dart';
import '../../../data/local/local_service.dart';
import '../../../di/injection.dart';
import 'domain_state.dart';

@injectable
class DomainBloc extends Cubit<DomainState> {
  DomainBloc(
    this._localService,
  ) : super(const DomainState());

  final LocalService _localService;
  final BuildConfig buildConfig = getIt<BuildConfig>();
  final AuthenticationService _authenticationService = getIt<AuthenticationService>();

  @override
  void emit(DomainState state) {
    if (isClosed) {
      return;
    }
    super.emit(state);
  }

  void onChangedDomain(String domain) {
    emit(state.copyWith(domain: domain));
  }



  void _saveDomain(String domain) {
    final newDomain = domain.replaceAll('https://', '');
    String url = "https://$newDomain";
    if (newDomain.isNotEmpty) {
      _localService.saveDomain(url);
      buildConfig.setBaseUrl(url);
      emit(state.copyWith(cachedDomain: url));
          _authenticationService.getDatabaseList().then((value) {
      if (value.error == null) {
        if (value.data == null||value.data!.isEmpty) {
         emit(state.copyWith(message: 'Không tìm thấy database'));
         return;
        }
         emit(state.copyWith(dbNames: value.data!));
      }
    });
    } else {
      _localService.saveDomain("");
      buildConfig.setBaseUrl("");
      emit(state.copyWith(cachedDomain: ''));
    }
  }



  void onChangedAutoLogin(bool? value) {
    emit(state.copyWith(autoLogin: value));
  }

  void initDomain() {
    final String domain = _localService.getDomain();
    buildConfig.setBaseUrl(domain);
    emit(state.copyWith(
      cachedDomain: domain, 
      domain: domain,
    ));
  }

  void onAccessDomain() {
    _saveDomain(state.domain ?? '');
    _localService.saveToken('');

  }
}
