import 'dart:convert';
import 'dart:math';

import 'package:contact/my_flutter_app_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'api_client.dart';
import 'main_screen.dart';
import 'package:flutter/services.dart';

import 'my_setting.dart'; // 추가


class BowlingLanesPage extends StatefulWidget {
  final DateTime? selectedDate; // 선택된 날짜를 전달받기 위한 변수

  // 생성자에 selectedDate 추가
  BowlingLanesPage({this.selectedDate});

  @override
  _BowlingLanesPageState createState() => _BowlingLanesPageState();
}

class _BowlingLanesPageState extends State<BowlingLanesPage> {
  List<Map<String, dynamic>> presentMembers = [];
  bool isManuallyAssigned = false;
  Map<String, int> laneAssignments = {};
  Map<String, int> orderAssignments = {};
  final ApiClient _apiClient = ApiClient();
  List<String> members = [];
  TextEditingController gameCountController = TextEditingController(text: '2'); // 디폴트2
  DateTime? selectedDate;
  List<Map<String, dynamic>> dailyScores = [];
  List<DateTime> workDates = [];
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    _apiClient.checkTokenValidity(context);

    // 전달받은 selectedDate를 초기화
    selectedDate = widget.selectedDate ?? DateTime.now();

    // 초기화 코드 추가
    presentMembers.clear();
    laneAssignments.clear();
    orderAssignments.clear();

    await _getWorkDtList(); // _selectDate 보다 먼저 getWorkDtList가 수행

    // 초기 프레임 렌더링 후 날짜 선택 다이얼로그 호출
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.selectedDate == null) {
        await _selectDate(context); // 날짜를 선택하지 않았다면 날짜 선택 다이얼로그 호출
      } else {
        await _fetchDailyScores(); // 날짜가 선택되어 있다면 바로 점수 데이터 불러오기
      }

      // _fetchDailyScores가 dailyScores를 업데이트 한 후 이를 확인
      if (dailyScores.isEmpty) {
        _showMemberSelectionDialog();
      }
    });
  }

  Future<void> _getWorkDtList() async {
    final workDtUrl = 'https://bowling-rolling.com/api/v1/score/workDtList';

    try {
      final getWorkDtResponse = await _apiClient.get(context, workDtUrl);

      if (getWorkDtResponse.statusCode == 200) {
        List<String> workDtStrings = List<String>.from(getWorkDtResponse.data['workDtList']);
        setState(() {
          workDates = workDtStrings.map((date) {
            int year = int.parse(date.substring(0, 4));
            int month = int.parse(date.substring(4, 6));
            int day = int.parse(date.substring(6, 8));
            return DateTime(year, month, day);
          }).toList();
          print('workDates : $workDates');
        });
      } else {
        throw Exception('Failed to load work dates');
      }
    } catch (e) {
      print('작업 날짜 목록 가져오기 실패: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<int>(
                        value: selectedYear,
                        items: List.generate(
                          101,
                              (index) => DropdownMenuItem(
                            value: 2020 + index,
                            child: Text((2020 + index).toString()),
                          ),
                        ),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedYear = newValue;
                              if (picked != null) {
                                picked = DateTime(selectedYear, picked!.month, picked!.day);
                              } else {
                                picked = DateTime(selectedYear, DateTime.now().month, DateTime.now().day);
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  TableCalendar(
                    locale: 'ko_KR',
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2101),
                    focusedDay: DateTime(selectedYear, picked?.month ?? DateTime.now().month),
                    selectedDayPredicate: (DateTime date) {
                      return isSameDay(picked, date);
                    },
                    onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
                      setState(() {
                        picked = selectedDay;
                      });
                      Navigator.pop(context);
                    },
                    calendarStyle: CalendarStyle(
                      tablePadding: EdgeInsets.only(bottom: 16.0),
                      cellMargin: EdgeInsets.symmetric(vertical: 4.0),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(fontSize: 14, color: Colors.black),
                      weekendStyle: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                    headerStyle: HeaderStyle(
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      titleCentered: true,
                      formatButtonVisible: false,
                    ),
                    calendarBuilders: CalendarBuilders(
                      dowBuilder: (context, day) {
                        if (day.weekday == DateTime.saturday) {
                          return Center(
                            child: Text(
                              DateFormat.E('ko_KR').format(day),
                              style: TextStyle(color: Colors.blue),
                            ),
                          );
                        } else if (day.weekday == DateTime.sunday) {
                          return Center(
                            child: Text(
                              DateFormat.E('ko_KR').format(day),
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        } else {
                          return Center(
                            child: Text(
                              DateFormat.E('ko_KR').format(day),
                              style: TextStyle(color: Colors.black),
                            ),
                          );
                        }
                      },
                      defaultBuilder: (context, date, _) {
                        if (date.weekday == DateTime.saturday) {
                          return Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(color: Colors.blue),
                            ),
                          );
                        } else if (date.weekday == DateTime.sunday) {
                          return Center(
                            child: Text(
                              '${date.day}',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return null;
                      },
                      markerBuilder: (context, date, events) {
                        if (workDates.any((workDate) => isSameDay(workDate, date))) {
                          return Center(
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '※빨간색으로 표시된 날짜는 취미반 활동날 입니다.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // 유지를 원했던 부분 추가
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await _fetchDailyScores();
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchDailyScores() async {
    if (selectedDate == null) return;

    final url = 'https://bowling-rolling.com/api/v1/score/daily/workDt';
    final response = await _apiClient.post(
      context,
      url,
      data: jsonEncode({"workDt": _formatDate(selectedDate!)}),
    );

    if (response != null && response.statusCode == 200) {
      List<dynamic> scoresJson = response.data['dailyScores'];
      setState(() {
        dailyScores = scoresJson
            .where((score) => score['gameNum'] == 1)
            .map((score) => {
          'userId': score['userId'], // userId 필드 추가
          'userName': score['userName'],
          'laneNum': score['laneNum'],
          'laneOrder': score['laneOrder']
        })
            .toList();

        //정렬
        dailyScores.sort((a, b) {
          int laneNumComparison = a['laneNum'].compareTo(b['laneNum']);
          if (laneNumComparison != 0) return laneNumComparison;
          return a['laneOrder'].compareTo(b['laneOrder']);
        });

        // `dailyScores` 기반으로 `presentMembers` 갱신
        presentMembers = dailyScores.map((score) => {
          'userId': score['userId'], // userId 필드 추가
          'userName': score['userName'].toString()
        }).toList();

        // `laneAssignments`와 `orderAssignments` 갱신
        laneAssignments.clear();
        orderAssignments.clear();

        for (var score in dailyScores) {
          laneAssignments[score['userName'].toString()] = score['laneNum'];
          orderAssignments[score['userName'].toString()] = score['laneOrder'];
        }
      });
    } else {
      _showErrorDialog('점수 데이터를 가져오는데 실패했습니다.');
    }
  }

  void _showMemberSelectionDialog() async {
    final getMembersUrl = 'https://bowling-rolling.com/api/v1/member/getAll';
    final response = await _apiClient.get(context, getMembersUrl);
    if (response.statusCode == 200) {
      List<dynamic> membersJson = response.data;
      List<Map<String, dynamic>> members = membersJson.map((member) => Map<String, dynamic>.from(member)).toList();

      // 한글 가나다순으로 정렬
      members.sort((a, b) => a['userName'].compareTo(b['userName']));

      List<String> tempSelectedMembers = dailyScores.isNotEmpty
          ? dailyScores.map((score) => score['userName'].toString()).toList()
          : List<String>.from(presentMembers.map((member) => member['userName']));

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: Text('멤버 선택'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: members.map((member) {
                      return CheckboxListTile(
                        title: Text(member['userName']),
                        value: tempSelectedMembers.contains(member['userName']),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              if (!tempSelectedMembers.contains(member['userName'])) {
                                tempSelectedMembers.add(member['userName']);
                              }
                            } else {
                              tempSelectedMembers.remove(member['userName']);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('확인'),
                    onPressed: () {
                      setState(() {
                        presentMembers = tempSelectedMembers.map((userName) =>
                            members.firstWhere((member) => member['userName'] == userName)).toList();
                        dailyScores = presentMembers.map((member) => {
                          'userId': member['userId'],
                          'userName': member['userName'],
                          'laneNum': laneAssignments[member['userName']] ?? '',
                          'laneOrder': orderAssignments[member['userName']] ?? ''
                        }).toList();
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      throw Exception('Failed to load members');
    }
  }



  void _assignRandomly(int laneCount) {
    if (presentMembers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('경고'),
          content: Text('멤버를 먼저 선택하세요.'),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    int memberCount = presentMembers.length;
    int baseCount = memberCount ~/ laneCount;
    int extra = memberCount % laneCount;

    List<int> laneSizes = List<int>.filled(laneCount, baseCount);
    for (int i = 0; i < extra; i++) {
      laneSizes[i]++;
    }

    List<Map<String, dynamic>> shuffledMembers = List<Map<String, dynamic>>.from(presentMembers)..shuffle();
    int index = 0;

    laneAssignments.clear();
    orderAssignments.clear();

    for (int i = 0; i < laneCount; i++) {
      for (int j = 0; j < laneSizes[i]; j++) {
        laneAssignments[shuffledMembers[index]['userName']] = i + 1;
        orderAssignments[shuffledMembers[index]['userName']] = j + 1;
        index++;
      }
    }

    // 수동 입력 상태를 초기화하고 dailyScores를 업데이트
    setState(() {
      isManuallyAssigned = false;
      _sortMembers();
      dailyScores = presentMembers.map((member) => {
        'userId': member['userId'], // userId 필드 추가
        'userName': member['userName'],
        'laneNum': laneAssignments[member['userName']] ?? '',
        'laneOrder': orderAssignments[member['userName']] ?? ''
      }).toList();
    });
  }

  void _showRandomAssignmentDialog() async {
    int? laneCount;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('랜덤 할당'),
              content: TextField(
                decoration: InputDecoration(
                  labelText: '원하는 레인 수를 입력하세요',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setStateInDialog(() {
                    laneCount = int.tryParse(value);
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('확인'),
                  onPressed: () {
                    if (laneCount != null && laneCount! > 0) {
                      Navigator.of(context).pop();
                      _assignRandomly(laneCount!);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSeededRandomAssignmentDialog() async {
    int? laneCount;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('1시드 할당 랜덤 배정'),
              content: TextField(
                decoration: InputDecoration(
                  labelText: '원하는 레인 수를 입력하세요',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setStateInDialog(() {
                    laneCount = int.tryParse(value);
                  });
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('취소'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('확인'),
                  onPressed: () {
                    if (laneCount != null && laneCount! > 0) {
                      Navigator.of(context).pop();
                      _assignRandomWithSeed(laneCount!);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _assignRandomWithSeed(int laneCount) async {
    if (presentMembers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('경고'),
          content: Text('멤버를 먼저 선택하세요.'),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    final url = 'https://bowling-rolling.com/api/v1/score/ranking';
    final response = await _apiClient.get(context, url);

    if (response.statusCode != 200) {
      _showErrorDialog('랭킹 데이터를 가져오는데 실패했습니다.');
      return;
    }

    List<dynamic> rankings = response.data['rankings'];
    Map<int, int> memberRankings = {};

    for (var member in presentMembers) {
      var ranking = rankings.firstWhere(
              (r) => r['userId'] == member['userId'],
          orElse: () => {});
      if (ranking.isNotEmpty) {
        memberRankings[member['userId']] = ranking['rankingByAvgScore'];
      }
    }

    List<Map<String, dynamic>> seededMembers = [];
    List<Map<String, dynamic>> unseededMembers = [];

    presentMembers.forEach((member) {
      if (memberRankings.containsKey(member['userId'])) {
        seededMembers.add(member);
      } else {
        unseededMembers.add(member);
      }
    });

    seededMembers.sort((a, b) => memberRankings[a['userId']]!.compareTo(memberRankings[b['userId']]!));

    // Calculate the number of seeded and non-seeded members
    int numSeeded = min(laneCount, seededMembers.length);
    List<Map<String, dynamic>> topSeededMembers = seededMembers.take(numSeeded).toList();
    List<Map<String, dynamic>> remainingMembers = [
      ...seededMembers.skip(numSeeded),
      ...unseededMembers
    ];

    laneAssignments.clear();
    orderAssignments.clear();

    // Step 1: Assign top seeded members to lane 1 to lane numSeeded
    Random rng = Random();
    List<int> availableLanes = List.generate(laneCount, (index) => index + 1);
    List<int> usedLanes = [];

    for (int i = 0; i < numSeeded; i++) {
      int lane = availableLanes[i];
      laneAssignments[topSeededMembers[i]['userName']] = lane;
      orderAssignments[topSeededMembers[i]['userName']] = 1;
      usedLanes.add(lane);
    }

    // Step 2: Prepare remaining members for assignment
    remainingMembers.shuffle(rng);

    // Ensure each lane gets at least 1 member
    for (int lane in availableLanes) {
      if (!usedLanes.contains(lane) && remainingMembers.isNotEmpty) {
        laneAssignments[remainingMembers.removeAt(0)['userName']] = lane;
        orderAssignments[laneAssignments.keys.last] = 1; // 1st order
      }
    }

    // Assign the rest of the remaining members to remaining lanes
    int currentLane = 1;
    int currentOrder = 2; // Start with 2 as 1 is used by top seeded members

    for (int i = 0; i < remainingMembers.length; i++) {
      if (!laneAssignments.containsKey(remainingMembers[i]['userName'])) {
        laneAssignments[remainingMembers[i]['userName']] = currentLane;
        orderAssignments[remainingMembers[i]['userName']] = currentOrder;

        currentOrder++;
        if (currentOrder > (remainingMembers.length / laneCount).ceil() + 1) {
          currentOrder = 2;
          currentLane++;
          if (currentLane > laneCount) {
            currentLane = 1;
          }
        }
      }
    }

    setState(() {
      _sortMembers();
      dailyScores = presentMembers.map((member) => {
        'userId': member['userId'],
        'userName': member['userName'],
        'laneNum': laneAssignments[member['userName']] ?? '',
        'laneOrder': orderAssignments[member['userName']] ?? ''
      }).toList();
    });

    // isManuallyAssigned를 false로 설정
    setState(() {
      isManuallyAssigned = false;
    });
  }


  void _sortMembers() {
    setState(() {
      presentMembers.sort((a, b) {
        int laneA = laneAssignments[a['userName']] ?? 0;
        int laneB = laneAssignments[b['userName']] ?? 0;
        if (laneA != laneB) {
          return laneA.compareTo(laneB);
        }
        int orderA = orderAssignments[a['userName']] ?? 0;
        int orderB = orderAssignments[b['userName']] ?? 0;
        return orderA.compareTo(orderB);
      });
    });
  }

  Future<List<Map<String, dynamic>>> _fetchScoresForUpload(int gameNum) async {
    if (selectedDate == null) return [];

    final String formattedDate = _formatDate(selectedDate!);
    final url = 'https://bowling-rolling.com/api/v1/score/daily/workDt';

    final response = await _apiClient.post(
      context,
      url,
      data: jsonEncode({"workDt": formattedDate}),
    );

    if (response != null && response.statusCode == 200) {
      List<dynamic> scoresJson = response.data['dailyScores'];

      return scoresJson
          .where((score) => score['gameNum'] == gameNum) // gameNum에 따라 필터링
          .map((score) => {
        'userId': score['userId'],
        'userName': score['userName'],
        'laneNum': score['laneNum'],
        'laneOrder': score['laneOrder'],
        'score': score['score'] // score 필드 포함
      })
          .toList();
    } else {
      _showErrorDialog('점수 데이터를 가져오는데 실패했습니다.');
      return [];
    }
  }


  Future<void> _uploadAssignments() async {
    if (selectedDate == null) {
      _showErrorDialog('날짜를 선택해주세요.');
      return;
    }

    final int gameCount = int.tryParse(gameCountController.text) ?? 2;

    for (int gameNum = 1; gameNum <= gameCount; gameNum++) {
      // 각 gameNum에 대해 점수를 가져와 dailyScores를 업데이트
      final List<Map<String, dynamic>> scoresToUpload = await _fetchScoresForUpload(gameNum);
      print('scoresToUpload for gameNum $gameNum: $scoresToUpload');

      // dailyScores 업데이트
      setState(() {
        dailyScores = dailyScores.map((existingScore) {
          // 임시적으로 형변환을 적용하여 비교
          final existingUserId = existingScore['userId'] as int?;
          final existingUserName = existingScore['userName'] as String?;
          final existingLaneNum = (existingScore['laneNum'] is String
              ? int.tryParse(existingScore['laneNum'] as String) // String을 int로 변환
              : existingScore['laneNum'] as int?);
          final existingLaneOrder = (existingScore['laneOrder'] is String
              ? int.tryParse(existingScore['laneOrder'] as String) // String을 int로 변환
              : existingScore['laneOrder'] as int?);

          final matchingScore = scoresToUpload.firstWhere(
                (apiScore) {
              final apiUserId = apiScore['userId'] as int?;
              final apiUserName = apiScore['userName'] as String?;
              final apiLaneNum = apiScore['laneNum'] as int?;
              final apiLaneOrder = apiScore['laneOrder'] as int?;
              final apiScoreValue = apiScore['score'] as int?;

              return apiUserId == existingUserId &&
                  apiUserName == existingUserName &&
                  apiLaneNum == existingLaneNum &&
                  apiLaneOrder == existingLaneOrder;
            },
            orElse: () => {
              'userId': existingUserId,
              'userName': existingUserName,
              'laneNum': existingScore['laneNum'],
              'laneOrder': existingScore['laneOrder'],
              'score': null, // 기본값으로 null을 설정
            },
          );
          print('Matching score for ${existingScore['userId']}: $matchingScore');

          return {
            ...existingScore,
            'score': matchingScore['score'] ?? existingScore['score'], // API에서 가져온 점수로 업데이트, 없으면 기존 점수 유지
          };
        }).toList();
        print('Updated dailyScores: $dailyScores');
      });

      final String formattedDate = _formatDate(selectedDate!);

      for (var score in dailyScores) {
        final userId = score['userId'] as int?;
        // POST 요청을 보낼 때는 laneNum과 laneOrder를 int로 변환
        final laneNum = (score['laneNum'] is String
            ? int.tryParse(score['laneNum'] as String) // String을 int로 변환
            : score['laneNum'] as int?);
        final laneOrder = (score['laneOrder'] is String
            ? int.tryParse(score['laneOrder'] as String) // String을 int로 변환
            : score['laneOrder'] as int?);
        final userScore = score['score'] as int?; // 점수 값 가져오기

        final data = {
          'workDt': formattedDate,
          'userId': userId,
          'gameNum': gameNum,
          'laneNum': laneNum,
          'laneOrder': laneOrder,
          'score': userScore, // score가 null일 경우 null로 처리
        };

        final url = 'https://bowling-rolling.com/api/v1/score/update/andInsert';

        try {
          print('Posting data: $data');
          final response = await _apiClient.post(context, url, data: jsonEncode(data));

          if (response == null || response.statusCode != 200) {
            _showErrorDialog('업로드에 실패했습니다.');
            return;
          }
        } catch (e) {
          _showErrorDialog('업로드 중 오류가 발생했습니다.');
          return;
        }
      }
    }

    _showSuccessDialog('레인 및 순서가 성공적으로 업로드되었습니다.');
  }


  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('성공'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('오류'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }


  void _saveAssignments() {
    Map<String, int> savedLaneAssignments = {};
    Map<String, int> savedOrderAssignments = {};

    laneAssignments.forEach((key, value) {
      savedLaneAssignments[key] = value;
    });

    orderAssignments.forEach((key, value) {
      savedOrderAssignments[key] = value;
    });

    laneAssignments = savedLaneAssignments;
    orderAssignments = savedOrderAssignments;
  }

  // 테이블 데이터를 텍스트로 변환하는 함수 추가
  String _convertTableToText() {
    // 컬럼 헤더
    StringBuffer buffer = StringBuffer();
    buffer.write("이름    Lane     순서\n");

    // 각 행 추가
    for (var score in dailyScores.isNotEmpty ? dailyScores : presentMembers) {
      String name = score['userName'] ?? '';
      String laneNum = (laneAssignments[score['userName']] is Map) ? '' : laneAssignments[score['userName']]?.toString() ?? '';
      String laneOrder = (orderAssignments[score['userName']] is Map) ? '' : orderAssignments[score['userName']]?.toString() ?? '';
      buffer.write("$name    $laneNum           $laneOrder\n");
    }

    return buffer.toString();
  }

  // 텍스트 복사 함수 추가
  void _copyTableToClipboard() {
    String tableText = _convertTableToText();
    Clipboard.setData(ClipboardData(text: tableText)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('테이블이 클립보드에 복사되었습니다.')),
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '레인 관리하기',
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
                MaterialPageRoute(builder: (context) => SettingsPage()), // 설정 페이지로 이동하도록 수정
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
            SizedBox(height: 15),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('총 몇 게임 치실 건가요?'),
                  SizedBox(width: 16),
                  Container(
                    height: 40,
                    width: 93,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: '게임 수',
                        labelStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey[400]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      keyboardType: TextInputType.number,
                      controller: gameCountController,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 멤버 수정 버튼
                OutlinedButton(
                  onPressed: _showMemberSelectionDialog,
                  child: Text(
                    '멤버 수정',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                SizedBox(width: 10),

                // 랜덤 배정 버튼
                OutlinedButton(
                  onPressed: () {
                    if (presentMembers.isEmpty) {
                      _showErrorDialog('멤버를 선택하세요.');
                      return;
                    }
                    _showRandomAssignmentDialog();
                  },
                  child: Text(
                    '랜덤 배정',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                SizedBox(width: 10),

                // 수동 배정 버튼
                OutlinedButton(
                  onPressed: () {
                    if (isManuallyAssigned) {
                      _saveAssignments();
                    }
                    setState(() {
                      isManuallyAssigned = !isManuallyAssigned;
                    });
                  },
                  child: Text(
                    '수동 배정',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 멤버 수정 버튼
                OutlinedButton(
                  onPressed: () {
                    if (presentMembers.isEmpty) {
                      _showErrorDialog('멤버를 선택하세요.');
                      return;
                    }
                    _showSeededRandomAssignmentDialog();
                  },
                  child: Text(
                    '1시드 할당 랜덤 배정',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            // SizedBox(height: 15,),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Container(
                        width: MediaQuery.of(context).size.width, // 가능한 큰 가로 사이즈
                        padding: EdgeInsets.all(16),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.grey[200],
                          ),
                          child: DataTable(
                            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[100]!),
                            border: TableBorder(
                              top: BorderSide(width: 1.5, color: Colors.black),
                              verticalInside: BorderSide(width: 0.7, color: Colors.grey[300]!),
                              horizontalInside: BorderSide(width: 0.7, color: Colors.grey[300]!),
                            ),
                            columns: [
                              DataColumn(
                                label: Text(
                                  '이름',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Lane',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  '순서',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            rows: (dailyScores.isNotEmpty
                                ? dailyScores
                                : presentMembers.map((member) {
                              return {
                                'userName': member['userName'],
                                'laneNum': (laneAssignments[member['userName']] is Map)
                                    ? ''
                                    : laneAssignments[member['userName']]?.toString() ?? '',
                                'laneOrder': (orderAssignments[member['userName']] is Map)
                                    ? ''
                                    : orderAssignments[member['userName']]?.toString() ?? ''
                              };
                            }).toList())
                                .map((score) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(score['userName'] ?? '')),
                                  DataCell(
                                    isManuallyAssigned
                                        ? TextFormField(
                                      initialValue: score['laneNum'].toString(),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isEmpty) {
                                            laneAssignments.remove(score['userName']);
                                          } else {
                                            laneAssignments[score['userName']] = int.tryParse(value) ?? 0;
                                          }
                                          dailyScores = presentMembers.map((member) => {
                                            'userId': member['userId'], // userId 필드 유지
                                            'userName': member['userName'],
                                            'laneNum': (laneAssignments[member['userName']] is Map)
                                                ? ''
                                                : laneAssignments[member['userName']]?.toString() ?? '',
                                            'laneOrder': (orderAssignments[member['userName']] is Map)
                                                ? ''
                                                : orderAssignments[member['userName']]?.toString() ?? ''
                                          }).toList();
                                        });
                                      },
                                    )
                                        : Text(score['laneNum'].toString()),
                                  ),
                                  DataCell(
                                    isManuallyAssigned
                                        ? TextFormField(
                                      initialValue: score['laneOrder'].toString(),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value.isEmpty) {
                                            orderAssignments.remove(score['userName']);
                                          } else {
                                            orderAssignments[score['userName']] = int.tryParse(value) ?? 0;
                                          }
                                          dailyScores = presentMembers.map((member) => {
                                            'userId': member['userId'], // userId 필드 유지
                                            'userName': member['userName'],
                                            'laneNum': (laneAssignments[member['userName']] is Map)
                                                ? ''
                                                : laneAssignments[member['userName']]?.toString() ?? '',
                                            'laneOrder': (orderAssignments[member['userName']] is Map)
                                                ? ''
                                                : orderAssignments[member['userName']]?.toString() ?? ''
                                          }).toList();
                                        });
                                      },
                                    )
                                        : Text(score['laneOrder'].toString()),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: kBottomNavigationBarHeight + 20, // 높이를 약간 조정하여 BottomAppBar를 위로 올림
          child: Row(
            children: [
              // 데이터 복사하기 버튼 (왼쪽)
              OutlinedButton(
                onPressed: _copyTableToClipboard,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 50), // 버튼 크기 최소화
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '데이터 복사하기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14, // 글자 크기 조정
                    ),
                  ),
                ),
              ),
              Spacer(), // 홈 버튼과 오른쪽 버튼들 사이의 간격을 조절합니다.
              // 홈 버튼 (중앙)
              GestureDetector(
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
              Spacer(), // 홈 버튼과 오른쪽 버튼들 사이의 간격을 조절합니다.
              // 삭제 버튼
              ElevatedButton(
                onPressed: () {
                  _confirmDelete();
                },
                child: Text(
                  '삭제',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  elevation: 4,
                  minimumSize: Size(0, 50), // 버튼 크기 최소화
                ),
              ),
              Spacer(), // 홈 버튼과 오른쪽 버튼들 사이의 간격을 조절합니다.
              // 저장 버튼
              ElevatedButton(
                onPressed: () {
                  validateAndSave();
                },
                child: Text(
                  '저장',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  elevation: 4,
                  minimumSize: Size(0, 50), // 버튼 크기 최소화
                ),
              ),
            ],
          ),
        ),
      ),


    );
  }

  void validateAndSave() {
    // 날짜가 선택되었는지 확인
    if (selectedDate == null) {
      _showErrorDialog('선택된 날짜가 없습니다.');
      return;
    }

    // Lane 또는 Order 할당이 누락되었는지 확인
    bool hasMissingLane = false;
    bool hasMissingOrder = false;
    List<String> duplicatedLaneOrders = [];
    List<String> incorrectLaneOrders = [];

    Map<int, Set<int>> laneOrderMap = {};

    for (var member in presentMembers) {
      if (!laneAssignments.containsKey(member['userName']) || laneAssignments[member['userName']] == 0) {
        hasMissingLane = true;
        break;
      }
      if (!orderAssignments.containsKey(member['userName']) || orderAssignments[member['userName']] == 0) {
        hasMissingOrder = true;
        break;
      }

      int lane = laneAssignments[member['userName']]!;
      int order = orderAssignments[member['userName']]!;

      if (laneOrderMap.containsKey(lane)) {
        if (laneOrderMap[lane]!.contains(order)) {
          duplicatedLaneOrders.add('$lane번');
        } else {
          laneOrderMap[lane]!.add(order);
        }
      } else {
        laneOrderMap[lane] = {order};
      }
    }

    laneOrderMap.forEach((lane, orders) {
      List<int> sortedOrders = orders.toList()..sort();
      for (int i = 0; i < sortedOrders.length; i++) {
        if (sortedOrders[i] != i + 1) {
          incorrectLaneOrders.add('$lane번');
          break;
        }
      }
    });

    if (hasMissingLane) {
      _showErrorDialog('Lane이 입력되지 않았습니다.');
    } else if (hasMissingOrder) {
      _showErrorDialog('순서가 입력되지 않았습니다.');
    } else if (duplicatedLaneOrders.isNotEmpty) {
      _showErrorDialog('${duplicatedLaneOrders.join(', ')} Lane의 순서가 중복되었습니다.');
    } else if (incorrectLaneOrders.isNotEmpty) {
      _showErrorDialog('${incorrectLaneOrders.join(', ')} Lane의 순서가 1번부터 할당되지 않았습니다.');
    } else {
      _uploadAssignments();
    }
  }

  Future<void> _confirmDelete() async {
    // 사용자가 삭제를 확인하는 대화 상자
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text('선택한 날짜의 정보가 모두 삭제됩니다. 그래도 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // 취소 버튼 클릭 시
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // 확인 버튼 클릭 시
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteDailyScores(); // 확인을 클릭하면 삭제 메서드를 호출
    }
  }

  Future<void> deleteDailyScores() async {
    if (selectedDate == null) return;

    final deleteScoresUrl = 'https://bowling-rolling.com/api/v1/score/delete/workDt';

    try {
      final response = await _apiClient.post(
        context,
        deleteScoresUrl,
        data: {"workDt": _formatDate(selectedDate!)},
      );

      // 상태 코드가 200인 경우
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['code'] == "200") {
          _showSuccessDialog('정상적으로 삭제되었습니다.');
        } else {
          _showErrorDialog('알 수 없는 오류가 발생했습니다.');
        }
      } else {
        // 상태 코드가 404인 경우
        if (response.statusCode == 404) {
          if (response.data['code'] == "RESOURCE_NOT_FOUND") {
            _showErrorDialog('해당 날짜에 삭제할 점수가 없습니다.');
          } else {
            _showErrorDialog('리소스를 찾을 수 없습니다.');
          }
        } else {
          _showErrorDialog('서버 오류가 발생했습니다.');
        }
      }
    } catch (e) {
      // 예외 발생 시 오류 메시지를 로그로 남기거나 더 구체적인 메시지를 제공
      print('Exception occurred: $e');
      _showErrorDialog('해당 날짜에 삭제할 점수가 없습니다.');
    }
  }


}