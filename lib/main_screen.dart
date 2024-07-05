import 'package:contact/font_awesome_icons.dart';
import 'package:contact/my_flutter_app_icons.dart';
import 'package:contact/record_score.dart';
import 'package:contact/storage_custom.dart';
import 'package:dio/dio.dart' as dio;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'api_client.dart';
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
  final ApiClient _apiClient = ApiClient();

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
    final getImageFileNameUrl = 'https://bowling-rolling.com/api/v1/get/myImage';

    try {
      final getImageFileNameResponse = await _apiClient.get(context,getImageFileNameUrl);

      if (getImageFileNameResponse.statusCode == 200 &&
          getImageFileNameResponse.data['code'] == '200') {
        setState(() {
          imageFileName = getImageFileNameResponse
              .data['message']; // API에서 정상적으로 imageFileName 가져옴
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
  final String? imageFileName;

  UserInfo({this.imageFileName});
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> _fetchProfile(BuildContext context) async {
    final profileUrl = 'https://bowling-rolling.com/api/v1/get/myProfile';

    try {
      final response = await _apiClient.get(context, profileUrl);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        if (response.statusCode == 400 && response.data['code'] == 'INVALID_PARAMETER') {
          return {'error': true};
        } else {
          throw Exception('Failed to load profile: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
      return {'error': true}; // 에러 발생 시 error 플래그를 설정합니다.
    }
  }

  Future<String?> _fetchName(BuildContext context) async {
    final nameUrl = 'https://bowling-rolling.com/api/v1/get/myName';

    try {
      final response = await _apiClient.get(context, nameUrl);
      if (response.statusCode == 200) {
        return response.data['message'];
      } else {
        throw Exception('Failed to load name: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching name: $e');
      return '-';
    }
  }

  String formatVisitDay(String? lastVisitDay) {
    if (lastVisitDay == null) return '-';
    DateTime date = DateTime.parse(lastVisitDay);
    List<String> weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}(${weekdays[date.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchProfile(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError || (snapshot.hasData && snapshot.data!['error'] == true)) {
          // 에러가 발생한 경우 이름을 대체 URL에서 가져오고 나머지 값을 '-'로 설정
          return FutureBuilder<String?>(
            future: _fetchName(context),
            builder: (context, nameSnapshot) {
              if (nameSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (nameSnapshot.hasError) {
                return Text('Error: ${nameSnapshot.error}');
              } else {
                var userName = nameSnapshot.data ?? '-';
                return _buildUserInfo(context, userName, '-', '-', '-');
              }
            },
          );
        } else if (!snapshot.hasData) {
          return Text('No data');
        } else {
          var profileData = snapshot.data!;
          var userName = profileData['userName'] ?? '-';
          var maxScore = profileData['maxScore']?.toString() ?? '-';
          var avgScore = profileData['avgScore']?.toString() ?? '-';
          var lastVisitDay = formatVisitDay(profileData['lastVisitDay']);
          return _buildUserInfo(context, userName, maxScore, avgScore, lastVisitDay);
        }
      },
    );
  }

  Widget _buildUserInfo(BuildContext context, String userName, String maxScore, String avgScore, String lastVisitDay) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image Section
          CircleAvatar(
            radius: 50,
            backgroundImage: imageFileName != null
                ? AssetImage(imageFileName!)
                : AssetImage('default.png'),
          ),
          SizedBox(width: 10),
          // User Info Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Name
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                // Scores Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            child: Icon(
                              Icons.emoji_events,
                              size: 25,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(width: 4),
                          Container(
                            child: Column(
                              children: [
                                Text(
                                  '최고 점수',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  maxScore,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            child: Icon(
                              Icons.score,
                              size: 25,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 4),
                          Container(
                            child: Column(
                              children: [
                                Text(
                                  '평균 점수',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  avgScore,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 16),
                // Recent Visit
                Text(
                  '최근 취미반 방문   $lastVisitDay',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class GraphSection extends StatefulWidget {
  @override
  _GraphSectionState createState() => _GraphSectionState();
}

class _GraphSectionState extends State<GraphSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<FlSpot> bestScoreDataPoints = [
    FlSpot(0, 250),
    FlSpot(1, 200),
    FlSpot(2, 150),
    FlSpot(3, 200),
    FlSpot(4, 160),
  ];

  final List<FlSpot> avgScoreDataPoints = [
    FlSpot(0, 220),
    FlSpot(1, 180),
    FlSpot(2, 120),
    FlSpot(3, 180),
    FlSpot(4, 140),
  ];

  final Map<int, String> monthLabels = {
    0: '23년 12월',
    1: '24년 1월',
    2: '24년 2월',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      title: '내 월별 점수',
      child: Container(
        width: double.infinity,
        height: 300,
        child: Column(
          children: [
            // TabBar for switching between best and average scores
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  text: '최고 점수 기준',
                ),
                Tab(
                  text: '평균 점수 기준',
                ),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              indicatorWeight: 3.0,
            ),
            SizedBox(height: 16),

            // TabBarView to display the corresponding chart
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChart(bestScoreDataPoints), // Chart for best scores
                  _buildChart(avgScoreDataPoints), // Chart for average scores
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> dataPoints) {
    return LineChart(
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
          border: Border.all(color: Colors.black, width: 1),
        ),
        minX: 0,
        maxX: 2,
        minY: 0,
        maxY: 300,
        lineBarsData: [
          LineChartBarData(
            spots: dataPoints,
            isCurved: true,
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.2),
                  Colors.blue.withOpacity(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RankingSection extends StatefulWidget {
  @override
  _RankingSectionState createState() => _RankingSectionState();
}

class _RankingSectionState extends State<RankingSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      title: '취미반 랭킹',
      icon: Icon(FontAwesome.crown, color: Color(0xFFFFD700)),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: '최고 점수 기준'),
              Tab(text: '평균 점수 기준'),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [
                RankingTable(rankingType: '최고 점수 기준'),
                RankingTable(rankingType: '평균 점수 기준'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RankingTable extends StatelessWidget {
  final String rankingType;

  RankingTable({required this.rankingType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: DataTable(
        columnSpacing: 32,
        headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
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
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            child: DataTable(
              columnSpacing: 24,
              headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[200]!),
              columns: [
                DataColumn(
                  label: Text(
                    '이름',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Game 1',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Game 2',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text('위형규')),
                  DataCell(Text('90')),
                  DataCell(Text('100')),
                ]),
                DataRow(cells: [
                  DataCell(Text('우경석')),
                  DataCell(Text('80')),
                  DataCell(Text('95')),
                ]),
                DataRow(cells: [
                  DataCell(Text('이민지')),
                  DataCell(Text('85')),
                  DataCell(Text('90')),
                ]),
              ],
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
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => BowlingScoresApp()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF0D47A1),
            surfaceTintColor: Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            '점수 기록하기',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}