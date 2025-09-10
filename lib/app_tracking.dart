import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppTracking {
  static var _kTestingCrashlytics = true;
  //TODO: setup in main.dart, input MyApp parameter. You have to put WidgetsFlutterBinding.ensureInitialized(); before init
  static init(
      {required Widget myApp,
      required FirebaseOptions options,
      required bool testingCrashlytics}) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: options);
    }
    _kTestingCrashlytics = testingCrashlytics;
    // Crashlytics wiring
    if (!kIsWeb) {
      try {
        await _initCrashlytics();
      } catch (e, stack) {
        debugPrint('Error initializing Crashlytics: $e');
        debugPrintStack(stackTrace: stack);
      }
    }
    // Bắt lỗi async ngoài Flutter framework
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    dispatcher.onError = (Object error, StackTrace stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return false; // không chặn mặc định
    };
    // Chạy app trong runZonedGuarded để bắt các lỗi chưa bắt
    runZonedGuarded(() {
      runApp(myApp);
    }, (error, stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    });
  }

  static bool get _crashlyticsEnabled => _kTestingCrashlytics;

  static Future<void> _initCrashlytics() async {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(_crashlyticsEnabled);

    final original = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) async {
      // Forward cho Crashlytics
      await FirebaseCrashlytics.instance.recordFlutterError(details);
      // Gọi lại handler cũ để không nuốt log
      if (original != null) original(details);
    };
  }

  static Future<void> _logEvent(String name,
      {Map<String, Object>? parameters}) async {
    final fa = FirebaseAnalytics.instance;
    try {
      await fa.logEvent(name: name, parameters: parameters);
    } on PlatformException catch (_) {
      // Trường hợp hiếm khi engine chưa attach → thử lại sau frame
      await WidgetsBinding.instance.endOfFrame;
      await fa.logEvent(name: name, parameters: parameters);
    }
  }

  static Future<void> _logScreenView(String screenName) async {
    final fa = FirebaseAnalytics.instance;
    try {
      await fa.logScreenView(screenName: screenName);
    } on PlatformException catch (_) {
      // Trường hợp hiếm khi engine chưa attach → thử lại sau frame
      await WidgetsBinding.instance.endOfFrame;
      await fa.logScreenView(screenName: screenName);
    }
  }

  static trackingErrorAPI(
      {required String userId,
      required String fullName,
      required String uuid,
      required String url,
      required dynamic head,
      required dynamic params,
      required dynamic messageError}) async {
    dynamic log = params;
    String error = "";
    final fa = FirebaseAnalytics.instance;
    try {
      if (!(log is String)) {
        if (log.containsKey('password')) {
          log.remove('password');
        }
      }
      error = messageError.toString();
    } catch (e) {
      error = e.toString();
    }
    await _logEvent('api_tracking', parameters: {
      'url': url,
      'headers': head != null ? head.toString() : '',
      'params': params != null ? log.toString() : '',
      'error': error,
      'userId': userId,
      'fullName': fullName,
      'uuid': uuid,
    });
  }

  static trackingScreen(
      {required String screenName,
      required String userId,
      required String fullName,
      required String uuid}) async {
    await _logEvent('screen_tracking', parameters: {
      'screenName': screenName,
      'userId': userId,
      'fullName': fullName,
      'uuid': uuid,
    });
    await _logScreenView(screenName);
  }

  static trackingNotification(
      {required String userId,
      required String fullName,
      required dynamic params}) async {
    dynamic log = params;
    try {
      if (log is! String && (log as Map).containsKey('password')) {
        log.remove('password');
      }
    } catch (_) {}
    await _logEvent('notification_tracking', parameters: {
      'userId': userId,
      'fullName': fullName,
      'params': log.toString(),
    });
  }

  ///saleclub
  static trackingScreenSaleV2(
      {required String screenName,
      required String userId,
      required String fullName,
      required String uuid}) async {
    await _logEvent('screen_sale_v2_tracking', parameters: {
      'screenName': screenName,
      'userId': userId,
      'fullName': fullName,
      'uuid': uuid,
    });
    await _logScreenView(screenName);
  }

  ///saleclub
  static trackingErrorAPISaleV2(
      {required String userId,
      required String fullName,
      required String uuid,
      required String url,
      required dynamic head,
      required dynamic params,
      required dynamic messageError}) async {
    dynamic log = params;
    String error;
    try {
      if (log is! String && (log as Map).containsKey('password')) {
        log.remove('password');
      }
      error = messageError.toString();
    } catch (e) {
      error = e.toString();
    }
    await _logEvent('api_sale_v2_tracking', parameters: {
      'url': url,
      'headers': head != null ? head.toString() : '',
      'params': params != null ? log.toString() : '',
      'error': error,
      'userId': userId,
      'fullName': fullName,
      'uuid': uuid,
    });
  }

  ///saleclub
  static trackingAPIOCR(
      {required String eventName,
      required String userId,
      required String fullName,
      required String uuid,
      required String url,
      required String status,
      required dynamic head,
      required dynamic params,
      required dynamic messageError,
      required String screenName}) async {
    dynamic log = params;
    String error;
    try {
      if (log is! String && (log as Map).containsKey('password')) {
        log.remove('password');
      }
      error = messageError.toString();
    } catch (e) {
      error = e.toString();
    }
    await _logEvent(eventName, parameters: {
      'url': url,
      'screenName': screenName,
      'headers': head != null ? head.toString() : '',
      'params': params != null ? log.toString() : '',
      'message': error,
      'userId': userId,
      'fullName': fullName,
      'uuid': uuid,
      'status': status,
    });
  }
}
