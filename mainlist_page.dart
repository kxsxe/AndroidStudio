import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../sub/question_page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_database/firebase_database.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPage();
}

class _MainPage extends State<MainPage> {
  final FirebaseDatabase database = FirebaseDatabase.instance;
  late DatabaseReference _testRef;

  String welcomeTitle = '';
  bool bannerUse = false;
  int itemHeight = 50;

  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  @override
  void initState() {
    super.initState();
    _testRef = database.ref('test');
    remoteConfigInit();
  }

  void remoteConfigInit() async {
    await remoteConfig.fetch();
    await remoteConfig.activate();
    setState(() {
      welcomeTitle = remoteConfig.getString('welcome');
      bannerUse = remoteConfig.getBool('banner');
      itemHeight = remoteConfig.getInt('item_height');
    });
  }

  Future<List<Map<String, dynamic>>> loadAsset() async {
    try {
      final snapshot = await _testRef.get();
      List<Map<String, dynamic>> list = [];

      for (var element in snapshot.children) {
        if (element.value is Map) {
          list.add(Map<String, dynamic>.from(element.value as Map));
        }
      }

      return list;
    } catch (e) {
      print('Failed to load data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: bannerUse
          ? AppBar(
              title: Text(welcomeTitle),
            )
          : null,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: loadAsset(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Center(
                child: CircularProgressIndicator(),
              );

            case ConnectionState.done:
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final list = snapshot.data!;

                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];

                    return InkWell(
                      onTap: () async {
                        try {
                          await FirebaseAnalytics.instance.logEvent(
                            name: 'test_click',
                            parameters: {
                              'test_name': item['title'].toString(),
                            },
                          );

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => QuestionPage(
                                question: item,
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Failed to log event: $e');
                        }
                      },
                      child: SizedBox(
                        height: itemHeight.toDouble(),
                        child: Card(
                          color: Colors.amber,
                          child: Center(
                            child: Text(
                              item['title'].toString(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              } else {
                return const Center(
                  child: Text('No Data'),
                );
              }

            default:
              return const Center(
                child: Text('No Data'),
              );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final _pushRef = database.ref('test');

          await _pushRef.push().set({
            "title": "당신이 좋아하는 애완동물은?",
            "question":
                "당신이 무인도에 도착했는데, 마침 떠내려온 상자를 열었을 때 보이는 이것은?",
            "selects": ["생존 키트", "휴대폰", "텐트", "무인도에서 살아남기"],
            "answer": [
              "당신은 현실주의! 동물은 안 키운다!!",
              "당신은 늘 함께 있는 걸 좋아하는 강아지",
              "당신은 같은 공간을 공유하는 고양이",
              "당신은 낭만을 좋아하는 앵무새"
            ],
          });

          await _pushRef.push().set({
            "title": "5초 MBTI I/E 편",
            "question": "친구와 함께 간 미술관 당신이라면?",
            "selects": ["말이 많아짐", "생각이 많아짐"],
            "answer": ["당신의 성향은 E", "당신의 성향은 I"],
          });

          await _pushRef.push().set({
            "title": "당신은 어떤 사랑을 하고 싶나요?",
            "question": "목욕을 할 때 가장 먼저 비누칠을 하는 곳은?",
            "selects": ["머리", "상체", "하체"],
            "answer": [
              "당신은 자만추를 추천해요.",
              "당신은 소개팅에서 새로운 사람을 소개받는 걸 좋아합니다.",
              "당신은 길 가다가 우연히 지나친 그런 인연을 좋아합니다."
            ],
          });
        },
      ),
    );
  }
}
