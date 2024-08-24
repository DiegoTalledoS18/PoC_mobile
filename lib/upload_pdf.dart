import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class UploadPDF extends StatelessWidget {
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
        // Si la solicitud fue exitosa, muestra la respuesta
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Respuesta del servidor'),
            content: SingleChildScrollView(
              child: Text(response.body),
            ),
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
      } else {
        // Si la solicitud falló, muestra un mensaje de error
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
      // Si ocurre un error en la solicitud, muestra un mensaje de error
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
              PlatformFile file = result.files.first;
              FirebaseStorage storage = FirebaseStorage.instance;
              Reference ref = storage.ref().child('uploads/${file.name}');

              // Crea un metadata con el tipo MIME
              final metadata = SettableMetadata(
                contentType: 'application/pdf',
              );

              // Sube el archivo con el metadata
              UploadTask uploadTask = ref.putFile(
                File(file.path!),
                metadata,
              );

              TaskSnapshot taskSnapshot = await uploadTask;
              String downloadUrl = await taskSnapshot.ref.getDownloadURL();

              // Procesa el PDF subido
              await _processUploadedPDF(context, downloadUrl);
            } else {
              // El usuario canceló la selección del archivo
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