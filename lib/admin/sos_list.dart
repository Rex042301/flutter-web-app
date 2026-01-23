import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SosListPage extends StatelessWidget {
  const SosListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Active SOS List",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos_triggers')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.shield_rounded,
                      color: Colors.white10, size: 50),
                  SizedBox(height: 15),
                  Text(
                    "No Active SOS",
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final Timestamp timestamp = data['time'] ?? Timestamp.now();
              final time = timestamp.toDate();

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white10,
                  border: Border.all(color: Colors.white24),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                    data['userId']?.toString().split('@')[0].toUpperCase() ??
                        "UNKNOWN",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Time: ${time.toLocal().toString().split('.')[0]}",
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white24, size: 16),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
