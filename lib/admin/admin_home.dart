import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'user_list.dart';

class AdminHome extends StatefulWidget {
  final Function(int)? onNavigate;
  const AdminHome({super.key, this.onNavigate});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- SOS ALARM LOGIC ---
  void _playAlarm() async {
    if (!_isAlarmPlaying) {
      try {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('sounds/sirens.mp3'));
        if (mounted) setState(() => _isAlarmPlaying = true);
      } catch (e) {
        debugPrint("Audio Error: $e");
      }
    }
  }

  void _stopAlarm() async {
    if (_isAlarmPlaying) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _isAlarmPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMainBackground(), // Midnight Gradient Background
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sos_triggers')
                .where('status', isNotEqualTo: 'resolved')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                _playAlarm();
              } else {
                _stopAlarm();
              }

              final sosDocs = snapshot.data?.docs ?? [];

              return SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Desktop Layout kung malapad ang screen, Mobile kung makitid
                    if (constraints.maxWidth > 1100) {
                      return _buildExpandedDesktopLayout(sosDocs);
                    } else {
                      return _buildMobileLayout(sosDocs);
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- BACKGROUND (LOGIN STYLE) ---
  Widget _buildMainBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Deep Midnight Blue mula sa iyong login
            Color(0xFF020617),
            Colors.black,
          ],
        ),
      ),
    );
  }

  // --- EXPANDED DESKTOP LAYOUT ---
  Widget _buildExpandedDesktopLayout(List<QueryDocumentSnapshot> sosDocs) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          SizedBox(
            height: 160,
            child: Row(
              children: _statCards().map((card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: card,
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _glassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Live SOS Monitor",
                            onAction: () => widget.onNavigate?.call(1),
                            actionLabel: "Open Map System"),
                        const SizedBox(height: 20),
                        Expanded(child: _buildRecentSosList(sosDocs)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  flex: 1,
                  child: _buildSystemStatusPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MOBILE LAYOUT (FIXED OVERFLOW) ---
  Widget _buildMobileLayout(List<QueryDocumentSnapshot> sosDocs) {
    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(20), child: _buildHeader()),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GridView fix: Pinalitan ang aspect ratio para hindi mag-overflow ang text
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1, // Adjustment para kasya ang text at icon
                  children: _statCards(),
                ),
                const SizedBox(height: 30),
                _buildSectionTitle("Active Alerts"),
                const SizedBox(height: 10),
                _buildRecentSosList(sosDocs, shrinkWrap: true),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- GLASS CONTAINER HELPER ---
  Widget _glassContainer({required Widget child, double opacity = 0.05}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  // --- STAT CARDS ---
// Sa loob ng AdminHome class:
  List<Widget> _statCards() {
    return [
      _buildStatCard("Active SOS", "sos_triggers", Icons.warning_rounded, Colors.redAccent, 1, isEmergency: true),

      // ITO ANG SERVICE CARD: Naka-set sa index 2
      _buildStatCard("Tasks", "service_requests", Icons.pending_actions, Colors.orangeAccent, 2),

      _buildStatCard("Users", "users", Icons.people_rounded, Colors.blueAccent, -1),
      _buildStatCard("Radio Logs", "broadcasts", Icons.campaign_rounded, Colors.greenAccent, 3),
    ];
  }
  Widget _buildStatCard(String title, String coll, IconData icon, Color color, int idx, {bool isEmergency = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: isEmergency
          ? FirebaseFirestore.instance.collection(coll).where('status', isNotEqualTo: 'resolved').snapshots()
          : FirebaseFirestore.instance.collection(coll).snapshots(),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "0";
        bool hasAlert = isEmergency && count != "0";

        return _glassContainer(
          opacity: hasAlert ? 0.15 : 0.05,
          child: InkWell(
            onTap: () => idx != -1 ? widget.onNavigate?.call(idx) : Navigator.push(context, MaterialPageRoute(builder: (_) => const UserListPage())),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Mahalaga para sa overflow fix
              children: [
                Icon(icon, color: hasAlert ? Colors.redAccent : color, size: 24),
                const SizedBox(height: 5),
                FittedBox( // Automatic resize ng text para hindi mag-overflow
                  fit: BoxFit.scaleDown,
                  child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 2),
                Text(title.toUpperCase(),
                  style: const TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- SYSTEM STATUS ---
  Widget _buildSystemStatusPanel() {
    return _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("COMMAND STATUS", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 20),
          _statusRow("Network", "SECURE", Colors.greenAccent),
          _statusRow("Firebase", "ACTIVE", Colors.greenAccent),
          _statusRow("Alarm", _isAlarmPlaying ? "TRIGGERED" : "READY", _isAlarmPlaying ? Colors.redAccent : Colors.white24),
          const Spacer(),
          if (_isAlarmPlaying)
            const Center(child: Text("🚨 EMERGENCY ACTIVE", style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)))
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  // --- RECENT SOS LIST ---
  Widget _buildRecentSosList(List<QueryDocumentSnapshot> docs, {bool shrinkWrap = false}) {
    if (docs.isEmpty) return _buildEmptyState();

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
          ),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.emergency_share, color: Colors.redAccent, size: 20),
            title: Text(data['userId']?.toString().split('@')[0].toUpperCase() ?? "USER",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            subtitle: Text(data['address'] ?? "Locating...",
              style: const TextStyle(color: Colors.white38, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 10),
            onTap: () => widget.onNavigate?.call(1),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.admin_panel_settings, color: Colors.blueAccent, size: 32),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text("Admin Center", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Text("AI-POWERED DASHBOARD", style: TextStyle(color: Colors.blueAccent, fontSize: 8, letterSpacing: 1.2)),
            ],
          ),
        ),
        if (_isAlarmPlaying)
          IconButton(
            onPressed: _stopAlarm,
            icon: const Icon(Icons.volume_off, color: Colors.redAccent, size: 20),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onAction, String? actionLabel}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        if (onAction != null)
          TextButton(
              onPressed: onAction,
              child: Text(actionLabel ?? "View All", style: const TextStyle(color: Colors.blueAccent, fontSize: 11))
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.white10, size: 30),
          SizedBox(height: 8),
          Text("ALL SYSTEMS CLEAR", style: TextStyle(color: Colors.white10, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}