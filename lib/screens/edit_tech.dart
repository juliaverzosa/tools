import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTechnicianPage extends StatefulWidget {
  final String id; // Firestore document ID
  final String name;
  final String email;
  final String phone;
  final String address;

  const EditTechnicianPage({
    Key? key,
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  }) : super(key: key);

  @override
  State<EditTechnicianPage> createState() => _EditTechnicianPageState();
}

class _EditTechnicianPageState extends State<EditTechnicianPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specialtyController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _specialtyController = TextEditingController(text: widget.address);
  }

  Future<void> _updateTechnician() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('technicians')
            .doc(widget.id)
            .update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'contact': _phoneController.text.trim(),
          'specialty': _specialtyController.text.trim(),
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
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an email' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(labelText: 'Specialty'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a specialty' : null,
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
