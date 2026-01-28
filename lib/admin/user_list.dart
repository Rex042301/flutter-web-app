import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String _search = "";
  final ScrollController _horizontalScroll = ScrollController();

  // --- FUNCTION: EXPORT TO CSV ---
  Future<void> _exportUsersToCSV() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection("users").get();
      List<List<dynamic>> rows = [];

      // Header
      rows.add(["ID", "Name", "Email", "Phone", "Role", "Status"]);

      for (var i = 0; i < snapshot.docs.length; i++) {
        var data = snapshot.docs[i].data();
        rows.add([
          (i + 1).toString(),
          data["name"] ?? "N/A",
          data["email"] ?? "N/A",
          data["phone"] ?? "N/A",
          data["role"] ?? "user",
          data["status"] ?? "active",
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/Aiper_User_Database.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'Aiper User Database Export');
    } catch (e) {
      debugPrint("Export Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. DYNAMIC BACKGROUND (Same as Login)
          _buildMainBackground(),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),

                // 2. MAIN GLASS CONTAINER
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.2),
                          ),
                          child: Column(
                            children: [
                              _searchBar(),
                              Expanded(
                                child: Scrollbar(
                                  controller: _horizontalScroll,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _horizontalScroll,
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: SizedBox(
                                      width: 1100,
                                      child: Column(
                                        children: [
                                          _tableHeader(),
                                          Expanded(child: _buildUserList()),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildMainBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Color(0xFF001A33), Colors.black],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        ),
        _buildGlowCircle(top: -100, left: -50, color: Colors.blueAccent),
        _buildGlowCircle(bottom: 100, right: -80, color: Colors.indigoAccent),
      ],
    );
  }

  Widget _buildGlowCircle({double? top, double? bottom, double? left, double? right, required Color color}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 350, height: 350,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 120, spreadRadius: 60)],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("User Database",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 1)),
              Text("MANAGE ACCOUNTS & ROLES",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: _exportUsersToCSV,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3))
              ),
              child: const Icon(Icons.file_download_outlined, color: Colors.greenAccent, size: 20),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (v) => setState(() => _search = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Search by ID, Name, or Email...",
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: Colors.blueAccent, size: 20),
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: const Row(
        children: [
          _ExcelCell("ID", 70, isHeader: true),
          _ExcelCell("NAME", 180, isHeader: true),
          _ExcelCell("EMAIL", 250, isHeader: true),
          _ExcelCell("PHONE", 150, isHeader: true),
          _ExcelCell("ROLE", 120, isHeader: true),
          _ExcelCell("STATUS", 120, isHeader: true),
          _ExcelCell("ACTIONS", 110, isHeader: true),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").orderBy("createdAt", descending: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));

        final allDocs = snapshot.data!.docs;
        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data["name"] ?? "").toString().toLowerCase();
          final email = (data["email"] ?? "").toString().toLowerCase();
          final idNum = (allDocs.indexOf(doc) + 1).toString();
          return name.contains(_search) || email.contains(_search) || idNum == _search;
        }).toList();

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            int id = allDocs.indexOf(doc) + 1;
            return _excelRow(data, id, doc.id);
          },
        );
      },
    );
  }

  Widget _excelRow(Map<String, dynamic> data, int id, String uid) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03)))),
      child: Row(
        children: [
          _ExcelCell("#${id.toString().padLeft(2, '0')}", 70, color: Colors.blueAccent, isBold: true),
          _ExcelCell(data["name"] ?? "N/A", 180),
          _ExcelCell(data["email"] ?? "N/A", 250),
          _ExcelCell(data["phone"] ?? "N/A", 150),
          _ExcelCell(data["role"]?.toString().toUpperCase() ?? "USER", 120),
          _excelWidgetCell(_statusBadge(data["status"] ?? "active"), 120),
          _excelWidgetCell(_actionButtons(uid, data), 110),
        ],
      ),
    );
  }

  Widget _excelWidgetCell(Widget child, double width) {
    return Container(
      width: width, height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: child,
    );
  }

  Widget _statusBadge(String status) {
    bool isBlocked = status == "blocked";
    Color color = isBlocked ? Colors.redAccent : Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }

  Widget _actionButtons(String uid, Map<String, dynamic> data) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 22),
          onPressed: () => _showEditDialog(uid, data),
        ),
        const SizedBox(width: 5),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          onPressed: () => _confirmDelete(uid),
        ),
      ],
    );
  }

  // --- DIALOGS ---

  void _showEditDialog(String uid, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data["name"]);
    final phoneController = TextEditingController(text: data["phone"]);
    String selectedRole = data["role"] ?? "user";
    String selectedStatus = data["status"] ?? "active";

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.black.withOpacity(0.85),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: Colors.white.withOpacity(0.1))),
            title: const Text("Edit User Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField("Full Name", nameController, Icons.person_outline),
                  _dialogField("Contact Number", phoneController, Icons.phone_android_outlined),
                  _dialogDropdown("Access Role", selectedRole, ["user", "admin"], (val) => setDialogState(() => selectedRole = val!)),
                  _dialogDropdown("Account Status", selectedStatus, ["active", "blocked"], (val) => setDialogState(() => selectedStatus = val!)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection("users").doc(uid).update({
                    "name": nameController.text, "phone": phoneController.text, "role": selectedRole, "status": selectedStatus,
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("UPDATE", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String uid) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: const Text("Delete User?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text("This user will be permanently removed from the database.", style: TextStyle(color: Colors.white54, fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection("users").doc(uid).delete();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("DELETE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
          labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          filled: true, fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
        ),
      ),
    );
  }

  Widget _dialogDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value, dropdownColor: Colors.grey[900],
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          filled: true, fillColor: Colors.white.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ExcelCell extends StatelessWidget {
  final String text;
  final double width;
  final bool isHeader;
  final Color? color;
  final bool isBold;

  const _ExcelCell(this.text, this.width, {this.isHeader = false, this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Text(
        text, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color ?? (isHeader ? Colors.white38 : Colors.white.withOpacity(0.7)),
          fontWeight: isHeader || isBold ? FontWeight.w900 : FontWeight.normal,
          fontSize: isHeader ? 10 : 13,
          letterSpacing: isHeader ? 1 : 0,
        ),
      ),
    );
  }
}