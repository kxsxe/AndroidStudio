import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../sub/detail_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class QuestionPage extends StatefulWidget {
  final Map<String, dynamic> question;

  const QuestionPage({
    super.key,
    required this.question,
  });

  @override
  State<QuestionPage> createState() => _QuestionPage();
}

class _QuestionPage extends State<QuestionPage> {
  late String title;
  int? selectedOption;

  @override
  void initState() {
    super.initState();
    title = widget.question['title'] as String;
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> selects = widget.question['selects'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question['question'] as String,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: selects.length,
                itemBuilder: (context, index) {
                  return RadioListTile<int>(
                    title: Text(selects[index] as String),
                    value: index,
                    groupValue: selectedOption,
                    onChanged: (int? value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: selectedOption == null
                    ? null
                    : () async {
                        try {
                          await FirebaseAnalytics.instance.logEvent(
                            name: 'personal_select',
                            parameters: {
                              'test_name': title,
                              'select': selectedOption ?? 0,
                            },
                          );

                          await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) {
                                return DetailPage(
                                  answer: widget.question['answer'][selectedOption],
                                  question: widget.question['question'],
                                );
                              },
                            ),
                          );
                        } catch (e) {
                          print('Failed to log event: $e');
                        }
                      },
                child: const Text('성격 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
