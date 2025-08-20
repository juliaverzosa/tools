import 'package:flutter/material.dart';

class ToolsSettingsPage extends StatefulWidget {
  const ToolsSettingsPage({Key? key}) : super(key: key);

  @override
  State<ToolsSettingsPage> createState() => _ToolsSettingsPageState();
}

class _ToolsSettingsPageState extends State<ToolsSettingsPage> {
  Map<String, List<String>> categories = {
    "PPE": ["Hard Hat", "Safety Belt", "Safety Shoes"],
    "Common Tools": ["Screwdriver", "Pliers", "Wrench"],
  };

  void _addCategory() async {
    final name = await _showTextDialog("New Category");
    if (name != null && name.trim().isNotEmpty) {
      setState(() => categories[name] = []);
    }
  }

  void _editCategory(String oldName) async {
    final newName = await _showTextDialog("Edit Category", oldValue: oldName);
    if (newName != null && newName.trim().isNotEmpty) {
      setState(() {
        categories[newName] = categories.remove(oldName) ?? [];
      });
    }
  }

  void _addTool(String category) async {
    final name = await _showTextDialog("New Tool");
    if (name != null && name.trim().isNotEmpty) {
      setState(() => categories[category]!.add(name));
    }
  }

  void _editTool(String category, int index) async {
    final oldName = categories[category]![index];
    final newName = await _showTextDialog("Edit Tool", oldValue: oldName);
    if (newName != null && newName.trim().isNotEmpty) {
      setState(() => categories[category]![index] = newName);
    }
  }

  Future<String?> _showTextDialog(String title, {String oldValue = ""}) {
    final controller = TextEditingController(text: oldValue);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Save")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Tools Checklist", style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF062481),
        actions: [
          IconButton(icon: const Icon(Icons.add), color: Colors.white, onPressed: _addCategory),
        ],
      ),
      body: ListView(
        children: categories.entries.map((entry) {
          final category = entry.key;
          final tools = entry.value;
          return ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editCategory(category);
                    if (value == 'delete') setState(() => categories.remove(category));
                    if (value == 'add_tool') _addTool(category);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'add_tool', child: Text("Add Tool")),
                    const PopupMenuItem(value: 'edit', child: Text("Edit Category")),
                    const PopupMenuItem(value: 'delete', child: Text("Delete Category")),
                  ],
                )
              ],
            ),
            children: tools.asMap().entries.map((e) {
              final i = e.key;
              final tool = e.value;
              return ListTile(
                title: Text(tool),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _editTool(category, i);
                    if (value == 'delete') setState(() => tools.removeAt(i));
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text("Edit")),
                    const PopupMenuItem(value: 'delete', child: Text("Delete")),
                  ],
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
