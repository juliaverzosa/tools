import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ToolsScreen extends StatefulWidget {
  final String technicianName;
  final String lastChecked;
  final String technicianId; // ✅ pass technician document ID

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
  final Map<String, String> toolStatus = {};

Widget _buildToolRow(String toolName) {
  return Row(
    children: [
      Expanded(
        child: Text(toolName, style: const TextStyle(fontSize: 14)),
      ),
      ...['OK', 'NONE', 'MISSING', 'DEFFECTIVE'].map((status) {
        return SizedBox(
          width: 60,
          child: Transform.translate(
            offset: const Offset(-6, 0), // 👈 move checkbox 6px to the left
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
      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        title,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      children: [
       const Padding(
  padding: EdgeInsets.symmetric(horizontal: 6.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.end, // align with the checkboxes
    children: [
      SizedBox(
        width: 40,
        child: Text(
          "OK",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ),
      SizedBox(
        width: 45,
        child: Text(
          "NONE",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ),
      SizedBox(
        width: 60,
        child: Text(
          "MISSING",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ),
      SizedBox(
        width: 80,
        child: Text(
          "DEFFECTIVE",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ),
    ],
  ),
),
        const Divider(height: 1),
        ...tools.map((tool) => _buildToolRow(tool)).toList(),
      ],
    );
  }

  Future<void> _saveToolStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(widget.technicianId) // ✅ update specific technician
          .update({
        'tools': toolStatus, // store tool status map
        'lastChecked': FieldValue.serverTimestamp(), // auto timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tools checklist saved successfully!")),
      );

      Navigator.pop(context, true); // return to refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving tools: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF062481),
        title: const Text("Tools",
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.technicianName,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF062481)),
            ),
            const SizedBox(height: 4),
            Text(
              "Last checked: ${widget.lastChecked}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildSection("PPE", [
                    "Hard Hat",
                    "Safety Belt with Strap",
                    "Safety Shoes",
                    "Safety Goggles",
                    "Insulating Rubber w/ Leather Gloves",
                    "Shoe Cover",
                    "Voltage Detector",
                    "Safety Cone",
                    "Cotton Gloves",
                  ]),
                  _buildSection("COMMON TOOLS", [
                    "Screwdriver Set",
                    "Pliers",
                    "Wrench Set",
                  ]),
                  _buildSection("ADDITIONAL TOOLS", [
                    "Cable Tester",
                    "Hammer",
                  ]),
                  _buildSection("LINE MAND HANDSET", [
                    "Handset Model X",
                  ]),
                ],
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
                onPressed: _saveToolStatus,
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
