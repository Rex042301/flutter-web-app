import 'package:flutter/material.dart';

class EvacuationPage extends StatelessWidget {
  const EvacuationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Evacuation"),
        backgroundColor: Colors.redAccent,
      ),
      body: const Center(
        child: Text(
          "Evacuation Page Content",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
