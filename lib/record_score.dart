import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:contact/my_flutter_app_icons.dart';
import 'package:contact/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'lane_assignment.dart';
import 'main_screen.dart';

// void main() => runApp(BowlingScoresApp());

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

// 진행 상황 표시 커스텀 위젯 수정
class PercentIndicator extends StatelessWidget {
  final double progress;

  const PercentIndicator({Key? key, required this.progress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 150, // 원의 크기를 더 크게 설정
          height: 150,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 8.0,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            backgroundColor: Colors.grey[200],
          ),
        ),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 36, // 글자 크기를 더 크게 설정
            fontWeight: FontWeight.bold,
            color: Colors.white,
            decoration: TextDecoration.none, // 밑줄 없애기
          ),
        ),
      ],
    );
  }
}

class _BowlingScoresScreenState extends State<BowlingScoresScreen> {
  DateTime? selectedDate;
  List<LaneScoresData> laneScoresData = [];
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker(); // 이미지 선택을 위한 객체 생성
  bool _isLoading = false; // 로딩 상태를 나타내는 변수
  double _progress = 0.0; // 진행 상황을 나타내는 변수

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      locale: const Locale('ko', 'KR'), // DatePicker 위젯에 한국어 로케일 추가
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
                context, // context 추가
                MaterialPageRoute(
                  builder: (context) => BowlingLanesPage(selectedDate: selectedDate),
                ),
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

        // laneNumber와 gameNumber로 정렬
        laneScoresData.sort((a, b) => a.laneNumber.compareTo(b.laneNumber));
        for (var lane in laneScoresData) {
          lane.gameScores.sort((a, b) => a.gameNumber.compareTo(b.gameNumber));
          for (var game in lane.gameScores) {
            game.players.sort((a, b) => a.laneOrder.compareTo(b.laneOrder));
          }
        }
      });
    }
  }


  List<LaneScoresData> _parseLaneScores(List<dynamic> dailyScores) {
    Map<int, Map<int, List<Player>>> lanes = {};

    for (var score in dailyScores) {
      int laneNum = score['laneNum'];
      int gameNum = score['gameNum'];
      String userName = score['userName'];
      int userId = score['userId'];
      int laneOrder = score['laneOrder']; // laneOrder 추가

      lanes.putIfAbsent(laneNum, () => {});
      lanes[laneNum]!.putIfAbsent(gameNum, () => []);

      Player player = Player(userName: userName, userId: userId, laneOrder: laneOrder);
      player.scoreController.text = score['score']?.toString() ?? '';  // Null일 경우 빈 문자열 설정

      lanes[laneNum]![gameNum]!.add(player);
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

  // 업로드 버튼 클릭 시 이미지 업로드 함수 수정
  Future<void> _handleCameraAction(GameScoresData gameScore) async {
    // final XFile? image = await _picker.pickImage(source: ImageSource.camera); // 기존 코드
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery); // 수정된 코드
    if (image == null) return;

    setState(() {
      _isLoading = true; // 로딩 상태 시작
      _progress = 0.0; // 진행 상황 초기화
    });

    try {
      // 6초 동안 진행 상태를 업데이트하는 예제
      const totalDuration = 6; // 총 6초
      const interval = 0.1; // 0.1초마다 업데이트
      for (int i = 1; i <= totalDuration / interval; i++) {
        await Future.delayed(Duration(milliseconds: (interval * 1000).toInt()));
        setState(() {
          _progress = i / (totalDuration / interval);
        });
      }

      final response = await _apiClient.uploadFile(
        context,
        'https://bowling-rolling.com/api/gpt/upload/gpt/extract/content',
        image,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        final statusCode = responseData['status_code'];
        final content = responseData['content'];

        if (statusCode == "200" &&
            content is List &&
            content.length == gameScore.players.length &&
            content.every((score) => score is int && score >= 0 && score <= 300)) {

          // 정상 응답 처리
          setState(() {
            for (int i = 0; i < gameScore.players.length; i++) {
              gameScore.players[i].scoreController.text = content[i].toString();
            }
          });
          // 정상 응답일 때 성공 메시지 표시
          Utils.showAlertDialog(context, "점수 업로드를 성공했습니다. 사진과 다르면 직접 수정해주세요.");
        } else if (statusCode == "400") {
          // 비정상 응답 5 처리: content는 문자열로 오므로 그대로 팝업에 표시
          final errorMessage = content is String ? content : "알 수 없는 오류가 발생했습니다.";
          Utils.showAlertDialog(context, errorMessage);
        } else {
          // 비정상 응답 1, 2, 3, 4 처리
          Utils.showAlertDialog(context, "점수분석을 실패했습니다. 수동입력 해주세요.");
        }
      } else {
        // 기타 실패 처리
        print('Failed to upload image');
      }
    } catch (e) {
      print('Error during image upload: $e');
    } finally {
      setState(() {
        _isLoading = false; // 로딩 상태 종료
        _progress = 0.0; // 진행 상황 초기화
      });
    }
  }

  Future<void> _uploadAssignments() async {
    if (selectedDate == null) {
      Utils.showAlertDialog(context, '날짜를 선택해주세요.');
      return;
    }

    final String formattedDate = _formatDate(selectedDate!);

    for (var lane in laneScoresData) {
      for (var game in lane.gameScores) {
        for (var player in game.players) {
          if (player.scoreController.text.trim().isNotEmpty) {
            final data = {
              'workDt': formattedDate,
              'userId': player.userId,
              'gameNum': game.gameNumber,
              'laneNum': lane.laneNumber,
              'laneOrder': player.laneOrder, // laneOrder 사용
              'score': int.tryParse(player.scoreController.text) ?? 0,
            };

            final url = 'https://bowling-rolling.com/api/v1/score/update/andInsert';

            try {
              final response = await _apiClient.post(context, url, data: jsonEncode(data));

              if (response == null || response.statusCode != 200) {
                Utils.showAlertDialog(context, '업로드에 실패했습니다.');
                return;
              }
            } catch (e) {
              Utils.showAlertDialog(context, '업로드 중 오류가 발생했습니다.');
              return;
            }
          }
        }
      }
    }

    Utils.showAlertDialog(context, '점수 수정을 성공했습니다.');
  }




  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                              backgroundColor: Colors.blue,
                              surfaceTintColor: Colors.white,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20,),
                    Row(
                      children: [
                        Spacer(),
                        Container(
                          alignment: Alignment.centerRight,
                          width: 250,
                          child: Row(
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
                        ),
                      ],
                    ),
                    SizedBox(height: 20,),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16.0),
                  children: laneScoresData.map((lane) {
                    return LaneScores(
                      laneNumber: lane.laneNumber,
                      gameScores: lane.gameScores,
                      onCameraAction: _handleCameraAction,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            color: Colors.white,
            shape: CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 32),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.home, color: Colors.black, size: 40),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen()),
                    );
                  },
                ),
                Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    surfaceTintColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _uploadAssignments();  // 저장 버튼 클릭 시 호출
                  },
                  child: Text('저장'),
                ),
                SizedBox(width: 16),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: PercentIndicator(progress: _progress),
                ),
              ),
            ),
          ),
      ],
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
  final int userId; // userId int로 수정
  int laneOrder; // laneOrder 추가 및 초기화
  final TextEditingController scoreController = TextEditingController();

  Player({required this.userName, required this.userId, required this.laneOrder});
}


class LaneScores extends StatelessWidget {
  final int laneNumber;
  final List<GameScoresData> gameScores;
  final void Function(GameScoresData) onCameraAction; // 콜백 함수 추가

  LaneScores({required this.laneNumber, required this.gameScores, required this.onCameraAction}); // 생성자 수정

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
                          onCameraAction(gameScore); // 콜백 함수 호출
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
                              controller: player.scoreController,
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
