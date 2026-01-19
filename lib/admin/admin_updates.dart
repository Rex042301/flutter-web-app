import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUpdates extends StatefulWidget {
  const AdminUpdates({super.key});

  @override
  State<AdminUpdates> createState() => _AdminUpdatesState();
}

class _AdminUpdatesState extends State<AdminUpdates> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  // --- LOGIC: SEND BROADCAST ---
  Future<void> _postUpdate() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }
    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('broadcasts').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Alert',
      });
      _titleController.clear();
      _messageController.clear();
      _showSnackBar("Broadcast sent successfully!");
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // --- LOGIC: EDIT BROADCAST ---
  Future<void> _editUpdate(String docId, String newTitle, String newMessage) async {
    try {
      await FirebaseFirestore.instance.collection('broadcasts').doc(docId).update({
        'title': newTitle,
        'message': newMessage,
      });
      if (mounted) Navigator.pop(context);
      _showSnackBar("Updated successfully!");
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.blueAccent)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // PURE BLACK
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Broadcast Updates",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
              ),
              const Text("Notify all residents instantly", style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 35),

              // CREATE BROADCAST FORM
              _buildGlowingForm(),

              const SizedBox(height: 45),
              const Text(
                "Recent Announcements",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
              ),
              const SizedBox(height: 15),

              // LIST OF RECENT BROADCASTS
              _buildRecentUpdatesList(),
              const SizedBox(height: 120), // Padding para sa Floating Navbar
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET: GLOWING FORM ---
  Widget _buildGlowingForm() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.06),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              // GLOWING WHITE BORDER
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
            ),
            child: Column(
              children: [
                _customTextField(_titleController, "Announcement Title", 1),
                const SizedBox(height: 15),
                _customTextField(_messageController, "Write your message here...", 4),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 10,
                      shadowColor: Colors.blueAccent.withOpacity(0.3),
                    ),
                    onPressed: _isSending ? null : _postUpdate,
                    child: _isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("SEND BROADCAST", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // REUSABLE TEXT FIELD
  Widget _customTextField(TextEditingController ctrl, String hint, int lines) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        contentPadding: const EdgeInsets.all(18),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1))
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blueAccent)
        ),
      ),
    );
  }

  // --- WIDGET: RECENT UPDATES LIST ---
  Widget _buildRecentUpdatesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('broadcasts').orderBy('timestamp', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No broadcasts found.", style: TextStyle(color: Colors.white24)));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
                color: Colors.white.withOpacity(0.05),
              ),
              child: ListTile(
                onTap: () => _showEditPanel(context, docId, data),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.campaign_rounded, color: Colors.blueAccent, size: 24),
                ),
                title: Text(data['title'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(data['message'] ?? "", style: const TextStyle(color: Colors.white38), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.edit_note_rounded, color: Colors.white24),
              ),
            );
          },
        );
      },
    );
  }

  // --- EDIT PANEL ---
  void _showEditPanel(BuildContext context, String docId, Map<String, dynamic> data) {
    TextEditingController editTitle = TextEditingController(text: data['title']);
    TextEditingController editMsg = TextEditingController(text: data['message']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 25, right: 25, top: 25),
          decoration: BoxDecoration(
              color: const Color(0xFF121212).withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              border: Border.all(color: Colors.white.withOpacity(0.1))
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Edit Announcement", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _customTextField(editTitle, "Title", 1),
              const SizedBox(height: 15),
              _customTextField(editMsg, "Message", 6),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        FirebaseFirestore.instance.collection('broadcasts').doc(docId).delete();
                        Navigator.pop(context);
                        _showSnackBar("Deleted successfully");
                      },
                      child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () => _editUpdate(docId, editTitle.text, editMsg.text),
                      child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}