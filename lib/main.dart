import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '/screens/login.dart'; // your signup page


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the correct options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "NK Tools",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(), // start with signup (or login)
    );
  }
}
