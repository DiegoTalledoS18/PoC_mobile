import 'package:flutter/material.dart';
import 'upload_pdf.dart';

class Homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.red, // Cambia el color del botón a rojo
          ),
          child: Text("Subir un PDF"),
          onPressed: () {
            // Navega a la pantalla de UploadPDF
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UploadPDF()),
            );
          },
        ),
      ),
    );
  }
}
