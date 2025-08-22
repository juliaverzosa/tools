import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTechnicianPage extends StatefulWidget {
  final String id; // Firestore document ID
  final String name;
  final String cluster;

  const EditTechnicianPage({
    Key? key,
    required this.id,
    required this.name,
    required this.cluster,
  }) : super(key: key);

  @override
  State<EditTechnicianPage> createState() => _EditTechnicianPageState();
}

class _EditTechnicianPageState extends State<EditTechnicianPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  String? _selectedCluster; // for dropdown

  final List<String> _clusters = ["Davao North", "Davao South"];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);

    // Only set _selectedCluster if it matches allowed values
    if (_clusters.contains(widget.cluster)) {
      _selectedCluster = widget.cluster;
    } else {
      _selectedCluster = null;
    }
  }

  Future<void> _updateTechnician() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('technicians')
            .doc(widget.id)
            .update({
          'name': _nameController.text.trim(),
          'cluster': _selectedCluster,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Technician updated successfully!')),
        );

        Navigator.pop(context, true); // return true to refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating technician: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Technician',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF062481),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Name input
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              // Cluster dropdown
              DropdownButtonFormField<String>(
                value: _selectedCluster,
                items: _clusters
                    .map((cluster) =>
                        DropdownMenuItem(value: cluster, child: Text(cluster)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCluster = value),
                decoration: const InputDecoration(labelText: "Cluster"),
                validator: (value) =>
                    value == null ? 'Please select a cluster' : null,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateTechnician,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF062481),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Update Technician'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
