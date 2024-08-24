import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:poc_mobile/upload_pdf.dart';
import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upload PDF App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UploadPDF(),
    );
  }
}
