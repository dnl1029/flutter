import 'dart:convert';
import 'package:contact/my_flutter_app_icons.dart';
import 'package:contact/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api_client.dart';
import 'lane_assignment.dart';

void main() => runApp(BowlingScoresApp());

class BowlingScoresApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('ko', 'KR'), // 한국어 로케일 추가
      ],
      locale: const Locale('ko', 'KR'), // 앱의 기본 로케일을 한국어로 설정
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 기본 배경 색상을 흰색으로 설정
      ),
      home: BowlingScoresScreen(),
    );
  }
}

class BowlingScoresScreen extends StatefulWidget {
  @override
  _BowlingScoresScreenState createState() => _BowlingScoresScreenState();
}

class _BowlingScoresScreenState extends State<BowlingScoresScreen> {
  DateTime? selectedDate;
  List<LaneScoresData> laneScoresData = [];
  final ApiClient _apiClient = ApiClient();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await _checkAlignmentAndNavigate();
      await _fetchLaneScores();
    }
  }

  Future<void> _checkAlignmentAndNavigate() async {
    if (selectedDate == null) return;
    String formattedDate = _formatDate(selectedDate!);

    final checkAlignmentUrl = 'https://bowling-rolling.com/api/v1/score/determine/alignment';
    final checkAlignmentResponse = await _apiClient.post(context,
      checkAlignmentUrl,
      data: jsonEncode({"workDt": formattedDate}),
    );

    if (checkAlignmentResponse.statusCode == 200) {
      final result = checkAlignmentResponse.data;
      if (result == false) {
        Utils.showAlertDialog(context, '선택된 날짜의 회원별 레인 데이터가 없습니다.'
            ,onConfirmed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BowlingLanesPage()),
              );
            });
      }
    }
  }

  Future<void> _fetchLaneScores() async {
    if (selectedDate == null) return;
    String formattedDate = _formatDate(selectedDate!);

    final fetchScoresUrl = 'https://bowling-rolling.com/api/v1/score/daily/workDt';
    final fetchScoresResponse = await _apiClient.post(
      context,
      fetchScoresUrl,
      data: jsonEncode({"workDt": formattedDate}),
    );

    if (fetchScoresResponse.statusCode == 200) {
      final responseData = fetchScoresResponse.data;
      final List<dynamic> dailyScores = responseData['dailyScores'];

      setState(() {
        laneScoresData = _parseLaneScores(dailyScores);
      });
    }
  }

  List<LaneScoresData> _parseLaneScores(List<dynamic> dailyScores) {
    Map<int, Map<int, List<Player>>> lanes = {};

    for (var score in dailyScores) {
      int laneNum = score['laneNum'];
      int gameNum = score['gameNum'];
      String userName = score['userName'];

      lanes.putIfAbsent(laneNum, () => {});
      lanes[laneNum]!.putIfAbsent(gameNum, () => []);
      lanes[laneNum]![gameNum]!.add(Player(userName: userName));
    }

    List<LaneScoresData> laneScoresData = [];
    lanes.forEach((laneNum, games) {
      List<GameScoresData> gameScoresData = [];
      games.forEach((gameNum, players) {
        gameScoresData.add(GameScoresData(gameNumber: gameNum, players: players));
      });
      laneScoresData.add(LaneScoresData(laneNumber: laneNum, gameScores: gameScoresData));
    });

    return laneScoresData;
  }

  String _formatDate(DateTime date) {
    return "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            Container(
              color: Color(0xFF303F9F),
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(CustomIcons.bowling_ball, color: Colors.red),
                      SizedBox(width: 8),
                      Text('점수 기록하기', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Icon(Icons.settings, color: Colors.white, size: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BowlingLanesPage()),
                            );
                          },
                          icon: Icon(Icons.arrow_forward, size: 18),
                          label: Text('레인 관리하기 화면으로 이동'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue, // 버튼의 배경색
                            surfaceTintColor: Colors.white, // 버튼 텍스트 색
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    )

                  ),
                  SizedBox(height: 20,),
                  Row(
                    children: [
                      Text(
                        '날짜 선택: ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            _selectDate(context);
                          },
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    selectedDate != null
                                        ? '${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}'
                                        : '날짜',
                                  ),
                                ),
                                Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: laneScoresData.map((lane) {
                  return LaneScores(laneNumber: lane.laneNumber, gameScores: lane.gameScores);
                }).toList(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(width: 16,),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      surfaceTintColor: Colors.blue,
                      foregroundColor: Colors.white
                  ),
                  onPressed: (){},
                  child: Text('저장')
              )
            ],
          ),
        )
    );
  }
}

class LaneScoresData {
  final int laneNumber;
  final List<GameScoresData> gameScores;

  LaneScoresData({required this.laneNumber, required this.gameScores});
}

class GameScoresData {
  final int gameNumber;
  final List<Player> players;

  GameScoresData({required this.gameNumber, required this.players});
}

class Player {
  final String userName;

  Player({required this.userName});
}

class LaneScores extends StatelessWidget {
  final int laneNumber;
  final List<GameScoresData> gameScores;

  LaneScores({required this.laneNumber, required this.gameScores});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      child: Container(
        color: Color(0xFFF5F5F5),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lane $laneNumber',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            for (var gameScore in gameScores)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('Game ${gameScore.gameNumber}', style: TextStyle(fontSize: 16.0)),
                      SizedBox(width: 16.0),
                      IconButton(
                        icon: Icon(Icons.camera_alt, size: 30),
                        onPressed: () {
                          // Handle camera action
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8.0),
                  Table(
                    border: TableBorder.all(),
                    columnWidths: {
                      0: FixedColumnWidth(100.0),
                      1: FlexColumnWidth(),
                    },
                    children: gameScore.players.map((player) {
                      return TableRow(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.0),
                            color: Color(0xFFF5F5F5),
                            child: Text(
                              player.userName,
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8.0),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '수동 입력',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16.0),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class BowlingLanesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('레인 관리하기'),
      ),
      body: Center(
        child: Text('레인 관리하기 페이지'),
      ),
    );
  }
}
