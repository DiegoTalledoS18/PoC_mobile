import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart'; // Importa el paquete para generar UUIDs
import 'questionspage.dart';

class UploadPDF extends StatefulWidget {
  @override
  _UploadPDFState createState() => _UploadPDFState();
}

class _UploadPDFState extends State<UploadPDF> {
  Future<void> _processUploadedPDF(BuildContext context, String downloadUrl) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/process_pdf_gemini/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'pdf_url': downloadUrl,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        hideLoadingDialog(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsPage(questions: data),
          ),
        );
      } else {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Error en la solicitud: ${response.statusCode}'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Error al procesar el PDF: $e'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Cargando'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Por favor, espere...'),
          ],
        ),
      ),
    );
  }

  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subir PDF'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text("Seleccionar y subir PDF"),
          onPressed: () async {

            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );


            if (result != null) {

              showLoadingDialog(context);

              PlatformFile file = result.files.first;
              FirebaseStorage storage = FirebaseStorage.instance;

              // Genera un UUID
              var uuid = Uuid();
              String uniqueId = uuid.v4();

              // Crea un nombre único para el archivo
              String uniqueFileName = '${uniqueId}_${file.name}';

              Reference ref = storage.ref().child('uploads/$uniqueFileName');

              final metadata = SettableMetadata(
                contentType: 'application/pdf',
              );

              UploadTask uploadTask = ref.putFile(
                File(file.path!),
                metadata,
              );

              TaskSnapshot taskSnapshot = await uploadTask;
              String downloadUrl = await taskSnapshot.ref.getDownloadURL();

              await _processUploadedPDF(context, downloadUrl);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No se seleccionó ningún archivo')),
              );
            }
          },
        ),
      ),
    );
  }
}
