import 'dart:io';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({Key? key}) : super(key: key);

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  bool _isLoading = false;
  String _statusMessage = "";
  String _spreadsheetUrl = "";
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/spreadsheets',
    ],
  );

  Future<void> _exportExcelFile() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = "Fetching data...";
        _spreadsheetUrl = "";
      });

      // Fetch all technicians
      final techSnapshot =
          await FirebaseFirestore.instance.collection('technicians').get();
      List<String> technicians =
          techSnapshot.docs.map((doc) => doc['name'].toString()).toList();

      // Fetch all tool categories ordered by createdAt descending
      final categorySnapshot = await FirebaseFirestore.instance
          .collection('tool_categories')
          .orderBy('createdAt', descending: false)
          .get();
      
      // Create Excel
      var excelFile = excel.Excel.createExcel();
      excel.Sheet sheet = excelFile['Sheet1'];

      // Add export date in the first cell
      final now = DateTime.now();
      final formattedDate = "${_getMonthName(now.month)} ${now.day}, ${now.year}";
      sheet.appendRow([excel.TextCellValue(formattedDate)]);
      
      // Empty row after date
      sheet.appendRow([excel.TextCellValue('')]);

      // Header row: TEAMS + all technicians
      List<excel.CellValue> headerRow = ['TEAMS', ...technicians].map((item) => excel.TextCellValue(item)).toList();
      sheet.appendRow(headerRow);

      // Loop through categories
      for (var categoryDoc in categorySnapshot.docs) {
        final category = categoryDoc.data();
        final categoryName = category['name'] as String;
        final tools = category['tools'] as List<dynamic>? ?? [];
        
        // Category row
        var categoryRow = [excel.TextCellValue(categoryName.toUpperCase())];
        sheet.appendRow(categoryRow);

        // Tools under this category
        for (var toolName in tools) {
          List<excel.CellValue> row = [excel.TextCellValue(toolName)];

          // Add status for each technician
          for (var techDoc in techSnapshot.docs) {
            final techData = techDoc.data();
            final techName = techData['name'] as String;
            final techTools = techData['tools'] as Map<String, dynamic>? ?? {};
            
            // Check if this technician has this tool and get its status
            if (techTools.containsKey(toolName)) {
              String status = techTools[toolName] as String;
              row.add(excel.TextCellValue(status));
            } else {
              row.add(excel.TextCellValue(' '));
            }
          }

          sheet.appendRow(row);
        }
        
        // Removed the empty row after each category
      }

      // Save Excel file locally
      final directory = await getExternalStorageDirectory();
      String filePath = "${directory!.path}/TechToolsExport.xlsx";
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(excelFile.encode()!);

      setState(() {
        _isLoading = false;
        _statusMessage = "Export completed!\nSaved at: $filePath";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  Future<void> _exportToGoogleSheets() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = "Signing in to Google...";
        _spreadsheetUrl = "";
      });

      // Sign in to Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Google sign-in cancelled";
        });
        return;
      }

      setState(() {
        _statusMessage = "Fetching data...";
      });

      // Fetch data
      final techSnapshot = 
          await FirebaseFirestore.instance.collection('technicians').get();
      List<String> technicians = 
          techSnapshot.docs.map((doc) => doc['name'].toString()).toList();

      // Fetch categories ordered by createdAt descending
      final categorySnapshot = await FirebaseFirestore.instance
          .collection('tool_categories')
          .orderBy('createdAt', descending: false)
          .get();

      // Prepare data for Google Sheets with proper structure
      List<List<dynamic>> sheetData = [];

      // Add export date in the first cell
      final now = DateTime.now();
      final formattedDate = "${_getMonthName(now.month)} ${now.day}, ${now.year}";
      sheetData.add([formattedDate]);
      
      // Empty row after date
      sheetData.add(['']);

      // Header row
      sheetData.add(['TEAMS', ...technicians]);

      // Loop through categories
      for (var categoryDoc in categorySnapshot.docs) {
        final category = categoryDoc.data();
        final categoryName = category['name'] as String;
        final tools = category['tools'] as List<dynamic>? ?? [];
        
        // Category row
        sheetData.add([categoryName.toUpperCase()]);

        // Tools under this category
        for (var toolName in tools) {
          List<dynamic> row = [toolName];

          // Add status for each technician
          for (var techDoc in techSnapshot.docs) {
            final techData = techDoc.data();
            final techName = techData['name'] as String;
            final techTools = techData['tools'] as Map<String, dynamic>? ?? {};
            
            // Check if this technician has this tool and get its status
            if (techTools.containsKey(toolName)) {
              String status = techTools[toolName] as String;
              row.add(status);
            } else {
              row.add(' ');
            }
          }

          sheetData.add(row);
        }
        
        // Removed the empty row after each category
      }

      // Create Google Sheets client
      final authHeaders = await googleUser.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      final sheetsApi = sheets.SheetsApi(client);

      setState(() {
        _statusMessage = "Creating Google Sheet...";
      });

      // Create new spreadsheet
      final spreadsheet = sheets.Spreadsheet()
        ..properties = sheets.SpreadsheetProperties(title: 'TechTools Export ${DateTime.now()}');

      final createdSpreadsheet = await sheetsApi.spreadsheets.create(spreadsheet);
      final spreadsheetId = createdSpreadsheet.spreadsheetId!;

      // Update with data
      final valueRange = sheets.ValueRange()
        ..values = sheetData
        ..range = 'Sheet1!A1';

      await sheetsApi.spreadsheets.values.update(
        valueRange,
        spreadsheetId,
        'Sheet1!A1',
        valueInputOption: 'USER_ENTERED',
      );

      final spreadsheetUrl = 'https://docs.google.com/spreadsheets/d/$spreadsheetId/edit';

      setState(() {
        _isLoading = false;
        _statusMessage = "Google Sheet created successfully!";
        _spreadsheetUrl = spreadsheetUrl;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  Future<void> _populateExistingGoogleSheet() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = "Signing in to Google...";
        _spreadsheetUrl = "";
      });

      // Sign in to Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Google sign-in cancelled";
        });
        return;
      }

      setState(() {
        _statusMessage = "Fetching data...";
      });

      // Fetch data
      final techSnapshot = 
          await FirebaseFirestore.instance.collection('technicians').get();
      List<String> technicians = 
          techSnapshot.docs.map((doc) => doc['name'].toString()).toList();

      // Fetch categories ordered by createdAt descending
      final categorySnapshot = await FirebaseFirestore.instance
          .collection('tool_categories')
          .orderBy('createdAt', descending: false)
          .get();

      // Prepare data for Google Sheets
      List<List<dynamic>> sheetData = [];
      
      // Add export date in the first cell
      final now = DateTime.now();
      final formattedDate = "${_getMonthName(now.month)} ${now.day}, ${now.year}";
      sheetData.add([formattedDate]);
      
      // Empty row after date
      sheetData.add(['']);

      sheetData.add(['TEAMS', ...technicians]);

      // Loop through categories
      for (var categoryDoc in categorySnapshot.docs) {
        final category = categoryDoc.data();
        final categoryName = category['name'] as String;
        final tools = category['tools'] as List<dynamic>? ?? [];
        
        // Category row
        sheetData.add([categoryName.toUpperCase()]);

        // Tools under this category
        for (var toolName in tools) {
          List<dynamic> row = [toolName];

          // Add status for each technician
          for (var techDoc in techSnapshot.docs) {
            final techData = techDoc.data();
            final techName = techData['name'] as String;
            final techTools = techData['tools'] as Map<String, dynamic>? ?? {};
            
            // Check if this technician has this tool and get its status
            if (techTools.containsKey(toolName)) {
              String status = techTools[toolName] as String;
              row.add(status);
            } else {
              row.add(' ');
            }
          }

          sheetData.add(row);
        }
        
        // Removed the empty row after each category
      }

      // Use your existing spreadsheet ID
      const existingSpreadsheetId = '1MUx2wPbIxZ5jaMKBuLTJWB_TSBsaQ9SONwN9wm6J4cI';

      final authHeaders = await googleUser.authHeaders;
      final client = GoogleAuthClient(authHeaders);
      final sheetsApi = sheets.SheetsApi(client);

      setState(() {
        _statusMessage = "Updating Google Sheet...";
      });

      // Clear existing data first
      await sheetsApi.spreadsheets.values.clear(
        sheets.ClearValuesRequest(),
        existingSpreadsheetId,
        'Sheet1!A:Z',
      );

      // Update with new data
      final valueRange = sheets.ValueRange()
        ..values = sheetData
        ..range = 'Sheet1!A1';

      await sheetsApi.spreadsheets.values.update(
        valueRange,
        existingSpreadsheetId,
        'Sheet1!A1',
        valueInputOption: 'USER_ENTERED',
      );

      final spreadsheetUrl = 'https://docs.google.com/spreadsheets/d/$existingSpreadsheetId/edit';

      setState(() {
        _isLoading = false;
        _statusMessage = "Google Sheet updated successfully!";
        _spreadsheetUrl = spreadsheetUrl;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Export Data",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), 
                 centerTitle: true,
        backgroundColor:  Color(0xFF062481),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: const Color(0xFF062481),
                          ),
                          icon: const Icon(Icons.download),
                          label: const Text("Export to Excel"),
                          onPressed: _exportExcelFile,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: const Color(0xFF062481),
                          ),
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text("Create New Google Sheet"),
                          onPressed: _exportToGoogleSheets,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: const Color(0xFF062481),
                          ),
                          icon: const Icon(Icons.update),
                          label: const Text("Update Existing Google Sheet"),
                          onPressed: _populateExistingGoogleSheet,
                        ),
                      ],
                    ),
              const SizedBox(height: 20),
              Text(_statusMessage, textAlign: TextAlign.center),
              if (_spreadsheetUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                Column(
                  children: [
                    const Text("Google Sheet URL:"),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            _spreadsheetUrl,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.content_copy),
                          onPressed: () => _copyToClipboard(_spreadsheetUrl),
                          tooltip: "Copy link to clipboard",
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Helper class for authentication
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}