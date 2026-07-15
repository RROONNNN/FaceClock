import 'package:face_time_keeping/pages/bloc/app_state.dart';
import 'package:face_time_keeping/pages/widgets/license_key_popup.dart';
import 'package:face_time_keeping/route/app_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:new_version_plus/new_version_plus.dart';

import 'common/resources/index.dart';
import 'configs/build_config.dart';
import 'data/local/hive_service.dart';
import 'di/injection.dart';
import 'localization/generated/l10n.dart';
import 'pages/bloc/app_bloc.dart';
import 'route/navigator.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppBloc _appBloc = getIt<AppBloc>();
  final HiveService _hiveService = getIt<HiveService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAppUpdate();
    });
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Future.delayed(const Duration(seconds: 5), () {
        _appBloc.loadLicenseExpiredDate();
      });
    });
  }

  Future<void> _checkForAppUpdate() async {
    try {
      final newVersion = NewVersionPlus();
      await newVersion.showAlertIfNecessary(context: context);
    } catch (e) {
      debugPrint('Error checking for app update: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hiveService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _configOrientation(context);
    return BlocProvider<AppBloc>(
      create: (_) => _appBloc,
      child: MaterialApp(
        title: getIt<BuildConfig>().kDefaultAppName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: AppColors.primaryColor,
        ),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback:
            (Locale? locale, Iterable<Locale> supportedLocales) {
          for (final Locale supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        navigatorKey: AppNavigator.navigatorKey,
        onGenerateRoute: AppRoutes.onGenerateRoutes,
        builder: (context, child) {
          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              _appBloc.checkLicenseExpired();
            },
            child: BlocListener<AppBloc, AppState>(
              listener: (context, state) {
                if (state.appStatus == AppStatus.wrong_time_local) {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text('Wrong Time Local'),
                      content: Text('Please check your time and try again'),
                    ),
                  );
                }
                if (state.appStatus == AppStatus.license_expired) {
                  final ctx =
                      AppNavigator.navigatorKey.currentContext ?? context;
                  LicenseKeyPopup.show(ctx);
                }
              },
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _configOrientation(BuildContext context) {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
  }
}
