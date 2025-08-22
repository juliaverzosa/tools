import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tech_list.dart';
import 'tools_settings.dart';
import 'checked_history.dart';
import 'login.dart';
import 'import_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error logging out: $e")));
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "";
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return "";
      }
      return DateFormat("MMMM d, yyyy h:mm a").format(dateTime);
    } catch (_) {
      return "";
    }
  }

  bool _isWithinToday(DateTime dt) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    return !dt.isBefore(start) && dt.isBefore(end);
  }

  Future<int> _getTotalRequiredTools() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('tool_categories').get();

    int totalTools = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['tools'] is List) {
        totalTools += (data['tools'] as List).length;
      }
    }
    return totalTools;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,

      // 🔹 Drawer
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.white),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      "Admin",
                      style: TextStyle(
                        color: Color(0xFF062481),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final adminName = (data['name'] ?? "Admin").toString();

                  return Text(
                    adminName,
                    style: const TextStyle(
                      color: Color(0xFF062481),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Manage Tools"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ToolsSettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text("Import File"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ImportPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF062481), size: 28),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dashboard",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF062481),
                  ),
                ),
                const SizedBox(height: 16),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('technicians')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final technicians = snapshot.data!.docs;
                    final totalTechs = technicians.length;

                    int okCount = 0;
                    int missingCount = 0;
                    int defectiveCount = 0;
                    int checkedToday = 0;

                    for (final doc in technicians) {
                      final data =
                          (doc.data() as Map<String, dynamic>?) ?? {};

                      final tools = data['tools'];
                      if (tools is Map<String, dynamic>) {
                        tools.forEach((_, value) {
                          bool isActive = true;
                          String? status;

                          if (value is Map<String, dynamic>) {
                            isActive = value['active'] != false;
                            final raw = value['status'];
                            if (raw != null) status = raw.toString();
                          } else if (value is String) {
                            status = value;
                            final s = status.toUpperCase().trim();
                            if (s == 'INACTIVE' || s == 'REMOVED') {
                              isActive = false;
                            }
                          }

                          if (!isActive || status == null) return;

                          final s = status.toUpperCase().trim();
                          if (s == 'OK') okCount++;
                          else if (s == 'MISSING') missingCount++;
                          else if (s == 'DEFECTIVE' || s == 'DEFFECTIVE') {
                            defectiveCount++;
                          }
                        });
                      }

                      final lastChecked = data['lastChecked'];
                      DateTime? lc;
                      if (lastChecked is Timestamp) {
                        lc = lastChecked.toDate();
                      } else if (lastChecked is DateTime) {
                        lc = lastChecked;
                      } else if (lastChecked is int) {
                        lc = DateTime.fromMillisecondsSinceEpoch(lastChecked);
                      }

                      if (lc != null && _isWithinToday(lc)) {
                        checkedToday++;
                      }
                    }

                    final totalCheckedTools =
                        okCount + missingCount + defectiveCount;

                    final okPercent = totalCheckedTools > 0
                        ? ((okCount / totalCheckedTools) * 100).toInt()
                        : 0;

                    return FutureBuilder<int>(
                      future: _getTotalRequiredTools(),
                      builder: (context, totalToolsSnapshot) {
                        if (!totalToolsSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final totalRequiredTools = totalToolsSnapshot.data ?? 0;

                        final stats = [
                          {'title': 'Technicians', 'value': '$totalTechs'},
                          {
                            'title': 'Technicians Checked Today',
                            'value': '$checkedToday'
                          },
                          {'title': 'OK Tools (%)', 'value': '$okPercent%'},
                          {'title': 'Missing Tools', 'value': '$missingCount'},
                          {
                            'title': 'Defective Tools',
                            'value': '$defectiveCount'
                          },
                          {
                            'title': 'Total Tools',
                            'value': '$totalRequiredTools'
                          },
                        ];

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: stats.length,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    stats[index]['value']!,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF062481),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    stats[index]['title']!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

// 🔹 Recent Checks
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('technicians')
      .orderBy('lastChecked', descending: true)
      .limit(5)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final recentTechs = snapshot.data!.docs
        .where((doc) => (doc.data() as Map<String, dynamic>?)?['lastChecked'] != null)
        .toList();

    if (recentTechs.isEmpty) {
      return const Text("No recent checks");
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF062481),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Checks",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...recentTechs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final formattedDate = _formatDate(data['lastChecked']);
            final techName = (data['name'] ?? '').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "• ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.4,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🔹 Technician Name (first line)
                        Text(
                          techName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        // 🔹 Date & Time (second line)
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const AllCheckedHistoryPage(),
  ),
);

              },
              child: const Text(
                "See all",
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  },
),

              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF062481),
        backgroundColor: Colors.white,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TechnicianListScreen(),
              ),
            );
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Technicians',
          ),
        ],
      ),
    );
  }
}
