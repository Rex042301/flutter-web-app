import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMap extends StatefulWidget {
  const AdminMap({super.key});

  @override
  State<AdminMap> createState() => _AdminMapState();
}

class _AdminMapState extends State<AdminMap> {
  final MapController _mapController = MapController();

  // Privacy Helper: Censored name (e.g., "John" -> "Jo**")
  String _censorName(String name) {
    if (name.length <= 2) return name;
    return name.substring(0, 2) + "*" * (name.length - 2);
  }

  void _zoomToLocation(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 17.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // PURE BLACK para sa high-tech feel
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Live Command Center",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
              ),
              const Text("Real-time community monitoring", style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 25),

              // 1. THE GLASSBOARD MAP CONTAINER WITH GLOWING WHITE BORDER
              _buildGlowingMapContainer(),

              const SizedBox(height: 25),

              // 2. EMERGENCY QUEUE CARD WITH RED GLOW
              _buildSosQueueCard(),

              const SizedBox(height: 100), // Space para sa Floating Navbar
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: MAP CONTAINER WITH GLOWING WHITE BORDER ---
  Widget _buildGlowingMapContainer() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 450,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              // GLOWING WHITE BORDER
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              children: [
                // Map Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: const [
                      Icon(Icons.map_rounded, color: Colors.blueAccent, size: 20),
                      SizedBox(width: 10),
                      Text("LIVE POPULATION MAP",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
                      Spacer(),
                      Icon(Icons.sensors_rounded, color: Colors.greenAccent, size: 18),
                    ],
                  ),
                ),

                // Actual Map Area
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, userSnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('sos_triggers').snapshots(),
                          builder: (context, sosSnapshot) {
                            final userDocs = userSnapshot.data?.docs ?? [];
                            final sosDocs = sosSnapshot.data?.docs ?? [];

                            return FlutterMap(
                              mapController: _mapController,
                              options: const MapOptions(
                                initialCenter: LatLng(14.5995, 120.9842),
                                initialZoom: 14,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                ),

                                MarkerLayer(
                                  markers: [
                                    // USERS MARKERS (Blue Glow)
                                    ...userDocs.where((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return data['latitude'] != null && data['longitude'] != null;
                                    }).map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return Marker(
                                        point: LatLng(data['latitude'], data['longitude']),
                                        width: 40, height: 40,
                                        child: Column(
                                          children: [
                                            const Icon(Icons.circle, color: Colors.blueAccent, size: 10),
                                            Text(_censorName(data['name'] ?? "User"),
                                                style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      );
                                    }),

                                    // SOS MARKERS (Red Pulsing Effect)
                                    ...sosDocs.where((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return data['latitude'] != null && data['longitude'] != null;
                                    }).map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return Marker(
                                        point: LatLng(data['latitude'], data['longitude']),
                                        width: 60, height: 60,
                                        child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 40),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET: SOS QUEUE CARD WITH RED GLOWING BORDER ---
  Widget _buildSosQueueCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              // RED GLOWING BORDER PARA SA EMERGENCY
              border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("ACTIVE EMERGENCY QUEUE",
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                    Icon(Icons.warning_rounded, color: Colors.redAccent, size: 20),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white10),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('sos_triggers').snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Text("All clear. No active alerts.", style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.emergency_rounded, size: 20, color: Colors.redAccent),
                          ),
                          title: Text(data['userId'].toString().split('@')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          subtitle: const Text("Immediate response required", style: TextStyle(color: Colors.white38, fontSize: 11)),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.gps_fixed_rounded, color: Colors.blueAccent, size: 20),
                              onPressed: () => _zoomToLocation(data['latitude'], data['longitude']),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}