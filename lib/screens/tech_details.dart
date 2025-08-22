import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TechnicianDetailsPage extends StatelessWidget {
  final String technicianId;

  const TechnicianDetailsPage({Key? key, required this.technicianId})
      : super(key: key);

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Not yet checked";
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return "Invalid date";
      }
      return DateFormat("MMMM d, yyyy h:mm a").format(dateTime);
    } catch (e) {
      return "Invalid date";
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'OK':
        return Colors.green;
      case 'MISSING':
        return Colors.red;
      case 'DEFFECTIVE':
        return Colors.orange;
      case 'NONE':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _showToolsPopup(BuildContext context, String status, List<String> tools) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _statusColor(status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text("$status Tools (${tools.length})"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: tools.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: tools.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: const Icon(Icons.build, size: 16),
                    title: Text(tools[index]),
                  ),
                )
              : const Text("No tools in this status"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  Widget _buildStatusSummaryRow(
      BuildContext context, String status, List<String> tools) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        tileColor: Colors.white,
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _statusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          status,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: _statusColor(status)),
        ),
        subtitle: Text("${tools.length} tool(s)"),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => _showToolsPopup(context, status, tools),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Technician Details",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF062481),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('technicians')
            .doc(technicianId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading technician"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Technician not found"));
          }

          final technician =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          final Map<String, dynamic> toolSummary =
              Map<String, dynamic>.from(technician['tools'] ?? {});

          // ✅ Group current tools by status
          Map<String, List<String>> toolsByStatus = {
            'OK': [],
            'NONE': [],
            'MISSING': [],
            'DEFFECTIVE': [],
          };
          toolSummary.forEach((tool, status) {
            final s = status.toString().toUpperCase();
            if (toolsByStatus.containsKey(s)) {
              toolsByStatus[s]!.add(tool);
            }
          });

          final lastChecked = technician['lastChecked'];
          final List<dynamic> previousChecks =
              technician['previousChecks'] ?? [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // ✅ Centered Technician Info
                Center(
                  child: Column(
                    children: [
                      Text(
                        technician['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        technician['cluster'] ?? '',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 32),

                // 🔹 Current Tools Summary
                const Text(
                  "Current Tools Summary",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...toolsByStatus.entries
                    .map((entry) =>
                        _buildStatusSummaryRow(context, entry.key, entry.value))
                    .toList(),

                const SizedBox(height: 8),
                Text(
                  "Last Checked: ${_formatDate(lastChecked)}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Divider(height: 32),

                // 🔹 Previous Checks (collapsible by date)
                const Text(
                  "Previous Checks",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (previousChecks.isNotEmpty)
                  ...previousChecks.map((check) {
                    final Map<String, dynamic> prevTools =
                        Map<String, dynamic>.from(check['tools'] ?? {});
                    final ts = check['date'];
                    final date = _formatDate(ts);

                    // Group prev tools
                    Map<String, List<String>> prevToolsByStatus = {
                      'OK': [],
                      'NONE': [],
                      'MISSING': [],
                      'DEFFECTIVE': [],
                    };
                    prevTools.forEach((tool, status) {
                      final s = status.toString().toUpperCase();
                      if (prevToolsByStatus.containsKey(s)) {
                        prevToolsByStatus[s]!.add(tool);
                      }
                    });

                    return ExpansionTile(
                      title: Text(
                        "Checked on $date",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      children: prevToolsByStatus.entries
                          .map((entry) => _buildStatusSummaryRow(
                              context, entry.key, entry.value))
                          .toList(),
                    );
                  }).toList()
                else
                  const Text("No previous checks recorded",
                      style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
