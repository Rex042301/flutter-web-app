import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Pages
import 'mapp_page.dart'; // Siguraduhing ito ang AdminMap mo
import '../login.dart';
import 'admin_home.dart';
import 'admin_services.dart';
import 'admin_updates.dart';
import 'admin_profile.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSirenPlaying = false;
  String? _latestDocId;
  StreamSubscription<QuerySnapshot>? _sosSubscription;

  late final List<Widget> _screens = [
    const AdminHome(),
    const AdminMap(),
    const AdminServices(),
    const AdminUpdates(),
    const AdminProfile(),
  ];

  @override
  void initState() {
    super.initState();
    _startGlobalSosListener();
  }

  @override
  void dispose() {
    _sosSubscription?.cancel();
    _stopSiren();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- SOS LISTENER LOGIC ---
  void _startGlobalSosListener() {
    _sosSubscription = FirebaseFirestore.instance
        .collection('sos_triggers')
        .orderBy('time', descending: true)
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs;
      if (docs.isNotEmpty) {
        if (_latestDocId != docs.first.id) {
          _latestDocId = docs.first.id;
          _playSiren();
        }
      } else {
        if (_isSirenPlaying) _stopSiren();
      }
    });
  }

  Future<void> _playSiren() async {
    if (!_isSirenPlaying) {
      setState(() => _isSirenPlaying = true);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/sirens.mp3'));
      _vibrate();
    }
  }

  Future<void> _stopSiren() async {
    await _audioPlayer.stop();
    if (mounted) setState(() => _isSirenPlaying = false);
  }

  void _vibrate() async {
    final bool hasVibrator = await Vibration.hasVibrator() == true;
    if (hasVibrator && _isSirenPlaying) {
      Vibration.vibrate(duration: 500);
      Future.delayed(const Duration(seconds: 1), _vibrate);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure Black Background
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 800;

          return Stack(
            children: [
              Row(
                children: [
                  if (isDesktop) _buildNavigationRail(),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
                  ),
                ],
              ),

              // Glass Navbar para sa Mobile
              if (!isDesktop)
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: _buildGlowingGlassNavbar(),
                ),

              // SOS ALERT INDICATOR (Lalabas kapag may active SOS)
              if (_isSirenPlaying) _buildEmergencyOverlay(),
            ],
          );
        },
      ),
    );
  }

  // --- DESKTOP NAV RAIL ---
  Widget _buildNavigationRail() {
    return NavigationRail(
      backgroundColor: Colors.black,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
      unselectedIconTheme: const IconThemeData(color: Colors.white24),
      selectedLabelTextStyle: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white24),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), label: Text("Home")),
        NavigationRailDestination(icon: Icon(Icons.map_rounded), label: Text("Map")),
        NavigationRailDestination(icon: Icon(Icons.admin_panel_settings_rounded), label: Text("Services")),
        NavigationRailDestination(icon: Icon(Icons.campaign_rounded), label: Text("Updates")),
        NavigationRailDestination(icon: Icon(Icons.person_rounded), label: Text("Profile")),
      ],
    );
  }

  // --- MOBILE GLOWING GLASS NAVBAR ---
  Widget _buildGlowingGlassNavbar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.grid_view_rounded, 0),
                _navItem(Icons.map_rounded, 1),
                _navItem(Icons.admin_panel_settings_rounded, 2),
                _navItem(Icons.campaign_rounded, 3),
                _navItem(Icons.person_rounded, 4),
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
        child: Icon(
          icon,
          color: isSelected ? Colors.blueAccent : Colors.white38,
          size: isSelected ? 30 : 26,
        ),
      ),
    );
  }

  // --- EMERGENCY OVERLAY INDICATOR ---
  Widget _buildEmergencyOverlay() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = 1), // Lilipat sa Map
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 15)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text("EMERGENCY ACTIVE - CHECK MAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}