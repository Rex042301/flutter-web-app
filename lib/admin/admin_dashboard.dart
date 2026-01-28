import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

// Pages
import 'mapp_page.dart';
import 'admin_home.dart';
import 'admin_services.dart';
import 'admin_updates.dart';
import 'admin_profile.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSirenPlaying = false;
  String? _latestDocId;
  StreamSubscription<QuerySnapshot>? _sosSubscription;

  // Screens with onBack callbacks fixed
  List<Widget> get _screens => [
    AdminHome(onNavigate: (index) => _onItemTapped(index)),
    const AdminMap(),
    AdminServices(onBack: () => _onItemTapped(0)),
    AdminUpdates(onBack: () => _onItemTapped(0)),
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMainBackground(),

          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 800;
              return Row(
                children: [
                  if (isDesktop) _buildNavigationRail(),
                  Expanded(
                    child: Padding(
                      padding:
                      EdgeInsets.only(bottom: isDesktop ? 0 : 90),
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _screens,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          Positioned(
            bottom: 25,
            left: 15,
            right: 15,
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return const SizedBox.shrink();
                }
                return _buildGlowingGlassNavbar();
              },
            ),
          ),

          if (_isSirenPlaying) _buildEmergencyOverlay(),
        ],
      ),
    );
  }

  // --- UI BUILDING BLOCKS ---

  Widget _buildMainBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Color(0xFF001220), Colors.black],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        _buildGlowCircle(top: -50, right: -50, color: Colors.blueAccent),
        _buildGlowCircle(bottom: 50, left: -80, color: Colors.indigoAccent),
      ],
    );
  }

  Widget _buildGlowCircle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 100,
              spreadRadius: 50,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      backgroundColor: Colors.white.withOpacity(0.02),
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: Colors.blueAccent),
      unselectedIconTheme: const IconThemeData(color: Colors.white24),
      destinations: const [
        NavigationRailDestination(
            icon: Icon(Icons.grid_view_rounded), label: Text("Home")),
        NavigationRailDestination(
            icon: Icon(Icons.map_rounded), label: Text("Map")),
        NavigationRailDestination(
            icon: Icon(Icons.pending_actions_rounded),
            label: Text("Services")),
        NavigationRailDestination(
            icon: Icon(Icons.campaign_rounded), label: Text("Updates")),
        NavigationRailDestination(
            icon: Icon(Icons.person_rounded), label: Text("Profile")),
      ],
    );
  }

  Widget _buildGlowingGlassNavbar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
            border:
            Border.all(color: Colors.white.withOpacity(0.12), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(Icons.grid_view_rounded, "HOME", 0),
              _navItem(Icons.map_rounded, "MAP", 1),
              _navItem(Icons.pending_actions_rounded, "PENDING", 2),
              _navItem(Icons.campaign_rounded, "ANNOUNCE", 3),
              _navItem(Icons.person_rounded, "PROFILE", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? Colors.blueAccent : Colors.white38,
                size: 22),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 8,
                    fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyOverlay() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: () => _onItemTapped(1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 20)
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "EMERGENCY ACTIVE - CHECK MAP",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
