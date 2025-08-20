import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTechnicianPage extends StatefulWidget {
  const AddTechnicianPage({Key? key}) : super(key: key);

  @override
  State<AddTechnicianPage> createState() => _AddTechnicianPageState();
}

class _AddTechnicianPageState extends State<AddTechnicianPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();

  Future<void> _saveTechnician() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create a new document ID automatically
        final docRef = FirebaseFirestore.instance.collection('technicians').doc();

        await docRef.set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'contact': _phoneController.text.trim(),
          'specialty': _specialtyController.text.trim(),
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastChecked': null, // will be updated when checked later
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Technician added successfully!')),
        );

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving technician: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Technician',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                onPressed: _saveTechnician,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF062481),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save Technician'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
