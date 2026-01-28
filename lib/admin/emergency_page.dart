import 'package:flutter/material.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency"),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text(
          "Emergency Page Content",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
