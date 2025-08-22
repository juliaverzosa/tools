import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({Key? key}) : super(key: key);

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _isLoading = false;
  String _statusMessage = "";

  Future<void> _importExcelFile() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = "Selecting file...";
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = "No file selected.";
        });
        return;
      }

      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Excel file has no sheets.";
        });
        return;
      }

      var sheet = excel.tables.values.first;

      // Validate header size
      if (sheet.rows.length < 2 || sheet.rows[0].length < 2) {
        setState(() {
          _isLoading = false;
          _statusMessage =
              "Excel format invalid. Must have at least 1 tool row and 1 technician column.";
        });
        return;
      }

      setState(() {
        _statusMessage = "Importing data...";
      });

      // Extract technicians from the first row
      List<String> technicians = [];
      for (int col = 1; col < sheet.rows[0].length; col++) {
        final techName = sheet.rows[0][col]?.value.toString().trim() ?? "";
        technicians.add(techName.isNotEmpty ? techName : "Unknown Tech $col");
      }

      // Loop through rows for tools
      for (int row = 1; row < sheet.rows.length; row++) {
        final toolName = sheet.rows[row][0]?.value.toString().trim() ?? "";
        if (toolName.isEmpty) continue;

        // Create tool in Firestore
        final toolDoc =
            await FirebaseFirestore.instance.collection('tools').add({
          'name': toolName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Loop through each technician’s status
        for (int col = 1; col < sheet.rows[row].length; col++) {
          final techName = technicians[col - 1];
          final toolStatus =
              sheet.rows[row][col]?.value.toString().trim() ?? "none";

          await FirebaseFirestore.instance.collection('checksHistory').add({
            'toolId': toolDoc.id,
            'toolName': toolName,
            'technician': techName,
            'status': toolStatus,
            'date': FieldValue.serverTimestamp(),
          });
        }
      }

      setState(() {
        _isLoading = false;
        _statusMessage = "Import completed successfully!";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Import Excel File"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Select Excel File"),
                      onPressed: _importExcelFile,
                    ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
