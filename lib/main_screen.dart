import 'package:contact/font_awesome_icons.dart';
import 'package:contact/my_flutter_app_icons.dart';
import 'package:contact/storage_custom.dart';
import 'package:dio/dio.dart' as dio;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'login.dart';
import 'my_setting.dart';

class MainScreen extends StatelessWidget {
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: MyHomePage(),
    );
  }
}


class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? jwtToken;
  String? imageFileName;
  final dio.Dio _dio = dio.Dio();

  @override
  void initState() {
    super.initState();
    _loadJwtToken();
    _loadImageFileName();
  }

  Future<void> _loadJwtToken() async {
    final storedToken = await StorageCustom.read('jwtToken');
    print('main_screen jwttoken : $storedToken');
    if (storedToken == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  Future<void> _loadImageFileName() async {
    final storedToken = await StorageCustom.read('jwtToken');
    final getImageFileNameUrl = 'https://bowling-rolling.com/api/v1/get/myImage';

    try {
      final getImageFileNameResponse = await _dio.get(
        getImageFileNameUrl,
        options: dio.Options(
          headers: {"jwtToken": storedToken},
        ),
      );

      if (getImageFileNameResponse.statusCode == 200 && getImageFileNameResponse.data['code'] == '200') {
        setState(() {
          imageFileName = getImageFileNameResponse.data['message']; // API에서 정상적으로 imageFileName 가져옴
        });
      } else {
        print('이미지 가져오기 실패: ${getImageFileNameResponse.data['message']}');
      }
    } catch (e) {
      print('이미지 가져오기 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Header(),
          Expanded(child: Content(imageFileName: imageFileName)), // Pass imageFileName to Content
          Footer(),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF303F9F),
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(CustomIcons.bowling_ball, color: Colors.red),
              SizedBox(width: 8),
              Text('볼케이노', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()), // SettingsPage로 이동
              );
            },
            child: Icon(Icons.settings, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

class Content extends StatelessWidget {
  final String? imageFileName; // Add imageFileName as a parameter

  Content({this.imageFileName}); // Update the constructor

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          UserInfo(imageFileName: imageFileName), // Pass imageFileName to UserInfo
          GraphSection(),
          RankingSection(),
          RecordsSection(),
        ],
      ),
    );
  }
}

// Section, UserInfo, GraphSection, RankingSection, RecordsSection, RankingOption, GraphOption, Footer 클래스는 그대로 유지


class Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Icon? icon; // 선택적으로 아이콘을 추가하기 위한 IconData

  Section({required this.title, required this.child, this.icon}); // 아이콘 매개변수 추가

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row( // 아이콘을 포함한 제목을 표시하는 Row 추가
            children: [
              if (icon != null) // 아이콘이 있으면 아이콘을 표시
                Container(child: icon),
              if (icon != null) // 아이콘이 있으면 아이콘과 제목 사이에 간격 추가
                SizedBox(width: 15),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class UserInfo extends StatelessWidget {
  final String? imageFileName; // Add imageFileName as a parameter

  UserInfo({this.imageFileName}); // Update the constructor

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey[100],
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: imageFileName != null
                  ? AssetImage('$imageFileName')
                  : AssetImage('default.png'), // Default image if imageFileName is null
            ),
            flex: 3,
          ),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('위형규', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('최근 취미반 방문: 2024. 05. 16(목)', style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow[700], size: 20),
                    SizedBox(width: 8),
                    Text('최고 점수: 160', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.show_chart, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Text('평균 점수: 130', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GraphSection extends StatelessWidget {
  final List<FlSpot> dataPoints = [
    FlSpot(0, 80),
    FlSpot(1, 120),
    FlSpot(2, 130),
    FlSpot(3, 100),
    FlSpot(4, 170),
  ];

  final Map<int, String> monthLabels = {
    0: '23년12월',
    1: '24년01월',
    2: '24년02월',
    3: '24년03월',
    4: '24년04월',
  };

  @override
  Widget build(BuildContext context) {
    return Section(
      title: '내 월별 점수',
      child: Container(
        width: double.infinity,
        height: 300,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: GraphOption(text: '최고 점수 기준', isSelected: true)),
                Expanded(child: GraphOption(text: '평균 점수 기준', isSelected: false)),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: dataPoints.length * 100.0, // Adjust the width to allow for scrolling
                  height: 400,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40, // Increase the width of the left labels
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}점');
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1, // Set interval to 1 month
                            getTitlesWidget: (value, meta) {
                              return Text(monthLabels[value.toInt()] ?? '');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      minX: 0,
                      maxX: dataPoints.length - 1,
                      minY: 0,
                      maxY: 300,
                      lineBarsData: [
                        LineChartBarData(
                          spots: dataPoints,
                          isCurved: true,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RankingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Section(
      title: '취미반 랭킹',
      icon: Icon(FontAwesome.crown,color: Color(0xFFFFD700)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: RankingOption(text: '최고 점수 기준', isSelected: true)),
              Expanded(child: RankingOption(text: '평균 점수 기준', isSelected: false)),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    '순위',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '점수',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    '이름',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text('1')),
                  DataCell(Text('190')),
                  DataCell(Text('위형규')),
                ]),
                DataRow(cells: [
                  DataCell(Text('2')),
                  DataCell(Text('180')),
                  DataCell(Text('우경석')),
                ]),
                DataRow(cells: [
                  DataCell(Text('3')),
                  DataCell(Text('170')),
                  DataCell(Text('이민지')),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecordsSection extends StatefulWidget {
  @override
  _RecordsSectionState createState() => _RecordsSectionState();
}

class _RecordsSectionState extends State<RecordsSection> {
  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      // locale: Locale('ko', 'KR'),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      title: '취미반 볼링 기록',
      child: Column(
        children: [
          SizedBox(height: 16),
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
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 40,
                        minWidth: 40,
                      ),
                      child: Text('이름', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Round 1',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Round 2',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Round 3',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Text('위형규')),
                    DataCell(Text('90')),
                    DataCell(Text('100')),
                    DataCell(Text('120')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('우경석')),
                    DataCell(Text('80')),
                    DataCell(Text('95')),
                    DataCell(Text('110')),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('이민지')),
                    DataCell(Text('85')),
                    DataCell(Text('90')),
                    DataCell(Text('105')),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RankingOption extends StatelessWidget {
  final String text;
  final bool isSelected;

  RankingOption({required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio(
          value: isSelected,
          groupValue: true,
          onChanged: (value) {},
        ),
        Text(text, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

class GraphOption extends StatelessWidget {
  final String text;
  final bool isSelected;

  GraphOption({required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio(
          value: isSelected,
          groupValue: true,
          onChanged: (value) {},
        ),
        Text(text, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

class Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: EdgeInsets.all(24),
      child: Center(
        child: ElevatedButton(
          onPressed: () {},
          child: Text('점수 기록하기'),
        ),
      ),
    );
  }
}