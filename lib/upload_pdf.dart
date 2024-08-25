import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'questionspage.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';



class UploadPDF extends StatefulWidget {
  @override
  _UploadPDFState createState() => _UploadPDFState();
}

class _UploadPDFState extends State<UploadPDF> {
  Future<void> _showLoadingDialog(BuildContext context, String message) async {
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
            Text(message),
          ],
        ),
      ),
    );
  }

  Future<void> _processUploadedPDF(BuildContext context, String downloadUrl) async {
    final timeoutDuration = Duration(seconds: 30);

    try {

      // Imprime la URL generada en la consola
      print('URL del PDF generado: $downloadUrl');

      final response = await http
          .post(
        Uri.parse('http://10.0.2.2:8000/api/process_pdf_claude/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'pdf_url': downloadUrl,
        }),
      )
          .timeout(timeoutDuration, onTimeout: () {
        Navigator.of(context).pop();
        _showErrorDialog(context, 'El proceso tomó demasiado tiempo y fue cancelado.');
        throw Exception('Timeout');
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        Navigator.of(context).pop(); // Cierra el diálogo de carga
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionsPage(questions: data),
          ),
        );
      } else {
        Navigator.of(context).pop(); // Cierra el diálogo de carga
        _showErrorDialog(context, 'Error en la solicitud: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cierra el diálogo de carga
      _showErrorDialog(context, 'Error al procesar el PDF: $e');
    }
  }


  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
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

  Future<bool> isPDFValid(File pdfFile) async {
    try {
      // Intenta leer el PDF
      final bytes = await pdfFile.readAsBytes();
      // Intenta crear un documento PDF a partir de los bytes
      PdfDocument.fromBase64String(base64Encode(bytes));
      return true;
    } catch (e) {
      // Si hay una excepción, el PDF es probablemente inválido
      print('Error al validar PDF: $e');
      return false;
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
              File pdfFile = File(file.path!);

              // Verificar si el PDF es válido
              bool isValid = await isPDFValid(pdfFile);
              if (!isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('El archivo PDF seleccionado es inválido o está corrupto.')),
                );
                return;
              }

              await _showLoadingDialog(context, 'Subiendo PDF...');

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
                pdfFile,
                metadata,
              );

              TaskSnapshot taskSnapshot = await uploadTask;
              String downloadUrl = await taskSnapshot.ref.getDownloadURL();

              Navigator.of(context).pop(); // Cierra el diálogo de carga
              await _showLoadingDialog(context, 'Generando preguntas...');

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
