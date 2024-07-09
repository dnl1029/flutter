import 'dart:convert';
import 'dart:ui';

import 'package:contact/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'lane_assignment.dart';
import 'main_screen.dart';
import 'my_setting.dart';

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
  String? role;

  @override
  void initState() {
    super.initState();
    _apiClient.checkTokenValidity(context);
    _loadRole();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      locale: const Locale('ko', 'KR'), // DatePicker 위젯에 한국어 로케일 추가
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            dialogBackgroundColor: Colors.white, // 배경색을 흰색으로 설정
            primaryColor: Colors.blue, // 선택된 날짜의 색상을 설정
            highlightColor: Colors.blue, // 강조색을 설정
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // 헤더 배경색을 설정
              onPrimary: Colors.white, // 헤더 텍스트 색상을 설정
              surface: Colors.white, // 달력 배경색을 설정
              onSurface: Colors.black, // 달력 텍스트 색상을 설정
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      if (role == 'ADMIN') {
        await _checkAlignmentAndNavigate();
      } else {
        if (selectedDate != null) {
          await _fetchLaneScores();
        }
      }
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
      } else {
        await _fetchLaneScores();
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

  Future<void> _loadRole() async {
    final getRoleUrl = 'https://bowling-rolling.com/api/v1/get/myRole';

    try {
      final getRoleResponse = await _apiClient.get(context,getRoleUrl);


      if (getRoleResponse.statusCode == 200 &&
          getRoleResponse.data['code'] == '200') {
        setState(() {
          role = getRoleResponse
              .data['message']; // API에서 정상적으로 role을 가져옴
        });
      } else {
        print('role 가져오기 실패: ${getRoleResponse.data['message']}');
      }
    } catch (e) {
      print('role 가져오기 실패: $e');
    }
  }




  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            // leading: IconButton(
            //   icon: Icon(Icons.arrow_back),
            //   color: Colors.black,
            //   onPressed: () {
            //     Navigator.pop(context);
            //   },
            // ),
            title: Text(
              '점수 기록하기',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings),
                color: Colors.black,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsPage()),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              if (role == 'ADMIN') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => BowlingLanesPage()),
                                );
                              } else {
                                Utils.showAlertDialog(context, '관리자만 접근할 수 있는 화면입니다.');
                              }
                            },
                            icon: Icon(Icons.arrow_forward, size: 18, color: Colors.black), // 플러스 아이콘으로 변경하고 색상을 검정으로 설정
                            label: Text(
                              '레인 관리하기 화면으로 이동',
                              style: TextStyle(
                                color: Colors.black, // 텍스트 색상을 검정으로 설정
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey), // 테두리 색상을 회색으로 설정
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20), // 캡처 이미지와 유사한 둥근 모서리 설정
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 버튼 안쪽 여백 설정
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              _selectDate(context);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedDate != null
                                        ? '${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}'
                                        : '날짜 선택',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                  ),
                                  Icon(Icons.calendar_today, color: Colors.grey[700]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
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
            child: SizedBox(
              height: kBottomNavigationBarHeight,
              child: Stack(
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MainScreen()),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], // 그라데이션 색상
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: (kBottomNavigationBarHeight - 42) / 2, // 높이를 맞추기 위해 조정
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _uploadAssignments();
                      },
                      icon: Icon(Icons.save, size: 24), // 아이콘 크기 조정
                      label: Text(
                        '저장',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF42A5F5), // 밝은 하늘색으로 변경
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // padding 조정
                        elevation: 4,
                        textStyle: TextStyle(fontSize: 16),
                        minimumSize: Size(0, 50), // 버튼 높이를 홈 버튼과 맞춤
                      ),
                    ),
                  ),
                ],
              ),
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
  final void Function(GameScoresData) onCameraAction;

  LaneScores({
    required this.laneNumber,
    required this.gameScores,
    required this.onCameraAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lane $laneNumber',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.0),
        for (var gameScore in gameScores)
          Card(
            margin: EdgeInsets.symmetric(vertical: 8.0),
            color: Colors.grey[200], // Change background color to grey[200]
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Game ${gameScore.gameNumber}',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.0),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            onCameraAction(gameScore);
                          },
                          icon: Icon(Icons.camera_alt, color: Colors.blue),
                          label: Text(
                            '사진 등록',
                            style: TextStyle(color: Colors.blue),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            surfaceTintColor: Colors.white,
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.0),
                  Column(
                    children: gameScore.players.map((player) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 80.0,
                              child: Text(
                                player.userName,
                                style: TextStyle(fontSize: 16.0),
                              ),
                            ),
                            SizedBox(width: 16.0),
                            Expanded(
                              child: TextField(
                                controller: player.scoreController,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white, // Set input field background color to white
                                  hintText: '수동 입력',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}