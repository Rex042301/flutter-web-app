import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Ngayon ay ginagamit na para sa DateFormat

class AdminServices extends StatefulWidget {
  const AdminServices({super.key});

  @override
  State<AdminServices> createState() => _AdminServicesState();
}

class _AdminServicesState extends State<AdminServices> {
  final TextEditingController _messageController = TextEditingController();

  final List<String> _autoResponses = [
    "Acknowledged. Responders are on the way.",
    "Maintenance is scheduled for tomorrow.",
    "Request received. We are reviewing it.",
    "Emergency team has been dispatched.",
    "Issue resolved. Please confirm."
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black,  Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Service Requests",
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                      Text("Manage community reports and feedback", style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('service_requests')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white24));
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return _buildAdminServiceCard(context, data, docs[index].id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackPanel(BuildContext context, String docId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20
          ),
          decoration: BoxDecoration(
            color: Colors.grey[900]!.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Send Feedback", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              const Text("Quick Reply (Automated)", style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _autoResponses.map((msg) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: Colors.blueAccent.withOpacity(0.2),
                      label: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => _submitFeedback(docId, msg),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Type manual message...",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      _submitFeedback(docId, _messageController.text);
                      _messageController.clear();
                    }
                  },
                  child: const Text("SEND MANUAL FEEDBACK", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitFeedback(String docId, String message) {
    FirebaseFirestore.instance.collection('service_requests').doc(docId).update({
      'adminFeedback': message,
      'status': 'In Progress',
      'lastResponded': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  Widget _buildAdminServiceCard(BuildContext context, Map<String, dynamic> data, String docId) {
    String status = data['status'] ?? "Pending";

    // Paggamit sa DateFormat (Para mawala ang unused import warning)
    String formattedTime = "Recently";
    if (data['timestamp'] != null) {
      DateTime dt = (data['timestamp'] as Timestamp).toDate();
      formattedTime = DateFormat('MMM dd, hh:mm a').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['serviceType']?.toUpperCase() ?? "INQUIRY",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 5),
                Text(formattedTime, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 10),
                Text(data['description'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 13)),

                if (data['adminFeedback'] != null) ...[
                  const Divider(color: Colors.white10, height: 25),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text("Admin: ${data['adminFeedback']}",
                        style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],

                const SizedBox(height: 20),
                Row(
                  children: [
                    // 1. Delete Button (Compact)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmDelete(context, docId),
                    ),

                    const Spacer(),

                    // 2. Feedback Button (Wrapped in Flexible to prevent overflow)
                    Flexible(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.message_outlined, size: 16),
                        label: const Text(
                          "FEEDBACK",
                          style: TextStyle(fontSize: 10), // Mas maliit na font
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () => _showFeedbackPanel(context, docId),
                      ),
                    ),

                    const SizedBox(width: 5),

                    // 3. Done Button (Maliit at Compact)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // Mas manipis
                        minimumSize: const Size(50, 30), // Liit na size
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => FirebaseFirestore.instance
                          .collection('service_requests')
                          .doc(docId)
                          .update({'status': 'Completed'}),
                      child: const Text("DONE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == "Completed" ? Colors.greenAccent : (status == "In Progress" ? Colors.blueAccent : Colors.orangeAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text("Delete?", style: TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
        TextButton(onPressed: () { FirebaseFirestore.instance.collection('service_requests').doc(docId).delete(); Navigator.pop(context); },
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent))),
      ],
    ));
  }
}