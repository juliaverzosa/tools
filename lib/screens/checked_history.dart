import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllCheckedHistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> allChecks;

  const AllCheckedHistoryPage({Key? key, required this.allChecks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allChecks.length,
        itemBuilder: (context, index) {
          final check = allChecks[index];

          // safely read values
          final time = (check['timestamp'] != null)
              ? (check['timestamp']).toDate()
              : null;

          final admin = check['admin'] ?? '';
          final technician = check['technician'] ?? '';
          final team = check['team'] ?? '';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${time != null ? "${time.hour}:${time.minute} ${time.day}/${time.month}/${time.year}" : ''} - $admin",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Text(
                "$technician - $team",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Divider(height: 16),
            ],
          );
        },
      ),
    );
  }
}
