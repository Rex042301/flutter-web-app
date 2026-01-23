import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Registered Users",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.blueAccent),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return _emptyState();
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data =
                    doc.data() as Map<String, dynamic>;
                    final name =
                    (data["name"] ?? "").toString().toLowerCase();
                    final email =
                    (data["email"] ?? "").toString().toLowerCase();

                    return name.contains(_search) ||
                        email.contains(_search);
                  }).toList();

                  if (docs.isEmpty) {
                    return _emptyState();
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 900, // FIXED TABLE WIDTH
                          child: Column(
                            children: [
                              _tableHeader(),
                              const Divider(
                                  color: Colors.white24,
                                  height: 1),
                              Expanded(
                                child: ListView.builder(
                                  physics:
                                  const BouncingScrollPhysics(),
                                  itemCount: docs.length,
                                  itemBuilder:
                                      (context, index) {
                                    final doc = docs[index];
                                    final data = doc.data()
                                    as Map<String, dynamic>;

                                    return _tableRow(
                                        data, doc.id);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          setState(() {
            _search = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: "Search by name or email...",
          hintStyle:
          const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon:
          const Icon(Icons.search, color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      color: Colors.white.withOpacity(0.04),
      child: Row(
        children: const [
          _HeaderCell("NAME", 160),
          _HeaderCell("EMAIL", 240),
          _HeaderCell("PHONE", 120),
          _HeaderCell("ROLE", 100),
          _HeaderCell("STATUS", 100),
          _HeaderCell("ACTIONS", 120),
        ],
      ),
    );
  }

  Widget _tableRow(Map<String, dynamic> data, String uid) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom:
          BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          _Cell(data["name"] ?? "N/A", 160),
          _Cell(data["email"] ?? "N/A", 240),
          _Cell(data["phone"] ?? "N/A", 120),
          _Cell(data["role"] ?? "user", 100),
          _Cell(data["status"] ?? "active", 100),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.edit,
                      color: Colors.blueAccent, size: 18),
                  onPressed: () {
                    _showEditDialog(uid, data);
                  },
                ),
                const SizedBox(width: 12),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete,
                      color: Colors.redAccent, size: 18),
                  onPressed: () {
                    _confirmDelete(uid);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
      String uid, Map<String, dynamic> data) async {
    final nameController =
    TextEditingController(text: data["name"]);
    final phoneController =
    TextEditingController(text: data["phone"]);
    String role = data["role"] ?? "user";
    String status = data["status"] ?? "active";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text("Edit User",
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _dialogField("Name", nameController),
                _dialogField("Phone", phoneController),
                _dropdown("Role", role, ["user", "admin"],
                        (val) => role = val),
                _dropdown("Status", status,
                    ["active", "blocked"],
                        (val) => status = val),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.white38)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent),
              child: const Text("Save"),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .update({
                  "name": nameController.text,
                  "phone": phoneController.text,
                  "role": role,
                  "status": status,
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(String uid) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text("Delete User",
              style: TextStyle(color: Colors.white)),
          content: const Text(
            "Are you sure you want to delete this user?",
            style: TextStyle(color: Colors.white38),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.white38)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent),
              child: const Text("Delete"),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .delete();

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _dialogField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value,
      List<String> items, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(
          value: e,
          child: Text(e),
        ))
            .toList(),
        onChanged: (val) => onChanged(val!),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people_outline,
              color: Colors.white24, size: 60),
          SizedBox(height: 15),
          Text("No users found",
              style: TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.bold)),
          Text("Firebase users collection is empty",
              style: TextStyle(
                  color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _HeaderCell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final double width;

  const _Cell(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
}
