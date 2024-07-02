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
  // final List<String> members = [
  //   '위형규', '최상진', '강선주', '김다인', '김성훈', '김수현',
  //   '김재위', '김지연', '김태윤', '김혜지', '남지연',
  //   '신가인', '신현경', '안성준', '우경석', '이동현',
  //   '이민영', '이민지', '이수경', '이수민', '이은경',
  //   '장누리', '정만석', '정진홍', '조현익', '최은진'
  // ];

  List<String> presentMembers = [];
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
    // 초기 멤버 선택 다이얼로그 표시
    _showMemberSelectionDialog();
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
          'userName': score['userName'],
          'laneNum': score['laneNum'],
          'laneOrder': score['laneOrder']
        })
            .toList();

        // `dailyScores` 기반으로 `presentMembers` 갱신
        presentMembers = dailyScores.map((score) => score['userName'].toString()).toList();

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



  Future<void> _fetchMembers() async {
    final fetchMembersUrl = 'https://bowling-rolling.com/api/v1/member/getAll';
    final response = await _apiClient.get(context, fetchMembersUrl);

    if (response != null && response.statusCode == 200) {
      List<dynamic> membersJson = response.data;
      setState(() {
        presentMembers = membersJson.map<String>((member) => member['userName'].toString()).toList();
      });
      // 멤버 데이터를 가져온 후에 멤버 선택 다이얼로그를 열도록 함
      _showMemberSelectionDialog();
    } else {
      _showErrorDialog('멤버 데이터를 가져오는데 실패했습니다.');
    }
  }

  void _showMemberSelectionDialog() async {
    final getMembersUrl = 'https://bowling-rolling.com/api/v1/member/getAll';
    final response = await _apiClient.get(context, getMembersUrl);
    if (response.statusCode == 200) {
      List<dynamic> members = response.data;

      // 전체 멤버 리스트와 현재 선택된 멤버 리스트를 비교하여 체크박스 상태를 설정
      List<String> tempSelectedMembers = dailyScores.isNotEmpty
          ? dailyScores.map((score) => score['userName'].toString()).toList()
          : List<String>.from(presentMembers);

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
                        presentMembers = tempSelectedMembers.toSet().toList();
                        dailyScores = presentMembers.map((member) => {
                          'userName': member,
                          'laneNum': laneAssignments[member] ?? '',
                          'laneOrder': orderAssignments[member] ?? ''
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

    List<String> shuffledMembers = List<String>.from(presentMembers)..shuffle();
    int index = 0;

    laneAssignments.clear();
    orderAssignments.clear();

    for (int i = 0; i < laneCount; i++) {
      for (int j = 0; j < laneSizes[i]; j++) {
        laneAssignments[shuffledMembers[index]] = i + 1;
        orderAssignments[shuffledMembers[index]] = j + 1;
        index++;
      }
    }

    setState(() {
      _sortMembers();
      dailyScores = presentMembers.map((member) => {
        'userName': member,
        'laneNum': laneAssignments[member] ?? '',
        'laneOrder': orderAssignments[member] ?? ''
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
              actions: [
                TextButton(
                  child: Text('확인'),
                  onPressed: () {
                    if (laneCount != null && laneCount! > 0) {
                      setState(() {
                        _assignRandomly(laneCount!);
                      });
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pop();
                      _showErrorDialog('숫자를 입력해주세요');
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
    presentMembers.sort((a, b) {
      int laneComparison = (laneAssignments[a] ?? 0).compareTo(laneAssignments[b] ?? 0);
      if (laneComparison != 0) return laneComparison;
      return (orderAssignments[a] ?? 0).compareTo(orderAssignments[b] ?? 0);
    });
  }

  Future<void> _uploadAssignments() async {
    List<Map<String, dynamic>> assignments = presentMembers.map((member) {
      return {
        'userName': member,
        'laneNum': laneAssignments[member],
        'laneOrder': orderAssignments[member],
        'playYn': 'Y',
        'gameCnt': int.tryParse(gameCountController.text) ?? 2,
      };
    }).toList();

    final url = 'https://bowling-rolling.com/api/v1/score/laneOrder';
    final response = await _apiClient.post(
      context,
      url,
      data: jsonEncode(assignments),
    );

    if (response != null && response.statusCode == 200) {
      _showSuccessDialog('레인 및 순서가 성공적으로 업로드되었습니다.');
    } else {
      _showErrorDialog('레인 및 순서 업로드에 실패했습니다.');
    }
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
                          'userName': member,
                          'laneNum': laneAssignments[member]?.toString() ?? '',
                          'laneOrder': orderAssignments[member]?.toString() ?? ''
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
                                    // Update dailyScores to reflect changes
                                    score['laneNum'] = laneAssignments[score['userName']] ?? '';
                                    dailyScores = presentMembers.map((member) => {
                                      'userName': member,
                                      'laneNum': laneAssignments[member] ?? '',
                                      'laneOrder': orderAssignments[member] ?? ''
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
                                    // Update dailyScores to reflect changes
                                    score['laneOrder'] = orderAssignments[score['userName']] ?? '';
                                    dailyScores = presentMembers.map((member) => {
                                      'userName': member,
                                      'laneNum': laneAssignments[member] ?? '',
                                      'laneOrder': orderAssignments[member] ?? ''
                                    }).toList();
                                  });
                                },
                              )
                                  : Text(score['laneOrder'].toString()),
                            ),
                          ],
                        );
                      }).toList(),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
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
        // Check if a date has been selected
        if (selectedDate == null) {
          _showErrorDialog('선택된 날짜가 없습니다.');
          return;
        }

        // Check for missing Lane or Order assignments
        bool hasMissingLane = false;
        bool hasMissingOrder = false;
        List<String> duplicatedLaneOrders = [];
        List<String> incorrectLaneOrders = [];

        Map<int, Set<int>> laneOrderMap = {};

        for (var member in presentMembers) {
          if (!laneAssignments.containsKey(member) || laneAssignments[member] == 0) {
            hasMissingLane = true;
            break;
          }
          if (!orderAssignments.containsKey(member) || orderAssignments[member] == 0) {
            hasMissingOrder = true;
            break;
          }

          int lane = laneAssignments[member]!;
          int order = orderAssignments[member]!;

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
          _saveAssignments();
        }
      },
      child: Text('저장'),
    );
  }


}