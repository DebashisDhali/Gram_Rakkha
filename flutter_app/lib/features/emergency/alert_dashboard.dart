import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gram_rakkha/core/notification_service.dart';
import 'package:gram_rakkha/features/auth/auth_provider.dart';
import 'package:gram_rakkha/features/community/profile_screen.dart';
import 'package:gram_rakkha/features/emergency/alert_map_screen.dart';
import 'package:gram_rakkha/features/emergency/alert_repository.dart';
import 'package:gram_rakkha/core/entities.dart';
import 'package:gram_rakkha/core/api_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// StreamProvider for active WebSocket
final alertStreamProvider = StreamProvider.autoDispose.family<Map<String, dynamic>, String>((ref, token) {
  // Extract host from ApiClient.baseUrl
  final baseUrl = ApiClient.baseUrl;
  final host = baseUrl.replaceFirst('http://', '').replaceFirst('https://', '').split('/api/').first;
  final protocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
  
  final channel = WebSocketChannel.connect(
    Uri.parse('$protocol://$host/api/v1/emergency/ws/$token'),
  );
  ref.onDispose(() => channel.sink.close());
  return channel.stream.map((event) => jsonDecode(event as String));
});

// Alert type config
class _AlertConfig {
  final String type;
  final String label;
  final String emoji;
  final String description;
  final Color color;
  final Color glowColor;
  final IconData icon;

  const _AlertConfig({
    required this.type,
    required this.label,
    required this.emoji,
    required this.description,
    required this.color,
    required this.glowColor,
    required this.icon,
  });
}

const _alertTypes = [
  _AlertConfig(
    type: 'danger',
    label: 'DANGER',
    emoji: '🆘',
    description: 'Immediate life threat',
    color: Color(0xFFD32F2F),
    glowColor: Color(0xFFFF5252),
    icon: Icons.warning_rounded,
  ),
  _AlertConfig(
    type: 'suspicious',
    label: 'SUSPICIOUS',
    emoji: '👁️',
    description: 'Suspicious activity nearby',
    color: Color(0xFFE65100),
    glowColor: Color(0xFFFF9800),
    icon: Icons.visibility,
  ),
  _AlertConfig(
    type: 'help',
    label: 'NEED HELP',
    emoji: '🤝',
    description: 'Require immediate assistance',
    color: Color(0xFF1565C0),
    glowColor: Color(0xFF42A5F5),
    icon: Icons.pan_tool_rounded,
  ),
];

class AlertDashboard extends ConsumerStatefulWidget {
  const AlertDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AlertDashboard> createState() => _AlertDashboardState();
}

class _AlertDashboardState extends ConsumerState<AlertDashboard>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _receivedAlerts = [];
  String? _triggeringType;
  bool _isAlarmRinging = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _stopAlarm() {
    NotificationService().stopForegroundAlarm();
    setState(() => _isAlarmRinging = false);
  }

  @override
  void dispose() {
    NotificationService().stopForegroundAlarm();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerAlert(String type, _AlertConfig config) async {
    setState(() => _triggeringType = type);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await ref.read(alertRepoProvider).triggerAlert(
        type: type,
        lat: pos.latitude,
        lng: pos.longitude,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Text(config.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text('${config.label} alert sent!',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            backgroundColor: config.color,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: $e'),
            backgroundColor: Colors.grey.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _triggeringType = null);
    }
  }

  Future<void> _verifyAlert(String alertId) async {
    try {
      await ref.read(alertRepoProvider).verifyAlert(alertId);
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert ENSURED! Thank you.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    }
  }

  void _onAlertReceived(Map<String, dynamic> data) {
    if (data['event'] == 'EMERGENCY_ALERT' || 
        data['event'] == 'PRIORITY_ALERT' || 
        data['event'] == 'ALERT_VERIFIED') {
      
      final payload = data['payload'];
      final reporterId = payload['reporter_id']?.toString();
      final currentUserId = ref.read(authStateProvider).user?.id;

      // 🛑 Don't notify yourself for your own alerts
      if (reporterId != null && reporterId == currentUserId) {
        return;
      }

      final type = payload['type']?.toString().toUpperCase() ?? 'DANGER';
      final isVerified = data['event'] == 'ALERT_VERIFIED' || payload['status'] == 'verified';
      final reporter = payload['reporter']?.toString() ?? 'Someone';
      final config = _alertTypes.firstWhere(
        (c) => c.type == payload['type']?.toString(),
        orElse: () => _alertTypes.first,
      );

      setState(() {
        // If it's a verification update, update the existing alert in list
        final index = _receivedAlerts.indexWhere((a) => a['payload']['id'] == payload['id']);
        if (index != -1) {
           _receivedAlerts[index] = data;
        } else {
           _receivedAlerts.insert(0, data);
           // New alert! Start ringing if not already
           _isAlarmRinging = true;
           NotificationService().playForegroundAlarm();
        }
        if (_receivedAlerts.length > 20) _receivedAlerts.removeLast();
      });

      // 🔔 Fire system notification
      NotificationService().showEmergencyAlert(
        id: (payload['id']?.toString().hashCode ?? 0) ^ DateTime.now().second,
        title: isVerified ? '✅ VERIFIED: $type ALERT!' : '${config.emoji} $type ALERT!',
        body: isVerified 
            ? 'Emergency at ${reporter}\'s location has been VERIFIED by contacts!'
            : '$reporter reported an emergency. Tap to help!',
        payload: jsonEncode(payload),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final token = authState.token ?? '';
    final user = authState.user;

    // Listen to alert stream
    ref.listen(alertStreamProvider(token), (_, next) {
      next.whenData(_onAlertReceived);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield, color: Colors.red, size: 26),
            const SizedBox(width: 8),
            const Text(
              'GramRaksha',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.red.shade700,
                  radius: 18,
                  child: Text(
                    user.fullName[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isAlarmRinging
          ? FloatingActionButton.extended(
              onPressed: _stopAlarm,
              backgroundColor: Colors.yellowAccent,
              icon: const Icon(Icons.volume_off, color: Colors.black),
              label: const Text('STOP ALARM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          // Greeting
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Hello, ${user?.fullName.split(' ').first ?? 'User'} 👋',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade600),
                  ),
                  child: Row(children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'EMERGENCY ALERT BUTTONS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Alert Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: _alertTypes.map((config) {
                final isTriggering = _triggeringType == config.type;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (ctx, _) {
                      return Transform.scale(
                        scale: isTriggering ? _pulseAnimation.value : 1.0,
                        child: GestureDetector(
                          onTap: isTriggering ? null : () => _triggerAlert(config.type, config),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [config.color, config.color.withOpacity(0.7)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: config.glowColor.withOpacity(0.4),
                                  blurRadius: isTriggering ? 24 : 12,
                                  spreadRadius: isTriggering ? 4 : 0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(config.icon, color: Colors.white, size: 36),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${config.emoji}  ${config.label}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        config.description,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.75),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isTriggering)
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                else
                                  const Icon(Icons.chevron_right, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Live Alerts Feed
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    'LIVE COMMUNITY ALERTS',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _receivedAlerts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none,
                                  color: Colors.white12, size: 56),
                              const SizedBox(height: 8),
                              const Text(
                                'No alerts yet\nYou\'ll be notified in real-time',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white24, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _receivedAlerts.length,
                          itemBuilder: (ctx, i) {
                            final alert = _receivedAlerts[i];
                            final payload = alert['payload'];
                            final type = payload['type']?.toString() ?? 'danger';
                            final config = _alertTypes.firstWhere(
                              (c) => c.type == type,
                              orElse: () => _alertTypes.first,
                            );
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: config.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: config.color.withOpacity(0.3), width: 1.5),
                                ),
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.all(12),
                                      onTap: () {
                                        final entity = AlertEntity(
                                          id: payload['id'],
                                          reporterName: payload['reporter'] ?? 'Someone',
                                          type: type,
                                          status: payload['status'] ?? 'PENDING',
                                          lat: (payload['location']['lat'] as num).toDouble(),
                                          lng: (payload['location']['lng'] as num).toDouble(),
                                          timestamp: DateTime.now(),
                                        );
                                        Navigator.push(context,
                                            MaterialPageRoute(builder: (_) => AlertMapScreen(alert: entity)));
                                      },
                                      leading: Text(config.emoji, style: const TextStyle(fontSize: 28)),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${config.label} — ${payload['reporter'] ?? 'Unknown'}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15),
                                            ),
                                          ),
                                          if (payload['status'] == 'verified' || alert['event'] == 'ALERT_VERIFIED')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.green),
                                              ),
                                              child: const Text('VERIFIED', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Location: ${payload['location']['lat']?.toStringAsFixed(4)}, ${payload['location']['lng']?.toStringAsFixed(4)}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                                        ),
                                      ),
                                      trailing: const Icon(Icons.map_outlined, color: Colors.blueAccent),
                                    ),
                                    const Divider(height: 1, color: Colors.white10),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextButton.icon(
                                              onPressed: () => _verifyAlert(payload['id']),
                                              icon: const Icon(Icons.verified_user_outlined, size: 18),
                                              label: const Text('ENSURE THIS ALERT'),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.blue.shade300,
                                                padding: const EdgeInsets.symmetric(vertical: 10),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
