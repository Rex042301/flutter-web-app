import 'dart:ui';
import 'package:aiper/admin/admin_services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_list.dart';
import 'sos_list.dart';
import 'package:aiper/admin/admin_services.dart';
import 'package:aiper/admin/admin_updates.dart';


class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                        letterSpacing: 1.5),
                  ),
                  const Text(
                    "Real-time command center monitoring",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
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
                      _buildStatCard(context, "Active SOS", "sos_triggers",
                          Icons.warning_amber_rounded, Colors.redAccent),
                      _buildStatCard(context, "Pending Tasks", "service_requests",
                          Icons.pending_actions_rounded, Colors.orangeAccent),
                      _buildStatCard(context, "Total Users", "users",
                          Icons.people_alt_rounded, Colors.blueAccent),
                      _buildStatCard(context, "Broadcasts", "broadcasts",
                          Icons.campaign_rounded, Colors.greenAccent),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Critical Incidents",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          "View Map",
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 15),

                  _buildRecentSosList(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STAT CARD =================
  Widget _buildStatCard(
      BuildContext context,
      String title,
      String collection,
      IconData icon,
      Color cardColor,
      ) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        String count =
        snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";

        return InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            if (collection == "users") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserListPage()),
              );
            } else if (collection == "sos_triggers") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SosListPage()),
              );
            } else if (collection == "service_requests") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminServices()), // from admin_services.dart
              );
            } else if (collection == "broadcasts") {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUpdates()), // from admin_updates.dart
              );
            }
          },

          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.05),
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
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: cardColor, size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        count,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ================= RECENT SOS =================
  Widget _buildRecentSosList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_triggers')
          .orderBy('time', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
              CircularProgressIndicator(color: Colors.blueAccent));
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
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.2),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emergency_rounded,
                            color: Colors.redAccent, size: 24),
                      ),
                      title: Text(
                        data['userId']
                            ?.toString()
                            .split('@')[0]
                            .toUpperCase() ??
                            "UNKNOWN",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      subtitle: const Text(
                        "Immediate Assistance Required",
                        style: TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white24,
                        size: 16,
                      ),
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

  // ================= EMPTY STATE =================
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
          Icon(Icons.shield_rounded,
              color: Colors.white10, size: 50),
          SizedBox(height: 15),
          Text(
            "SYSTEM SECURE",
            style: TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                letterSpacing: 2),
          ),
          Text(
            "No active critical incidents reported.",
            style: TextStyle(
                color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
