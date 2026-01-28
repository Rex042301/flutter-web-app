import 'package:flutter/material.dart';

class SafetyTipsPage extends StatelessWidget {
  const SafetyTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety Tips"),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          "Safety Tips Page Content",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
