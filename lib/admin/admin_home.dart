import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // PURE BLACK para mag-match sa Dashboard
      body: Stack(
        children: [
          // Subtle Glow sa background para hindi masyadong flat
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Admin Overview",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5
                    ),
                  ),
                  const Text(
                      "Real-time command center monitoring",
                      style: TextStyle(color: Colors.white38, fontSize: 14)
                  ),
                  const SizedBox(height: 35),

                  // --- ADMIN STATS GRID ---
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.1,
                    children: [
                      _buildStatCard("Active SOS", "sos_triggers", Icons.warning_amber_rounded, Colors.redAccent),
                      _buildStatCard("Pending Tasks", "service_requests", Icons.pending_actions_rounded, Colors.orangeAccent),
                      _buildStatCard("Total Users", "users", Icons.people_alt_rounded, Colors.blueAccent),
                      _buildStatCard("Broadcasts", "broadcasts", Icons.campaign_rounded, Colors.greenAccent),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Critical Incidents",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.1),
                      ),
                      TextButton(
                          onPressed: () {},
                          child: const Text("View Map", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold))
                      )
                    ],
                  ),
                  const SizedBox(height: 15),

                  // --- RECENT SOS LIST ---
                  _buildRecentSosList(),
                  const SizedBox(height: 120), // Space para sa Floating Navbar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String collection, IconData icon, Color cardColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.05), // Outer glow effect
                blurRadius: 15,
                spreadRadius: 1,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(25),
                  // GLOWING WHITE BORDER
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          shape: BoxShape.circle
                      ),
                      child: Icon(icon, color: cardColor, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        count,
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentSosList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sos_triggers').orderBy('time', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle
                        ),
                        child: const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 24),
                      ),
                      title: Text(
                        data['userId']?.toString().split('@')[0].toUpperCase() ?? "UNKNOWN",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: const Text("Immediate Assistance Required", style: TextStyle(color: Colors.white38, fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Column(
        children: [
          Icon(Icons.shield_rounded, color: Colors.white10, size: 50),
          SizedBox(height: 15),
          Text("SYSTEM SECURE", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 2)),
          Text("No active critical incidents reported.", style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}