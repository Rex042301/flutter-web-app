import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  // Weather API Setup
  final String apiKey = "fe5a11561b18c04c0ffdcf0ab173bea7";
  final String city = "Manila";

  Future<Map<String, dynamic>> fetchWeather() async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=metric&appid=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception("Failed to load");
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // UPDATED: Pure Black para sa seamless look sa Dashboard
    const Color pureBlack = Colors.black;

    return Scaffold(
      backgroundColor: pureBlack,
      body: SafeArea(
        // Inalis ang Stack/Gradient para sa clean black aesthetic
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Current Status", style: _headingStyle),
              const SizedBox(height: 15),
              // Emerald Green Glass Status
              _buildSafetyStatus(isEmergency: false),

              const SizedBox(height: 30),
              const Text("Real-Time Weather", style: _headingStyle),
              const SizedBox(height: 15),

              FutureBuilder<Map<String, dynamic>>(
                future: fetchWeather(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white24));
                  }
                  final data = snapshot.data ?? {};
                  return _buildStatsGrid(data);
                },
              ),

              const SizedBox(height: 30),
              const Text("Community Alerts", style: _headingStyle),
              const SizedBox(height: 15),
              _buildCommunityAlerts(),

              // Extra space para sa Floating Glass Navbar ng Dashboard
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  static const _headingStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 18,
      letterSpacing: 1.2);

  // --- WIDGET SECTIONS ---

  Widget _buildSafetyStatus({bool isEmergency = false}) {
    // Emerald highlight para sa "Safe" status
    final Color safeColor = const Color(0xFF00C853).withOpacity(0.08);
    final Color safeBorder = const Color(0xFF69F0AE).withOpacity(0.4);

    final Color emergencyColor = Colors.redAccent.withOpacity(0.12);
    final Color emergencyBorder = Colors.redAccent.withOpacity(0.5);

    return _glassContainer(
      customColor: isEmergency ? emergencyColor : safeColor,
      customBorderColor: isEmergency ? emergencyBorder : safeBorder,
      child: Row(
        children: [
          Icon(
            isEmergency ? Icons.warning_rounded : Icons.verified_user_rounded,
            color: isEmergency ? Colors.redAccent : const Color(0xFF69F0AE),
            size: 40,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmergency ? "EMERGENCY ACTIVE" : "SYSTEM SECURE",
                  style: TextStyle(
                      color: isEmergency ? Colors.redAccent : const Color(0xFFB9F6CA),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
                Text(
                  isEmergency ? "Emergency services alerted" : "No threats detected in your area",
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> weather) {
    final temp = weather['main']?['temp']?.toStringAsFixed(1) ?? "--";
    final humidity = weather['main']?['humidity']?.toString() ?? "--";
    final wind = weather['wind']?['speed']?.toString() ?? "--";
    final condition = weather['weather']?[0]?['main'] ?? "Cloudy";

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.25,
      children: [
        _statCard("Condition", condition, Icons.wb_cloudy_outlined),
        _statCard("Humidity", "$humidity%", Icons.water_drop_outlined),
        _statCard("Wind", "$wind km/h", Icons.air_rounded),
        _statCard("Temp", "$temp°C", Icons.thermostat_rounded),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 28),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCommunityAlerts() {
    return _glassContainer(
      padding: 5,
      child: const ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white10,
          child: Icon(Icons.campaign_outlined, color: Colors.white70),
        ),
        title: Text("All Systems Clear",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text("Normal community activity reported.",
            style: TextStyle(color: Colors.white38, fontSize: 12)),
      ),
    );
  }

  // --- REUSABLE GLASS CONTAINER ---
  // --- REUSABLE GLASS CONTAINER WITH GLOWING BORDER ---
  Widget _glassContainer({
    required Widget child,
    Color? customColor,
    Color? customBorderColor,
    double padding = 20,
  }) {
    return Container(
      // Ang Shadow na ito ang gumagawa ng "Glow" effect
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: (customBorderColor ?? Colors.white).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: customColor ?? Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              // Mas maliwanag na White Border para mag-reflect ang glow
              border: Border.all(
                color: customBorderColor ?? Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}