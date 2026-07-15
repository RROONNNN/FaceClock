import 'package:face_native/face_native.dart';
import 'package:face_time_keeping/common/utils/sync_jobs_util.dart';
import 'package:face_time_keeping/configs/build_config.dart';
import 'package:face_time_keeping/data/local/hive_service.dart';
import 'package:face_time_keeping/data/local/local_service.dart';
import 'package:face_time_keeping/di/injection.dart';
import 'package:face_time_keeping/entities/sync_face_schedule.dart';
import 'package:face_time_keeping/entities/sync_schedule.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../common/event/event_bus_mixin.dart';
import 'bootstrap_state.dart';

@LazySingleton()
class BootstrapCubit extends Cubit<BootstrapState> with EventBusMixin {
  BootstrapCubit(this._localService, this._buildConfig)
      : super(const BootstrapState(status: BootstrapStatus.initial));

  final LocalService _localService;
  final BuildConfig _buildConfig;

  @override
  void emit(BootstrapState state) {
    if (isClosed) {
      return;
    }
    super.emit(state);
  }

  Future<void> initData() async {
    final token = _localService.getToken();
    final domain = _localService.getDomain();
    if (domain.isNotEmpty) {
      _buildConfig.setBaseUrl(domain);
    }
    final dbName = await _localService.getDbName();
    if (dbName.isEmpty) {
      emit(state.copyWith(status: BootstrapStatus.unauthenticated));
      return;
    }
    final tenantId =
        await _localService.getTenantIdOrSaveTenant(domain, dbName);
    await _localService.saveTenantId(tenantId);
    await FaceNative().initObjectBox(tenantId.toString());
    await getIt<HiveService>().init(tenantId.toString());

    if (token.isEmpty) {
      emit(state.copyWith(status: BootstrapStatus.unauthenticated));
      return;
    }
    emit(state.copyWith(status: BootstrapStatus.authenticated));
  }
}
