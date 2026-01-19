import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// Siguraduhin na tama ang iyong import paths
import 'user_home.dart';
import 'user_services.dart';
import 'updates.dart';
import 'profile_page.dart';

class UserDashboardPage extends StatefulWidget {
  final String userRole;
  const UserDashboardPage({super.key, required this.userRole});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int _selectedIndex = 0;
  StreamSubscription<Position>? _positionStream;

  // Iisang listahan ng screens para sa madaling navigation
  late final List<Widget> _screens = [
    const UserHome(),
    const UserServices(),
    const SizedBox.shrink(), // SOS Placeholder (Hindi ito nirerender bilang screen)
    const UserUpdates(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // --- LOCATION TRACKING LOGIC ---
  Future<void> _startLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        _updateUserLocationInFirestore(position);
      });
    }
  }

  Future<void> _updateUserLocationInFirestore(Position pos) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // --- NAVIGATION LOGIC ---
  void _onItemTapped(int index) {
    if (index == 2) {
      _triggerSosAction(); // SOS Button behavior
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  // --- SOS EMERGENCY ACTION ---
  Future<void> _triggerSosAction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      Position pos = await Geolocator.getCurrentPosition();
      DocumentReference doc = await FirebaseFirestore.instance.collection('sos_triggers').add({
        'userId': user.email ?? user.uid,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'time': Timestamp.now(),
        'status': 'active',
      });
      _showSosDialog(doc.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  void _showSosDialog(String docId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: const BorderSide(color: Colors.redAccent, width: 2)),
          title: const Text("SOS ACTIVE",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          content: const Text("Emergency responders are tracking your location. Stay calm.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70)),
          actions: [
            Center(
              child: TextButton(
                onPressed: () {
                  FirebaseFirestore.instance.collection('sos_triggers').doc(docId).delete();
                  Navigator.pop(context);
                },
                child: const Text("CANCEL SOS",
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure black base
      extendBody: true, // Importante para maging transparent ang area sa likod ng navbar
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            const Icon(Icons.shield_moon_rounded, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 10),
            Text(
              "AIPER",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main Content Container
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),

          // --- GLOWING GLASS NAVBAR ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildGlowingNavbar(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingNavbar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.06), // Ambient outer glow
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(35),
              // Glowing White Border
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.grid_view_rounded, 0),
                _navItem(Icons.handyman_rounded, 1),
                _sosButton(),
                _navItem(Icons.notifications_active_rounded, 3),
                _navItem(Icons.person_3_rounded, 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Icon(
          icon,
          color: isSelected ? Colors.blueAccent : Colors.white30,
          size: isSelected ? 30 : 26,
        ),
      ),
    );
  }

  Widget _sosButton() {
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Icon(Icons.sos_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}