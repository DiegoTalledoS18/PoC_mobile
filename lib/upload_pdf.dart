import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadPDF extends StatelessWidget {
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
            // Selecciona el archivo PDF
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );

            if (result != null) {
              // Obtiene el archivo
              PlatformFile file = result.files.first;

              // Sube el archivo a Firebase Storage
              FirebaseStorage storage = FirebaseStorage.instance;
              Reference ref = storage.ref().child('uploads/${file.name}');
              UploadTask uploadTask = ref.putFile(File(file.path!));
              TaskSnapshot taskSnapshot = await uploadTask;

              // Obtiene la URL de descarga
              String downloadUrl = await taskSnapshot.ref.getDownloadURL();

              // Muestra la URL en un AlertDialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text('URL del archivo subido: $downloadUrl'),
                ),
              );
            } else {
              // Muestra un mensaje si no se seleccionó ningún archivo
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: Text('No se seleccionó ningún archivo'),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
