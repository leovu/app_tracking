import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AppTracking {
  static FirebaseAnalytics? analytics;
  static const MethodChannel _channel = const MethodChannel('app_tracking');
  static var _kTestingCrashlytics = true;

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  //TODO: setup in main.dart, input MyApp parameter. You have to put WidgetsFlutterBinding.ensureInitialized(); before init
  static init({required Widget myApp, required bool testingCrashlytics}) async {
    await Firebase.initializeApp();
    if(!kIsWeb) {
      analytics = FirebaseAnalytics();
      _kTestingCrashlytics = testingCrashlytics;
    }
    if(kIsWeb) {
        runApp(myApp);
     }
    else {
        runZonedGuarded(() {
        _initCrashlytics();
        runApp(myApp);
      }, FirebaseCrashlytics.instance.recordError);
    }
  }

  static _initCrashlytics() async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(_kTestingCrashlytics);
    Function(FlutterErrorDetails)? originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails errorDetails) async {
      await FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      if (originalOnError != null) {
        originalOnError(errorDetails);
      }
    };
  }

  static trackingErrorAPI(
      {required String userId,
      required String fullName,
      required String uuid,
      required String url,
      required dynamic head,
      required dynamic params,
      required dynamic messageError}) async {
    if (analytics == null) analytics = FirebaseAnalytics();
    if (kIsWeb) return;
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
    analytics!.logEvent(name: 'api_tracking', parameters: <String, dynamic>{
      "url": url ?? "",
      "headers": head != null ? "${head.toString()}" : "",
      "params": params != null ? "${log.toString()}" : "",
      "error": error,
      "userId": userId,
      "fullName": fullName,
      "uuid": uuid
    });
  }

  static trackingScreen(
      {required String screenName,
      required String userId,
      required String fullName,
      required String uuid}) {
    if (analytics == null) analytics = FirebaseAnalytics();
    if (kIsWeb) return;
    analytics!.logEvent(
      name: 'screen_tracking',
      parameters: <String, dynamic>{
        "screenName": screenName,
        "userId": userId,
        "fullName": fullName,
        "uuid": uuid
      },
    );
  }

  static trackingNotification(
      {required String userId,
      required String fullName,
      required dynamic params}) {
    if (analytics == null) analytics = FirebaseAnalytics();
    if (kIsWeb) return;
    dynamic log = params;
    try {
      if (!(log is String)) {
        if (log.containsKey('password')) {
          log.remove('password');
        }
      }
    } catch (_) {}
    analytics!
        .logEvent(name: 'notification_tracking', parameters: <String, dynamic>{
      "userId": userId,
      "fullName": fullName,
      "params": log.toString(),
    });
  }
}
