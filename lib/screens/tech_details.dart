import 'package:flutter/material.dart';

class TechnicianDetailsPage extends StatelessWidget {
  final Map<String, dynamic> technician;

  const TechnicianDetailsPage({Key? key, required this.technician})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ Handle tools saved as a Map<String, String>
    Map<String, dynamic> toolSummary =
        technician['tools'] != null ? Map<String, dynamic>.from(technician['tools']) : {};

    // ✅ Handle previous checks (optional history)
    List<dynamic> previousChecks = technician['previousChecks'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Technician Details",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF062481),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Technician Info
            Text(
              technician['name'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(technician['email'] ?? '',
                style: const TextStyle(color: Colors.grey)),
            Text(technician['phone'] ?? '',
                style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),

            // Current Tool Summary
            const Text(
              "Current Tools Summary",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (toolSummary.isNotEmpty)
              ...toolSummary.entries.map((entry) {
                final toolName = entry.key;
                final status = entry.value;

                return ListTile(
                  title: Text(toolName),
                  trailing: Text(
                    status,
                    style: TextStyle(
                      color: status == 'OK'
                          ? Colors.green
                          : (status == 'MISSING'
                              ? Colors.red
                              : Colors.orange),
                    ),
                  ),
                );
              }).toList()
            else
              const Text("No tool checklist available",
                  style: TextStyle(color: Colors.grey)),

            const Divider(height: 32),

            // Previous Checks
            const Text(
              "Previous Checks",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (previousChecks.isNotEmpty)
              ...previousChecks.map((check) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${check['date'] ?? ''} - ${check['admin'] ?? ''}",
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      check['summary'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Divider(),
                  ],
                );
              }).toList()
            else
              const Text("No previous checks recorded",
                  style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
