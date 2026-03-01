import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gram_rakkha/core/entities.dart';

class AlertMapScreen extends StatefulWidget {
  final AlertEntity alert;
  const AlertMapScreen({super.key, required this.alert});

  @override
  State<AlertMapScreen> createState() => _AlertMapScreenState();
}

class _AlertMapScreenState extends State<AlertMapScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint("🚨 AlertMapScreen opened for: ${widget.alert.id}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('${widget.alert.type.toUpperCase()} ALERT', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF16213E),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // If Map fails/crashes, this background remains
          Container(color: Colors.black),
          
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.alert.lat, widget.alert.lng), 
              zoom: 15
            ),
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            markers: {
              Marker(
                markerId: MarkerId(widget.alert.id),
                position: LatLng(widget.alert.lat, widget.alert.lng),
                infoWindow: InfoWindow(
                  title: widget.alert.type.toUpperCase(), 
                  snippet: 'Reported by: ${widget.alert.reporterName}'
                ),
              ),
            },
            onMapCreated: (controller) {
              debugPrint("🗺️ Google Map Created Successfully.");
            },
          ),

          // Detail Card
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${widget.alert.type.toUpperCase()} REPORTED',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reporter: ${widget.alert.reporterName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('STATUS', style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: const Text('PENDING', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Action logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Contacting community members...'))
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('VERIFY SITUATION', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
