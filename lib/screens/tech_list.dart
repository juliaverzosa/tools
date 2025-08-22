import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import '/screens/tools_checklist.dart';
import '/screens/add_tech.dart';
import '/screens/edit_tech.dart';
import '/screens/tech_details.dart';

class TechnicianListScreen extends StatefulWidget {
  const TechnicianListScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianListScreen> createState() => _TechnicianListScreenState();
}

class _TechnicianListScreenState extends State<TechnicianListScreen> {
  String searchQuery = "";
  bool sortAZ = true; // controls A-Z or Z-A

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Not yet";
    final dt = timestamp.toDate();
    return DateFormat("MMMM d, yyyy h:mm a").format(dt);
  }

  Future<bool> _confirmDelete() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text('Are you sure you want to delete this technician?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ white background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: const Color(0xFF062481),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Technicians",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search...',
                            ),
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.toLowerCase();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            sortAZ = !sortAZ;
                          });
                        },
                        child: Text(
                          sortAZ ? "A → Z" : "Z → A",
                          style: const TextStyle(color: Color(0xFF062481)),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddTechnicianPage()),
                          );
                          if (result == true) setState(() {});
                        },
                        child: const Text("Add"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Technician List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('technicians')
                    .orderBy('lastChecked', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Error loading technicians"));
                  if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filter + case-insensitive sort
                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    return name.contains(searchQuery);
                  }).toList();

                  docs.sort((a, b) {
                    final nameA = (a['name'] ?? '').toString().toLowerCase();
                    final nameB = (b['name'] ?? '').toString().toLowerCase();
                    return sortAZ ? nameA.compareTo(nameB) : nameB.compareTo(nameA);
                  });

                  if (docs.isEmpty) return const Center(child: Text("No technicians found"));

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final id = docs[index].id;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Last checked: ${formatDate(data['lastChecked'])}",
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                color: Colors.white,
                                onSelected: (value) async {
                                  if (value == 'view') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TechnicianDetailsPage(
                                          technicianId: id,
                                        ),
                                      ),
                                    );
                                  } else if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditTechnicianPage(
                                          id: id,
                                          name: data['name'] ?? '',
                                          cluster: data['cluster'] ?? '',
                                        ),
                                      ),
                                    ).then((result) {
                                      if (result == true) setState(() {});
                                    });
                                  } else if (value == 'delete') {
                                    bool confirm = await _confirmDelete();
                                    if (confirm) {
                                      await FirebaseFirestore.instance
                                          .collection('technicians')
                                          .doc(id)
                                          .delete();

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Technician deleted successfully'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'view', child: Text('View')),
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade100,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ToolsScreen(
                                    technicianId: id,
                                    technicianName: data['name'] ?? '',
                                    lastChecked: formatDate(data['lastChecked']),
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "Tools",
                              style: TextStyle(color: Color(0xFF062481)),
                            ),
                          ),
                          const Divider(height: 20),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: 1,
        selectedItemColor: const Color(0xFF062481),
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Technicians'),
        ],
      ),
    );
  }
}
