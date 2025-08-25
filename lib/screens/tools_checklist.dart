import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ToolsScreen extends StatefulWidget {
  final String technicianName;
  final String lastChecked;
  final String technicianId;

  const ToolsScreen({
    Key? key,
    required this.technicianName,
    required this.lastChecked,
    required this.technicianId,
  }) : super(key: key);

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  Map<String, String> toolStatus = {}; // toolName -> status
  Map<String, List<String>> categories = {}; // category -> list of tools
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchToolsFromFirebase();
  }

  // Fetch categories and their tools ordered by createdAt descending
  Future<void> _fetchToolsFromFirebase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tool_categories')
          .orderBy('createdAt', descending: false) // Order by createdAt descending
          .get();

      Map<String, List<String>> data = {};
      for (var doc in snapshot.docs) {
        final categoryName = doc.get('name') as String? ?? 'Unknown';
        final tools = List<String>.from(doc.get('tools') ?? []);
        data[categoryName] = tools;

        for (var t in tools) {
          if (!toolStatus.containsKey(t)) {
            toolStatus[t] = ""; // initially no status
          }
        }
      }

      setState(() {
        categories = data;
        loading = false;
      });
    } catch (e) {
      // If ordering by createdAt fails, fall back to unordered fetch
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('tool_categories')
            .get();

        Map<String, List<String>> data = {};
        for (var doc in snapshot.docs) {
          final categoryName = doc.get('name') as String? ?? 'Unknown';
          final tools = List<String>.from(doc.get('tools') ?? []);
          data[categoryName] = tools;

          for (var t in tools) {
            if (!toolStatus.containsKey(t)) {
              toolStatus[t] = ""; // initially no status
            }
          }
        }

        setState(() {
          categories = data;
          loading = false;
        });
      } catch (fallbackError) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching tools: $fallbackError")));
      }
    }
  }

  Widget _buildToolRow(String toolName) {
    return Row(
      children: [
        Expanded(child: Text(toolName, style: const TextStyle(fontSize: 14))),
        ...['OK', 'NONE', 'MISSING', 'DEFFECTIVE'].map((status) {
          return SizedBox(
            width: 60,
            child: Transform.translate(
              offset: const Offset(-6, 0),
              child: Checkbox(
                value: toolStatus[toolName] == status,
                onChanged: (_) {
                  setState(() {
                    toolStatus[toolName] = status;
                  });
                },
              ),
            ),
          );
        }).toList()
      ],
    );
  }

  Widget _buildSection(String title, List<String> tools) {
    return ExpansionTile(
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.black87)),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  "OK",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
              SizedBox(
                width: 45,
                child: Text(
                  "NONE",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  "MISSING",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  "DEFFECTIVE",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ...tools.map(_buildToolRow).toList(),
      ],
    );
  }

  bool get allToolsChecked {
    return !toolStatus.values.any((status) => status.isEmpty);
  }

  Future<void> _saveToolStatus() async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('technicians').doc(widget.technicianId);

      final snapshot = await docRef.get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        // Save old tools + lastChecked into previousChecks before overwriting
        final currentTools = data['tools'];
        final currentLastChecked = data['lastChecked'];

        if (currentTools != null && currentLastChecked != null) {
          await docRef.update({
            'previousChecks': FieldValue.arrayUnion([
              {
                'tools': currentTools,
                'date': currentLastChecked,
                'updatedBy': "Admin Name", // put actual admin login if needed
              }
            ]),
          });
        }
      }

      // Save new status
      await docRef.update({
        'tools': toolStatus,
        'lastChecked': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Tools checklist saved successfully!")));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving tools: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF062481),
        title: const Text("Tools",
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
                
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(widget.technicianName,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF062481))),
            const SizedBox(height: 4),
            Text("Last checked: ${widget.lastChecked}",
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: categories.entries
                    .map((entry) => _buildSection(entry.key, entry.value))
                    .toList(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF062481),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: allToolsChecked ? _saveToolStatus : null,
                child: const Text("SAVE",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}