import 'package:contact/my_flutter_app_icons.dart';
import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bowling Lanes',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 기본 배경 색상을 흰색으로 설정
      ),
      home: BowlingLanesPage(),
    );
  }
}

class BowlingLanesPage extends StatefulWidget {
  @override
  _BowlingLanesPageState createState() => _BowlingLanesPageState();
}

class _BowlingLanesPageState extends State<BowlingLanesPage> {
  final List<String> members = [
    '위형규', '최상진', '강선주', '김다인', '김성훈', '김수현',
    '김재위', '김지연', '김태윤', '김혜지', '남지연',
    '신가인', '신현경', '안성준', '우경석', '이동현',
    '이민영', '이민지', '이수경', '이수민', '이은경',
    '장누리', '정만석', '정진홍', '조현익', '최은진'
  ];

  List<String> presentMembers = [];
  bool isManuallyAssigned = false;
  Map<String, int> laneAssignments = {};
  Map<String, int> orderAssignments = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showMemberSelectionDialog());
  }

  void _showMemberSelectionDialog() async {
    List<String> selectedMembers = await showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelectedMembers = [];
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('오늘 참석한 멤버를 선택하세요'),
          content: SingleChildScrollView(
            child: ListBody(
              children: members.map((member) {
                return StatefulBuilder(
                  builder: (context, setState) {
                    return CheckboxListTile(
                      title: Text(member),
                      value: tempSelectedMembers.contains(member),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            tempSelectedMembers.add(member);
                          } else {
                            tempSelectedMembers.remove(member);
                          }
                        });
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop(tempSelectedMembers);
              },
            ),
          ],
        );
      },
    );

    if (selectedMembers != null && selectedMembers.isNotEmpty) {
      setState(() {
        presentMembers = selectedMembers;
      });
    }
  }

  void _showRandomAssignmentDialog() async {
    int? laneCount;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('랜덤 할당'),
          content: TextField(
            decoration: InputDecoration(
              labelText: '원하는 레인 수를 입력하세요',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              laneCount = int.tryParse(value);
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
                } else {
                  Navigator.of(context).pop();
                  _showErrorDialog('숫자를 입력해주세요');
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _assignRandomly(int laneCount) {
    if (laneCount <= 0) return;

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
    _sortMembers(); // 랜덤 배정 후 즉시 정렬
  }

  void _sortMembers() {
    presentMembers.sort((a, b) {
      int laneComparison = laneAssignments[a]!.compareTo(laneAssignments[b]!);
      if (laneComparison != 0) return laneComparison;
      return orderAssignments[a]!.compareTo(orderAssignments[b]!);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _saveAssignments() {
    setState(() {
      _sortMembers();
    });
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _showRandomAssignmentDialog,
                  child: Text('랜덤 배정하기'),
                ),
                SizedBox(width: 20,),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isManuallyAssigned = !isManuallyAssigned;
                    });
                  },
                  child: Text('수동 배정하기'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: 400,  // 원하는 너비를 지정
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('이름')),
                      DataColumn(label: Text('Lane')),
                      DataColumn(label: Text('순서')),
                    ],
                    rows: presentMembers.map((member) {
                      TextEditingController laneController = TextEditingController(
                        text: laneAssignments[member]?.toString() ?? '',
                      );

                      TextEditingController orderController = TextEditingController(
                        text: orderAssignments[member]?.toString() ?? '',
                      );

                      return DataRow(
                        cells: [
                          DataCell(Text(member)),
                          DataCell(
                            isManuallyAssigned
                                ? TextField(
                              decoration: InputDecoration(
                                hintText: laneAssignments.containsKey(member)
                                    ? laneAssignments[member].toString()
                                    : '-',
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              controller: TextEditingController(
                                text: laneAssignments[member]?.toString() ?? '',
                              )..selection = TextSelection.collapsed(
                                offset: laneAssignments[member]?.toString().length ?? 0,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value.isEmpty) {
                                    laneAssignments.remove(member);
                                  } else {
                                    laneAssignments[member] = int.tryParse(value) ?? 0;
                                  }
                                });
                              },
                            )
                                : Text(
                              laneAssignments.containsKey(member)
                                  ? laneAssignments[member].toString()
                                  : '-',
                            ),
                          ),
                          DataCell(
                            isManuallyAssigned
                                ? TextField(
                              decoration: InputDecoration(
                                hintText: orderAssignments.containsKey(member)
                                    ? orderAssignments[member].toString()
                                    : '-',
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.blue),
                                ),
                              ),
                              controller: TextEditingController(
                                text: orderAssignments[member]?.toString() ?? '',
                              )..selection = TextSelection.collapsed(
                                offset: orderAssignments[member]?.toString().length ?? 0,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value.isEmpty) {
                                    orderAssignments.remove(member);
                                  } else {
                                    orderAssignments[member] = int.tryParse(value) ?? 0;
                                  }
                                });
                              },
                            )
                                : Text(
                              orderAssignments.containsKey(member)
                                  ? orderAssignments[member].toString()
                                  : '-',
                            ),
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
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: 16,),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                surfaceTintColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
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
            ),
          ],
        ),
      ),
    );
  }
}
