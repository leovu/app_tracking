import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppTracking {
  static final _ready = Completer<void>();
  static var _kTestingCrashlytics = true;
  static Future<void> setup({required bool enableCrashlytics}) async {
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(enableCrashlytics);

      final original = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) async {
        await FirebaseCrashlytics.instance.recordFlutterError(details);
        original?.call(details);
      };

      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return false;
      };
    }
  }
  static Future<void> init({
    required Widget myApp,
    required FirebaseOptions options,
    required bool testingCrashlytics,
  }) async {
    await Firebase.initializeApp(options: options);
    Zone.current.runGuarded(()async{
      _kTestingCrashlytics = testingCrashlytics;
      if (!kIsWeb) {
        await _initCrashlytics();
        final dispatcher = WidgetsBinding.instance.platformDispatcher;
        dispatcher.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return false;
        };
      }
      runApp(myApp);
    });

    // đánh dấu “đã có frame đầu tiên”
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_ready.isCompleted) _ready.complete();
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

  static Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!_ready.isCompleted) await _ready.future; // chờ UI attach

    final fa = FirebaseAnalytics.instance;
    try {
      await fa.logEvent(name: name, parameters: parameters);
    } on PlatformException catch (_) {
      await WidgetsBinding.instance.endOfFrame; // đợi thêm một frame
      await fa.logEvent(name: name, parameters: parameters);
    }
  }

  static Future<void> _logScreenView(String screenName) async {
    if (!_ready.isCompleted) await _ready.future;

    final fa = FirebaseAnalytics.instance;
    try {
      await fa.logScreenView(screenName: screenName);
    } on PlatformException catch (_) {
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
    // Đảm bảo UI đã có view trước khi logScreenView
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _logScreenView(screenName);
    });
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
    // Đảm bảo UI đã có view trước khi logScreenView
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _logScreenView(screenName);
    });
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
