import 'package:contact/my_flutter_app_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'login.dart';

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
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadJwtToken();
  }

  Future<void> _loadJwtToken() async {
    final storedToken = await _storage.read(key: 'jwtToken');
    print('main_screen jwttoken : $storedToken');
    if (storedToken == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Header(),
          Expanded(child: Content()),
          Footer(),
        ],
      ),
    );
  }
}

// Header, Content, GraphSection, RankingSection, RecordsSection, Footer 클래스는 그대로 유지

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(Icons.settings, size: 24),
        ],
      ),
    );
  }
}

class Content extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          UserInfo(),
          GraphSection(),
          RankingSection(),
          RecordsSection(),
        ],
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Icon? icon;

  Section({required this.title, required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Container(child: icon),
              if (icon != null) SizedBox(width: 15),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: Icon(Icons.man, size: 60),
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
                  width: dataPoints.length * 100.0,
                  height: 400,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text('${value.toInt()}점');
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
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
                        border: Border.all(color: Colors.black),
                      ),
                      minX: 0,
                      maxX: dataPoints.length - 1.toDouble(),
                      minY: 0,
                      maxY: 200,
                      lineBarsData: [
                        LineChartBarData(
                          spots: dataPoints,
                          isCurved: true,
                          barWidth: 2,
                          // color: [Colors.blue],
                          dotData: FlDotData(show: true),
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

class GraphOption extends StatelessWidget {
  final String text;
  final bool isSelected;

  GraphOption({required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xff99B2CC) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class RankingSection extends StatelessWidget {
  final List<Map<String, dynamic>> rankingData = [
    {'rank': 1, 'name': '회원1', 'score': 180},
    {'rank': 2, 'name': '회원2', 'score': 170},
    {'rank': 3, 'name': '회원3', 'score': 160},
  ];

  @override
  Widget build(BuildContext context) {
    return Section(
      title: '전체 회원 랭킹',
      child: Column(
        children: rankingData.map((data) {
          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data['rank']}위'),
                Text('${data['name']}'),
                Text('${data['score']}점'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class RecordsSection extends StatelessWidget {
  final List<Map<String, dynamic>> recordData = [
    {'date': '2024. 06. 01', 'score': 150},
    {'date': '2024. 05. 25', 'score': 160},
    {'date': '2024. 05. 20', 'score': 155},
  ];

  @override
  Widget build(BuildContext context) {
    return Section(
      title: '내 기록',
      child: Column(
        children: recordData.map((data) {
          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${data['date']}'),
                Text('${data['score']}점'),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: '내 정보',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: '랭킹',
        ),
      ],
      selectedItemColor: Color(0xff99B2CC),
    );
  }
}
