import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:gram_rakkha/core/entities.dart';
import 'package:gram_rakkha/features/emergency/alert_map_screen.dart';
import 'package:gram_rakkha/main.dart'; // To access navigatorKey

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    try {
      await _plugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            try {
              final Map<String, dynamic> data = jsonDecode(payload);
              final entity = AlertEntity(
                id: data['id'],
                reporterName: data['reporter'] ?? 'Unknown',
                type: data['type'] ?? 'danger',
                status: 'PENDING',
                lat: (data['location']['lat'] as num).toDouble(),
                lng: (data['location']['lng'] as num).toDouble(),
                timestamp: DateTime.now(),
              );

              // Navigate to map
              MyApp.navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => AlertMapScreen(alert: entity)),
              );
            } catch (e) {
              debugPrint("Notification navigation error: $e");
            }
          }
        },
      );
      
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'gram_raksha_emergency', 
        'GramRaksha Emergency Alerts',
        description: 'Real-time community emergency notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFFFF0000),
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      _initialized = true;
    } catch (e) {
      debugPrint("Notification init error: $e");
    }
  }

  Future<void> showEmergencyAlert({
    required String title,
    required String body,
    required int id,
    String? payload,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'gram_raksha_emergency',
      'GramRaksha Emergency Alerts',
      channelDescription: 'Real-time community emergency notifications',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'Emergency Alert!',
      color: Color(0xFFD32F2F),
      enableLights: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _plugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
