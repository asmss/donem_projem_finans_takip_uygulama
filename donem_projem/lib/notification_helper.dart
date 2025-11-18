import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  // Nesnemizi oluşturduk
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future initialize() async {
    // Bildirim ikonu belirttik.
    const androidInitialize =
    AndroidInitializationSettings('mipmap/ic_launcher');
    const initializationsSettings =
    InitializationSettings(android: androidInitialize);

    // Paketimizi bildirim ikonu belirttikten sonra başlattık.
    await _notifications.initialize(initializationsSettings);
  }

  // Bildirimimizle ilgili tüm ayarları çağırmak üzere burada belirttik.
  static Future _notificationDetails() async => const NotificationDetails(
    android: AndroidNotificationDetails(
      "donem_projem", // Kanal ID - mutlaka unique olmalı
      "day_counterr_1", // Kanal adı
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      timeoutAfter: 5000, // 5 saniye sonra zaman aşımı
      autoCancel: true,
      ongoing: false,
      styleInformation: BigTextStyleInformation(''),
    ),
  );

  // Normal bildirim gösterme.
  static Future showNotification({
    int id = 0,
    required String title,
    required String body,
  }) async =>
      _notifications.show(id, title, body, await _notificationDetails());

  // Zamanlanmış bildirim gösterme.
  static Future scheduleNotification({
    int id = 0,
    String? title,
    String? body,
    required DateTime scheduledDateTime,
  }) async =>
      _notifications.zonedSchedule(
          id,
          title,
          body,
          // TimeZone paketiyle DateTime objesini TZDateTime'e dönüştürdük.
          tz.TZDateTime.from(scheduledDateTime, tz.local),
          await _notificationDetails(),

          // Bildirim tipini burada alarm olarak belirledik.
          androidScheduleMode: AndroidScheduleMode.inexact,
          // Bildirim zamanını absolute (gmt) zaman dilimi olarak belirledik.
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime);

  // Tüm zamanlanmış fonksiyonları iptal etme.
  static Future unScheduleAllNotifications() async =>
      await _notifications.cancelAll();
}