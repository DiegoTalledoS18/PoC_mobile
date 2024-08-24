import 'package:flutter/material.dart';

class QuestionsPage extends StatelessWidget {
  final Map<String, dynamic> questions;

  QuestionsPage({required this.questions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preguntas'),
      ),
      body: ListView.builder(
        itemCount: questions['questions'].length,
        itemBuilder: (context, index) {
          final question = questions['questions'][index];
          final questionText = question['question'];
          final alternatives = List<String>.from(question['alternatives']);
          final answerIndex = question['answer'];

          return Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questionText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ...alternatives.map((alt) {
                    final isCorrect = alternatives.indexOf(alt) == answerIndex;
                    return ListTile(
                      title: Text(alt),
                      leading: isCorrect ? Icon(Icons.check, color: Colors.green) : null,
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
