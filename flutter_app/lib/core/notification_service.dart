import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:gram_rakkha/core/entities.dart';
import 'package:gram_rakkha/features/emergency/alert_map_screen.dart';
import 'package:gram_rakkha/main.dart'; // To access navigatorKey

import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;

  Future<void> playForegroundAlarm() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/emergency.mp3'));
    } catch (e) {
      debugPrint("Error playing foreground alarm: $e");
    }
  }

  Future<void> stopForegroundAlarm() async {
    await _audioPlayer.stop();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
      await androidImplementation?.requestFullScreenIntentPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }
  }

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
        'gram_raksha_emergency_v2', 
        'GramRaksha Emergency Alerts',
        description: 'Persistent loud alerts for life-threatening emergencies',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('emergency'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
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
      'gram_raksha_emergency_v2',
      'GramRaksha Emergency Alerts',
      channelDescription: 'Persistent loud alerts for life-threatening emergencies',
      importance: Importance.max,
      priority: Priority.max,
      ticker: 'EMERGENCY ALERT!',
      color: Color(0xFFD32F2F),
      enableLights: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      playSound: true,
      sound: RawResourceAndroidNotificationSound('emergency'),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true, // Makes it harder to dismiss accidentally
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    const DarwinNotificationDetails iosNotificationDetails = 
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'emergency.mp3',
      interruptionLevel: InterruptionLevel.critical,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(
          android: androidNotificationDetails,
          iOS: iosNotificationDetails,
        );

    await _plugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
