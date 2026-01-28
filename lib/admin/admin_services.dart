import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your card widgets
import 'emergency_card.dart';
import 'safety_tips_card.dart';
import 'ews_card.dart';
import 'facilities_card.dart';
import 'evacuation_card.dart';
import 'hazard_card.dart';
import 'hotlines_card.dart';

// Import the pages to navigate
import 'emergency_page.dart';
import 'safety_tips_page.dart';
import 'ews_page.dart';
import 'facilities_page.dart';
import 'evacuation_page.dart';
import 'hazard_page.dart';
import 'hotlines_page.dart';

class AdminServices extends StatefulWidget {
  final VoidCallback onBack;
  const AdminServices({super.key, required this.onBack});

  @override
  State<AdminServices> createState() => _AdminServicesState();
}

class _AdminServicesState extends State<AdminServices> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _isAdmin = doc.exists && doc.get('role') == 'admin';
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 800 ? 5 : width > 600 ? 4 : 3;

    // List of service cards with navigation
    final List<Widget> serviceCards = [
      EmergencyCard(
        isAdmin: _isAdmin,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmergencyPage()),
        ),
      ),
      SafetyTipsCard(
        isAdmin: _isAdmin,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SafetyTipsPage()),
        ),
      ),
      EWSCard(
        isAdmin: _isAdmin,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EWSPage()),
        ),
      ),
      FacilitiesCard(
        isAdmin: _isAdmin,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FacilitiesPage()),
        ),
      ),
      EvacuationCard(
        isAdmin: _isAdmin,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EvacuationPage()),
        ),
      ),
      HazardCard(
        isAdmin: _isAdmin,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HazardPage()),
        ),
      ),
      HotlinesCard(
        isAdmin: _isAdmin,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HotlinesPage()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildGlowCircle(top: -50, right: -50, color: Colors.blueAccent),
          _buildGlowCircle(bottom: 50, left: -80, color: Colors.indigoAccent),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: widget.onBack,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Admin Services",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(20),
                    crossAxisCount: crossCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: serviceCards,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              color: color.withOpacity(0.2),
              blurRadius: 100,
              spreadRadius: 50,
            )
          ],
        ),
      ),
    );
  }
}
