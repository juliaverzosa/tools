import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tech_list.dart';
import 'tools_settings.dart';
import 'checked_history.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔔 Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.notifications_none, size: 28),
                    IconButton(
                      icon: const Icon(Icons.settings, size: 28),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ToolsSettingsPage()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  "Dashboard",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ✅ Live stats from Firestore
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

                    // Count all tool statuses
                    int okCount = 0;
                    int missingCount = 0;
                    int totalTools = 0;

                    for (var doc in technicians) {
                      final data =
                          doc.data() as Map<String, dynamic>? ?? {};
                      final tools = data['tools'] as Map<String, dynamic>? ?? {};
                      tools.forEach((_, status) {
                        totalTools++;
                        if (status == "OK") okCount++;
                        if (status == "MISSING") missingCount++;
                      });
                    }

                    final okPercent =
                        totalTools > 0 ? ((okCount / totalTools) * 100).toInt() : 0;

                    final stats = [
                      {'title': 'Technicians', 'value': '$totalTechs'},
                      {'title': 'Tools Checked Today', 'value': '$totalTools'},
                      {'title': 'OK Tools (%)', 'value': '$okPercent%'},
                      {'title': 'Missing Tools', 'value': '$missingCount'},
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
                ),
                const SizedBox(height: 24),

                // ✅ Recent Checks from Firestore
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('checks')
                      .orderBy('timestamp', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final recentChecks = snapshot.data!.docs;

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
                          ...recentChecks.map((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>? ?? {};
                            final time =
                                (data['timestamp'] as Timestamp?)?.toDate();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${time != null ? "${time.hour}:${time.minute}" : ''} - ${data['admin'] ?? ''}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${data['technician'] ?? ''} - ${data['team'] ?? ''}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AllCheckedHistoryPage(
                                      allChecks: recentChecks.map((e) {
                                        final data =
                                            e.data() as Map<String, dynamic>? ??
                                                {};
                                        return data;
                                      }).toList(),
                                    ),
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
                          )
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
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TechnicianListScreen()),
            );
          }
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: 'Technicians'),
        ],
      ),
    );
  }
}
