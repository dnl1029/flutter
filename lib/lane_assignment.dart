import 'dart:convert';

import 'package:contact/my_flutter_app_icons.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';
import 'main_screen.dart';


class BowlingLanesPage extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();

    // 초기화 코드 추가
    presentMembers.clear();
    laneAssignments.clear();
    orderAssignments.clear();

    // 초기 프레임 렌더링 후 날짜 선택 다이얼로그 호출
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // BuildContext를 전달하여 _selectDate 호출
      await _selectDate(context);

      // _fetchDailyScores가 dailyScores를 업데이트 한 후 이를 확인
      if (dailyScores.isEmpty) {
        _showMemberSelectionDialog();
      }
    });
  }

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
      await _fetchDailyScores();
      // await _checkAlignmentAndNavigate();
      // await _fetchLaneScores();
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

      List<String> tempSelectedMembers = dailyScores.isNotEmpty
          ? dailyScores.map((score) => score['userName'].toString()).toList()
          : List<String>.from(presentMembers.map((member) => member['userName']));

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
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

  Future<void> _uploadAssignments() async {
    if (selectedDate == null) {
      _showErrorDialog('날짜를 선택해주세요.');
      return;
    }

    final String formattedDate = _formatDate(selectedDate!);
    final int gameCount = int.tryParse(gameCountController.text) ?? 2;

    for (int gameNum = 1; gameNum <= gameCount; gameNum++) {
      for (var score in dailyScores) {
        final userId = score['userId'];
        final laneNum = score['laneNum'];
        final laneOrder = score['laneOrder'];

        final data = {
          'workDt': formattedDate,
          'userId': userId,
          'gameNum': gameNum,
          'laneNum': laneNum,
          'laneOrder': laneOrder,
        };

        final url = 'https://bowling-rolling.com/api/v1/score/update/andInsert';

        try {
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Container(
            color: Color(0xFF303F9F),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(CustomIcons.bowling_ball, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      '레인 관리하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.settings, color: Colors.white, size: 24),
              ],
            ),
          ),
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
              SizedBox(height: 20,),
              Container(
                // padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,  // Text와 TextField의 수직 정렬 조정
                  children: [
                    Text('총 몇 게임 치실 건가요?'),
                    SizedBox(width: 16),  // Text와 TextField 사이에 적절한 간격 추가
                    Container(
                      width: 93,  // TextField의 가로 크기를 제한
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
              SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _showMemberSelectionDialog,
                    child: Text('멤버 수정'),
                  ),
                  SizedBox(width: 10,),
                  ElevatedButton(
                    onPressed: () {
                      if (presentMembers.isEmpty) {
                        // 랜덤 배정 전 선택된 멤버가 없으면 에러 표시
                        _showErrorDialog('멤버를 선택하세요.');
                        return;
                      }
                      _showRandomAssignmentDialog();
                    },
                    child: Text('랜덤 배정'),
                  ),

                  SizedBox(width: 10,),
                  // 수동 배정 버튼의 onPressed 핸들러 수정
                  ElevatedButton(
                    onPressed: () {
                      if (isManuallyAssigned) {
                        // Save the current manual assignments before toggling off
                        _saveAssignments();
                      }
                      setState(() {
                        isManuallyAssigned = !isManuallyAssigned;
                      });
                    },
                    child: Text('수동 배정'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Container(
                    width: 350,  // 원하는 너비를 지정
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('이름')),
                        DataColumn(label: Text('Lane')),
                        DataColumn(label: Text('순서')),
                      ],
                      rows: (dailyScores.isNotEmpty
                          ? dailyScores
                          : presentMembers.map((member) {
                        return {
                          'userName': member['userName'], // userName 필드 수정
                          'laneNum': (laneAssignments[member['userName']] is Map) ? '' : laneAssignments[member['userName']]?.toString() ?? '',
                          'laneOrder': (orderAssignments[member['userName']] is Map) ? '' : orderAssignments[member['userName']]?.toString() ?? ''
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
                                      'userName': member['userName'],
                                      'laneNum': (laneAssignments[member['userName']] is Map) ? '' : laneAssignments[member['userName']]?.toString() ?? '',
                                      'laneOrder': (orderAssignments[member['userName']] is Map) ? '' : orderAssignments[member['userName']]?.toString() ?? ''
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
                                      'userName': member['userName'],
                                      'laneNum': (laneAssignments[member['userName']] is Map) ? '' : laneAssignments[member['userName']]?.toString() ?? '',
                                      'laneOrder': (orderAssignments[member['userName']] is Map) ? '' : orderAssignments[member['userName']]?.toString() ?? ''
                                    }).toList();
                                  });
                                },
                              )
                                  : Text(score['laneOrder'].toString()),
                            ),
                          ],
                        );
                      }).toList(),
                    )
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 32), // 왼쪽 여백
              Spacer(),
              IconButton(
                icon: Icon(Icons.home, color: Colors.black, size: 40),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen()), // MainScreen으로 이동
                  );
                },
              ),
              Spacer(),
              buildSaveButton(),
              SizedBox(width: 16), // 오른쪽 여백
            ],
          ),
        )
    );
  }

  Widget buildSaveButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        surfaceTintColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
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
      },
      child: Text('저장'),
    );
  }
  
}