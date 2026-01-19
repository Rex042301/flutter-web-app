import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login.dart'; // Siguraduhing tama ang path ng iyong LoginPage

class AdminProfile extends StatelessWidget {
  const AdminProfile({super.key});
  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Change Profile Picture",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(context, Icons.photo_library_rounded, "Gallery"),
                  _buildSourceOption(context, Icons.camera_enhance_rounded, "Camera"),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceOption(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // Close modal
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black, // PURE BLACK base
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              // --- GLOWING ADMIN AVATAR ---
              // --- GLOWING ADMIN AVATAR WITH FUNCTIONAL BUTTON ---
              Center(
                child: Stack(
                  children: [
                    // Main Avatar Container
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        // DITO MADI-DISPLAY ANG IMAGE (Placeholder muna ang Icon)
                        child: const Icon(Icons.person_rounded, size: 55, color: Colors.blueAccent),
                      ),
                    ),

                    // THE FUNCTIONAL BUTTON (Bottom Right)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          // Dito mo tatawagin ang image picker function
                          _showImageSourceDialog(context);
                        },
                        child: Container(
                          height: 35,
                          width: 35,
                          decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2.5), // Para humiwalay sa background
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)
                              ]
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "ADMINISTRATOR",
                style: TextStyle(
                  color: Colors.blueAccent.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user?.email ?? "admin@aiper.com",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 45),

              // --- PROFILE ACTIONS ---
              _buildGlassTile(Icons.security_rounded, "Security Settings"),
              const SizedBox(height: 15),
              _buildGlassTile(Icons.notifications_active_rounded, "Notification Preferences"),
              const SizedBox(height: 15),
              _buildGlassTile(Icons.history_toggle_off_rounded, "Emergency Logs"),
              const SizedBox(height: 15),
              _buildGlassTile(Icons.info_outline_rounded, "App Version"),
              const SizedBox(height: 15),

              // --- LOGOUT BUTTON ---
              _buildGlassTile(
                  Icons.logout_rounded,
                  "Sign Out",
                  isDestructive: true,
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false,
                    );
                  }
              ),

              const SizedBox(height: 120), // Space para sa Floating Navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTile(IconData icon, String title, {bool isDestructive = false, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: isDestructive ? Colors.redAccent.withOpacity(0.05) : Colors.white.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: InkWell(
            onTap: onTap ?? () {},
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(22),
                // GLOWING BORDER
                border: Border.all(
                    color: isDestructive ? Colors.redAccent.withOpacity(0.4) : Colors.white.withOpacity(0.4),
                    width: 1.5
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: isDestructive ? Colors.redAccent : Colors.blueAccent, size: 24),
                  const SizedBox(width: 15),
                  Text(
                      title,
                      style: TextStyle(
                          color: isDestructive ? Colors.redAccent : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600
                      )
                  ),
                  const Spacer(),
                  Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.2),
                      size: 14
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}