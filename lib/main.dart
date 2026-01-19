import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'login.dart';
import 'register.dart';
import 'theme_provider.dart';
import 'user/user_dashboard.dart';
import 'admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GINAGAMIT DITO: Para sa Dynamic Theme ng buong App
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI-RES',
      theme: themeProvider.themeData,
      home: const AuthWrapper(),
    );
  }
}

/* =======================
   AUTH WRAPPER WITH ROLE CHECK
======================= */
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<Widget> _getHome(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final role = doc.data()?['role'] ?? 'user';
        if (role == 'admin') {
          return const AdminDashboardPage();
        }
        return UserDashboardPage(userRole: role);
      }
    } catch (e) {
      debugPrint("Error fetching role: $e");
    }
    return const UserDashboardPage(userRole: 'user');
  }

  @override
  Widget build(BuildContext context) {
    // INALIS ANG UNUSED VARIABLE: themeProvider (Line 73)
    // Hindi ito kailangan dito dahil logic lang ng Firebase ang tinitignan natin.

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<Widget>(
            future: _getHome(snapshot.data!),
            builder: (context, roleSnapshot) {
              if (!roleSnapshot.hasData) {
                return const Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(child: CircularProgressIndicator(color: Colors.blue)),
                );
              }
              return roleSnapshot.data!;
            },
          );
        }

        return const HomePage();
      },
    );
  }
}

/* =======================
   GLASS CONTAINER
======================= */
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 25,
    this.blur = 15,
  });

  @override
  Widget build(BuildContext context) {
    // GINAGAMIT DITO: Para sa theme-based background color
    final themeProvider = Provider.of<ThemeProvider>(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: themeProvider.buttonBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/* =======================
   HOME PAGE (ORIGINAL COLORS + RESPONSIVE)
======================= */
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // GINAGAMIT DITO: Para sa Theme Toggle at Gradients
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeProvider.isDarkMode
                    ? [Colors.black, Colors.blueAccent, Colors.black]
                    : [Colors.white, Colors.blue[200]!, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 180,
                      child: Image.asset(
                        'assets/images/sirens.gif',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "AI-RES",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "High Alert Simulation",
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // LOGIN BUTTON
                    GlassContainer(
                      borderRadius: 20,
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                          },
                          child: Text(
                            "LOGIN",
                            style: TextStyle(
                              color: themeProvider.buttonTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // REGISTER BUTTON
                    GlassContainer(
                      borderRadius: 20,
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                          },
                          child: Text(
                            "REGISTER",
                            style: TextStyle(
                              color: themeProvider.buttonTextColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      icon: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: themeProvider.buttonTextColor,
                      ),
                      onPressed: themeProvider.toggleTheme,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}