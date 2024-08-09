import 'dart:convert';

import 'package:contact/font_awesome_icons.dart';
import 'package:contact/my_flutter_app_icons.dart';
import 'package:contact/record_score.dart';
import 'package:contact/storage_custom.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart'; // 날짜 포맷을 위한 패키지
import 'package:table_calendar/table_calendar.dart';

import 'api_client.dart';
import 'login.dart';
import 'my_setting.dart';
import 'package:collection/collection.dart'; // for firstWhereOrNull

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
    _apiClient.checkTokenValidity(context);
    _loadJwtToken();
    _loadImageFileName();
  }

  Future<void> _loadJwtToken() async {
    final storedToken = await StorageCustom.read('jwtToken');
    // print('main_screen jwttoken : $storedToken');
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
    return AppBar(
      backgroundColor: Colors.white, // Make sure the background is white
      elevation: 0, // No shadow or elevation
      centerTitle: true, // Center the title
      title: Text(
        '볼링롤링',
        style: TextStyle(
          color: Colors.black, // Text color should be black
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          color: Colors.black, // Icon color should be black
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          },
        ),
      ],
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
          Container(
            width: double.infinity,
            height: 10,
            color: Colors.grey[200], // Light gray color
          ),
          GraphSection(),
          Container(
            width: double.infinity,
            height: 10,
            color: Colors.grey[200], // Light gray color
          ),
          RankingSection(),
          Container(
            width: double.infinity,
            height: 10,
            color: Colors.grey[200], // Light gray color
          ),
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
      padding: EdgeInsets.all(24), // Added padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Image Section
          GestureDetector(
            onTap: () {
              Widget imageWidget;
              if (imageFileName != null) {
                if (imageFileName!.startsWith('https')) {
                  imageWidget = Image.network(
                    imageFileName!,
                    fit: BoxFit.cover,
                  );
                } else {
                  imageWidget = Image.asset(
                    imageFileName!,
                    fit: BoxFit.cover,
                  );
                }
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          imageWidget,
                          TextButton(
                            child: Text('닫기'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
            child: CircleAvatar(
              radius: 33, // Adjusted to 2/3 of the original radius (50 * 2/3)
              backgroundImage: imageFileName != null
                  ? (imageFileName!.startsWith('https')
                  ? NetworkImage(imageFileName!)
                  : AssetImage(imageFileName!) as ImageProvider)
                  : AssetImage('default.png'),
            ),
          ),
          SizedBox(width: 10), // Added space between image and right column
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
                          SizedBox(width: 10),
                          Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Changed alignment to left
                              children: [
                                Text(
                                  '최고 점수',
                                  style: TextStyle(
                                    fontSize: 14, // Reduced font size
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  maxScore,
                                  style: TextStyle(
                                    fontSize: 14, // Reduced font size
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12), // Added space between max score and average score
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[200],
                            child: Icon(
                              Icons.score,
                              size: 25,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Changed alignment to left
                              children: [
                                Text(
                                  '평균 점수',
                                  style: TextStyle(
                                    fontSize: 14, // Reduced font size
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  avgScore,
                                  style: TextStyle(
                                    fontSize: 16, // Reduced font size
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
  List<FlSpot> bestScoreDataPoints = [];
  List<FlSpot> avgScoreDataPoints = [];
  Map<int, String> monthLabels = {};
  final ApiClient _apiClient = ApiClient();
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchScoreData();
  }

  Future<void> _fetchScoreData() async {
    final scoreUrl = 'https://bowling-rolling.com/api/v1/score/myUserId';

    try {
      final response = await _apiClient.get(context, scoreUrl);
      if (response.statusCode == 200) {
        final data = response.data;
        final scores = data['scores'];

        setState(() {
          _updateScoreData(scores);
        });
      } else {
        setState(() {
          bestScoreDataPoints = [];
          avgScoreDataPoints = [];
          monthLabels = {};
        });
      }
    } catch (error) {
      print("Error fetching scores: $error");
      setState(() {
        bestScoreDataPoints = [];
        avgScoreDataPoints = [];
        monthLabels = {};
      });
    }
  }

  void _updateScoreData(List<dynamic> scores) {
    List<FlSpot> bestScores = [];
    List<FlSpot> avgScores = [];
    Map<int, String> labels = {};

    for (int i = 0; i < scores.length; i++) {
      final score = scores[i];
      final yearMonth = score['yearMonth'];
      final year = int.parse(yearMonth.substring(0, 4));
      final month = int.parse(yearMonth.substring(4, 6));

      if (year == selectedYear) {
        DateTime date = DateTime(year, month, 1);
        int index = month - 1;  // 월을 0부터 11까지 설정
        final monthLabel = DateFormat('M월').format(date);

        if (!labels.containsKey(index)) {
          bestScores.add(FlSpot(index.toDouble(), score['maxScore'].toDouble()));
          avgScores.add(FlSpot(index.toDouble(), score['avgScore'].toDouble()));
          labels[index] = monthLabel;
        }
      }
    }

    bestScoreDataPoints = bestScores;
    avgScoreDataPoints = avgScores;
    monthLabels = labels;
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
        height: 400,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: Row(
                children: [
                  Text(
                    '년도 선택',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 16),
                  DropdownButton<int>(
                    value: selectedYear,
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedYear = newValue;
                          _fetchScoreData();
                        });
                      }
                    },
                    items: List.generate(10, (index) => DateTime.now().year - index)
                        .map<DropdownMenuItem<int>>((int year) {
                      return DropdownMenuItem<int>(
                        value: year,
                        child: Text(year.toString(), style: TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: '최고 점수 기준'),
                Tab(text: '평균 점수 기준'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.transparent, // 하단 회색 라인 제거
            ),
            SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChart(bestScoreDataPoints),
                  _buildChart(avgScoreDataPoints),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> dataPoints) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: double.infinity,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              drawHorizontalLine: true,
              verticalInterval: 1,
              horizontalInterval: 50,
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: 50,
                  getTitlesWidget: (value, meta) {
                    if (value % 50 == 0) {
                      return Padding(
                        padding: EdgeInsets.only(
                          right: 4.0,
                          top: value == 300 ? 10.0 : 0,
                        ),
                        child: Text(
                          '${value.toInt()}점',
                          textAlign: TextAlign.right,
                        ),
                      );
                    }
                    return Container();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, _) {
                    int intValue = value.toInt();
                    String label = monthLabels[intValue] ?? '';
                    if (label.isEmpty) {
                      return Container();
                    }
                    return Padding(
                      padding: EdgeInsets.only(
                        left: intValue == 0 ? 8.0 : 0,
                        right: intValue == 11 ? 8.0 : 0,
                        top: 8.0,
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                    );
                  },
                  reservedSize: 40,
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
            maxX: 11,
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
        ),
      ),
    );
  }
}





class RankingSection extends StatefulWidget {
  @override
  _RankingSectionState createState() => _RankingSectionState();
}

class _RankingSectionState extends State<RankingSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();

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
            height: 500,
            child: TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<List<dynamic>>(
                  future: _fetchRankings('rankingByMaxScore', 'maxScore'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Failed to load data'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No data available'));
                    } else {
                      List<dynamic> rankings = snapshot.data!;
                      return RankingTable(data: rankings, rankingType: 'rankingByMaxScore');
                    }
                  },
                ),
                FutureBuilder<List<dynamic>>(
                  future: _fetchRankings('rankingByAvgScore', 'avgScore'),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Failed to load data'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No data available'));
                    } else {
                      List<dynamic> rankings = snapshot.data!;
                      return RankingTable(data: rankings, rankingType: 'rankingByAvgScore');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<dynamic>> _fetchRankings(String rankingType, String scoreType) async {
    String url = 'https://bowling-rolling.com/api/v1/score/ranking';
    try {
      final response = await _apiClient.get(context, url);
      if (response.statusCode == 200) {
        List<dynamic> rankings = response.data['rankings'];
        rankings.sort((a, b) => a[rankingType].compareTo(b[rankingType]));
        return rankings;
      } else {
        throw Exception('Failed to load rankings');
      }
    } catch (e) {
      print('Error fetching rankings: $e');
      return [];
    }
  }
}


class RankingTable extends StatelessWidget {
  final List<dynamic> data;
  final String rankingType;

  RankingTable({required this.data, required this.rankingType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Theme(
        data: Theme.of(context).copyWith(),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 0,
              headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[100]!),
              border: TableBorder(
                top: BorderSide(width: 1.5, color: Colors.black),
                horizontalInside: BorderSide(width: 0.7, color: Colors.grey[300]!),
              ),
              columns: [
                DataColumn(
                  label: Container(
                    width: 50, // 순위 컬럼의 너비 조정
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(''),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    width: 80, // 이름 컬럼의 너비 조정
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(''),
                    ),
                  ),
                ),
                DataColumn(
                  label: Container(
                    width: 40, // 점수 컬럼의 너비 조정
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(''),
                    ),
                  ),
                ),
              ],
              rows: List<DataRow>.generate(
                data.length,
                    (index) => DataRow(
                  cells: [
                    DataCell(
                      Container(
                        width: 50,
                        child: Row(
                          children: [
                            if (index == 0) Icon(FontAwesome.medal, color: Color(0xFFFFCF35), size: 16),
                            if (index == 1) Icon(FontAwesome.medal, color: Color(0xFFCBCCCE), size: 16),
                            if (index == 2) Icon(FontAwesome.medal, color: Color(0xFFDD966A), size: 16),
                            if (index >= 3) SizedBox(width: 16), // 4등부터 아이콘 대신 빈 공간 추가
                            SizedBox(width: 4),
                            Text(
                              '${data[index][rankingType]}등',
                              textAlign: TextAlign.left,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 80, // 이름 컬럼의 너비 조정
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Widget imageWidget;
                                if (data[index]['imageFileName'].startsWith('https')) {
                                  imageWidget = Image.network(
                                    data[index]['imageFileName'],
                                    fit: BoxFit.cover,
                                  );
                                } else {
                                  imageWidget = Image.asset(
                                    data[index]['imageFileName'],
                                    fit: BoxFit.cover,
                                  );
                                }

                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          imageWidget,
                                          TextButton(
                                            child: Text('닫기'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: CircleAvatar(
                                radius: 16, // 이미지 크기 줄임
                                backgroundImage: data[index]['imageFileName'] != null
                                    ? (data[index]['imageFileName'].startsWith('https')
                                    ? NetworkImage(data[index]['imageFileName'])
                                    : AssetImage(data[index]['imageFileName']) as ImageProvider)
                                    : AssetImage('default.png'),
                              ),
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data[index]['userName'],
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14), // 글자 크기 줄임
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        width: 40, // 점수 컬럼의 너비 조정
                        child: Text(
                          rankingType == 'rankingByMaxScore'
                              ? data[index]['maxScore'].toString()
                              : data[index]['avgScore'].toString(),
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14), // 글자 크기 줄임
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
  int selectedYear = DateTime.now().year;
  List<dynamic> dailyScores = [];
  List<DateTime> workDates = [];
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _getWorkDtList();
    selectedDate = DateTime.now(); // 디폴트로 오늘 날짜 선택
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

  void _selectDate(BuildContext context) {
    showDialog(
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
                              selectedDate = DateTime(selectedYear, selectedDate!.month, selectedDate!.day);
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
                    focusedDay: DateTime(selectedYear, selectedDate!.month),
                    selectedDayPredicate: (DateTime date) {
                      return isSameDay(selectedDate, date);
                    },
                    onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
                      setState(() {
                        selectedDate = selectedDay;
                      });
                      Navigator.pop(context);
                      _fetchDailyScores();
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
  }

  Future<void> _fetchDailyScores() async {
    if (selectedDate == null) return;

    final url = 'https://bowling-rolling.com/api/v1/score/daily/workDt';
    try {
      final response = await _apiClient.post(
        context,
        url,
        data: jsonEncode({"workDt": _formatDate(selectedDate!)}),
      );

      if (response.statusCode == 200) {
        setState(() {
          dailyScores = response.data['dailyScores'];
        });
      } else {
        throw Exception('Failed to load daily scores');
      }
    } catch (e) {
      print('Error fetching daily scores: $e');
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Section(
      title: '취미반 볼링 기록',
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
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
            // 선택된 날짜에 데이터가 없는 경우
            if (dailyScores.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  '선택한 날짜에는 데이터가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 300),
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[100]!),
                    border: TableBorder(
                      top: BorderSide(width: 1.5, color: Colors.black),
                      verticalInside: BorderSide(width: 0.7, color: Colors.grey[300]!),
                      horizontalInside: BorderSide(width: 0.7, color: Colors.grey[300]!),
                    ),
                    columns: _buildColumns(),
                    rows: _buildRows(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = [
      DataColumn(
        label: Expanded(
          child: Center(
            child: Text(
              '이름',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    ];

    if (dailyScores.isNotEmpty) {
      Set<int> gameNums = dailyScores.map((score) => score['gameNum'] as int).toSet();
      List<int> sortedGameNums = gameNums.toList()..sort();

      for (int gameNum in sortedGameNums) {
        columns.add(
          DataColumn(
            label: Expanded(
              child: Center(
                child: Text(
                  'Game $gameNum',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        );
      }

      // 평균 컬럼 추가
      columns.add(
        DataColumn(
          label: Expanded(
            child: Center(
              child: Text(
                '평균',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );
    }

    return columns;
  }

  List<DataRow> _buildRows() {
    List<DataRow> rows = [];

    Map<String, List<DataCell>> userRows = {};
    Map<String, int> userAverages = {};

    dailyScores.forEach((score) {
      String userName = score['userName'] as String;
      int gameNum = score['gameNum'] as int;
      int? scoreValue = score['score'];

      if (scoreValue == null) return;

      userRows.putIfAbsent(userName, () => [
        DataCell(
          Center(
            child: Text(userName),
          ),
        ),
        ...List<DataCell>.generate(
          _buildColumns().length - 2,
              (_) => DataCell(
            Center(
              child: Text(''),
            ),
          ),
        ),
      ]);

      userRows[userName]![gameNum] = DataCell(
        Center(
          child: Text(scoreValue.toString()),
        ),
      );

      if (userAverages.containsKey(userName)) {
        userAverages[userName] = ((userAverages[userName]! + scoreValue) / 2).round();
      } else {
        userAverages[userName] = scoreValue;
      }
    });

    userAverages.forEach((userName, avg) {
      userRows[userName]!.add(
        DataCell(
          Center(
            child: Text(avg.toString()),
          ),
        ),
      );
    });

    // 평균값으로 내림차순 정렬하고, 평균값이 같으면 이름 오름차순 정렬
    final sortedUserNames = userAverages.keys.toList()
      ..sort((a, b) {
        int compareAvg = userAverages[b]!.compareTo(userAverages[a]!);
        if (compareAvg == 0) {
          return a.compareTo(b);
        }
        return compareAvg;
      });

    for (String userName in sortedUserNames) {
      rows.add(DataRow(cells: userRows[userName]!));
    }

    return rows;
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
      color: Colors.white,
      padding: EdgeInsets.all(24),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => BowlingScoresApp()));
          },
          style: ElevatedButton.styleFrom(
            // backgroundColor: Color(0xFF0D47A1),
            // surfaceTintColor: Color(0xFF0D47A1),
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