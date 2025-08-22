import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '/screens/tech_details.dart'; // ✅ import your technician details page

class AllCheckedHistoryPage extends StatelessWidget {
  const AllCheckedHistoryPage({Key? key}) : super(key: key);

  // ✅ Helper function to format date
  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat("MMMM dd, yyyy h:mm a").format(date);
    }
    return "No date recorded";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "All Checked History",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF062481),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('technicians')
            .orderBy('lastChecked', descending: true) // ✅ fetch all
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTechs = snapshot.data!.docs
              .where((doc) =>
                  (doc.data() as Map<String, dynamic>?)?['lastChecked'] != null)
              .toList();

          if (allTechs.isEmpty) {
            return const Center(child: Text("No checked history found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allTechs.length,
            itemBuilder: (context, index) {
              final doc = allTechs[index];
              final data = doc.data() as Map<String, dynamic>;
              final formattedDate = _formatDate(data['lastChecked']);
              final techName = (data['name'] ?? 'Unknown Technician').toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "• ",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Technician Name (clickable)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TechnicianDetailsPage(
                                    technicianId: doc.id, // 👈 pass ID
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              techName,
                              style: const TextStyle(
                                color:  Color(0xFF062481), // clickable but no underline
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          // 🔹 Date & Time
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
