import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ToolsSettingsPage extends StatefulWidget {
  const ToolsSettingsPage({Key? key}) : super(key: key);

  @override
  State<ToolsSettingsPage> createState() => _ToolsSettingsPageState();
}

class _ToolsSettingsPageState extends State<ToolsSettingsPage> {
  final CollectionReference _categoriesCollection =
      FirebaseFirestore.instance.collection('tool_categories');

  // Fetch all categories
  Future<List<DocumentSnapshot>> _fetchCategories() async {
    final snapshot = await _categoriesCollection.get();
    return snapshot.docs;
  }

  Future<String?> _showTextDialog(String title, {String oldValue = ""}) {
    final controller = TextEditingController(text: oldValue);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text("Save")),
        ],
      ),
    );
  }

  // Add a new category
  void _addCategory() async {
    final categoryName = await _showTextDialog("New Category");
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      await _categoriesCollection.add({
        'name': categoryName.trim(),
        'tools': [],
      });
      setState(() {});
    }
  }

  void _editCategory(DocumentSnapshot doc) async {
    final oldName = doc.get('name') as String? ?? '';
    final newName = await _showTextDialog("Edit Category", oldValue: oldName);
    if (newName != null && newName.trim().isNotEmpty) {
      await doc.reference.update({'name': newName.trim()});
      setState(() {});
    }
  }

  void _deleteCategory(DocumentSnapshot doc) async {
    await doc.reference.delete();
    setState(() {});
  }

  void _addTool(DocumentSnapshot categoryDoc) async {
    final toolName = await _showTextDialog("New Tool");
    if (toolName != null && toolName.trim().isNotEmpty) {
      await categoryDoc.reference.update({
        'tools': FieldValue.arrayUnion([toolName.trim()])
      });
      setState(() {});
    }
  }

  void _editTool(DocumentSnapshot categoryDoc, String oldTool) async {
    final newTool =
        await _showTextDialog("Edit Tool", oldValue: oldTool);
    if (newTool != null && newTool.trim().isNotEmpty) {
      await categoryDoc.reference.update({
        'tools': FieldValue.arrayRemove([oldTool])
      });
      await categoryDoc.reference.update({
        'tools': FieldValue.arrayUnion([newTool.trim()])
      });
      setState(() {});
    }
  }

  void _deleteTool(DocumentSnapshot categoryDoc, String tool) async {
    await categoryDoc.reference.update({
      'tools': FieldValue.arrayRemove([tool])
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Tools Checklist",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF062481),
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              color: Colors.white,
              onPressed: _addCategory),
        ],
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _fetchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No categories found"));
          }

          final categories = snapshot.data!;

          return ListView(
            children: categories.map((doc) {
              final categoryName = doc.get('name') as String? ?? '';
              final tools = List<String>.from(doc.get('tools') ?? []);

              return ExpansionTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(categoryName),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editCategory(doc);
                        if (value == 'delete') _deleteCategory(doc);
                        if (value == 'add_tool') _addTool(doc);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'add_tool', child: Text("Add Tool")),
                        const PopupMenuItem(
                            value: 'edit', child: Text("Edit Category")),
                        const PopupMenuItem(
                            value: 'delete', child: Text("Delete Category")),
                      ],
                    )
                  ],
                ),
                children: tools.map((tool) {
                  return ListTile(
                    title: Text(tool),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _editTool(doc, tool);
                        if (value == 'delete') _deleteTool(doc, tool);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text("Edit")),
                        const PopupMenuItem(
                            value: 'delete', child: Text("Delete")),
                      ],
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
