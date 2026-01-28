import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart'; // Import ito

class AdminMap extends StatefulWidget {
  const AdminMap({super.key});

  @override
  State<AdminMap> createState() => _AdminMapState();
}

class _AdminMapState extends State<AdminMap> {
  final MapController _mapController = MapController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _lastAlertCount = 0;

  @override
  void initState() {
    super.initState();
    // Pre-load ang sound file mula sa assets
    _audioPlayer.setSource(AssetSource('alarm.mp3'));
  }

  // Function para patunugin ang alarm
  void _playAlarm() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      print("Audio error: $e");
    }
  }

  void _zoomToLocation(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 17.5);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos_triggers')
            .where('status', isNotEqualTo: 'resolved')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            int currentCount = snapshot.data!.docs.length;

            // LALAKAS ANG TUNOG: Kung dumami ang alerts kaysa dati
            if (currentCount > _lastAlertCount) {
              _playAlarm();
            }
            _lastAlertCount = currentCount;
          }

          final sosDocs = snapshot.data?.docs ?? [];

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 25),
                  Expanded(
                    child: isDesktop
                        ? Row(
                      children: [
                        Expanded(flex: 3, child: _buildMap(sosDocs)),
                        const SizedBox(width: 25),
                        Expanded(flex: 2, child: _buildSosQueue(sosDocs)),
                      ],
                    )
                        : Column(
                      children: [
                        Expanded(flex: 2, child: _buildMap(sosDocs)),
                        const SizedBox(height: 20),
                        Expanded(flex: 3, child: _buildSosQueue(sosDocs)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- MAP WIDGET ---
  Widget _buildMap(List<QueryDocumentSnapshot> sosDocs) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: FlutterMap(
          mapController: _mapController,
          options: const MapOptions(initialCenter: LatLng(14.5995, 120.9842), initialZoom: 13),
          children: [
            TileLayer(urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'),
            MarkerLayer(
              markers: sosDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Marker(
                  point: LatLng(data['latitude'], data['longitude']),
                  width: 50, height: 50,
                  child: const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- SOS QUEUE WIDGET ---
  Widget _buildSosQueue(List<QueryDocumentSnapshot> docs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("ACTIVE ALERTS", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              if (docs.isNotEmpty)
                const Icon(Icons.volume_up, color: Colors.redAccent, size: 18),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data['userId'].toString().split('@')[0], style: const TextStyle(color: Colors.white)),
                  subtitle: Text(data['address'] ?? "Locating...", style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.gps_fixed, color: Colors.blueAccent),
                    onPressed: () => _zoomToLocation(data['latitude'], data['longitude']),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Command Center", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text("Emergency Monitoring System", style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }
}