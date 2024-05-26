import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<GameRecord> records = [
    GameRecord(date: '5.24(금)', scores: [50, 60, 80], total: 190, average: 63.3),
    GameRecord(date: '5.17(금)', scores: [50, 60, 70, 80], total: 260, average: 65.0),
    GameRecord(date: '5.17(금)', scores: [100, 120, 150, 160], total: 530, average: 132.5),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('7:IO'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ProfileSection(),
            AverageCard(),
            RecordSection(),
            ClubSection(),
            RecordList(records: records),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_baseball),
            label: '마이볼링',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: '랭킹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: '미션',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_pin),
            label: '볼링장',
          ),
        ],
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage('https://via.placeholder.com/150'),
      ),
      title: Text('위형규(큐큐큐)'),
      subtitle: Text('최근 3개월 동안 0개 볼링장을 6회 방문했습니다.'),
    );
  }
}

class AverageCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Practice Average',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              children: [
                CircularProgressIndicator(
                  value: 59.8 / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 6,
                ),
                SizedBox(width: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '59.8',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('21 Games'),
                  ],
                ),
                Spacer(),
                Column(
                  children: [
                    Text(
                      'Best',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('160'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecordSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blue,
      padding: EdgeInsets.all(16.0),
      width: double.infinity,
      child: Text(
        '2023년 나의 기록은?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ClubSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '클럽',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text('클럽전체보기'),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.search),
          title: Text('아직 소속된 클럽이 없네요. 활동하고 싶은 클럽을 찾아볼까요?'),
        ),
        Padding(
          padding: EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {},
            child: Text('연습게임기록하기'),
          ),
        ),
      ],
    );
  }
}

class GameRecord {
  final String date;
  final List<int> scores;
  final int total;
  final double average;

  GameRecord({
    required this.date,
    required this.scores,
    required this.total,
    required this.average,
  });
}

class RecordList extends StatelessWidget {
  final List<GameRecord> records;

  RecordList({required this.records});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        return RecordCard(record: records[index]);
      },
    );
  }
}

class RecordCard extends StatelessWidget {
  final GameRecord record;

  RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.date,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Row(
              children: record.scores
                  .map((score) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: Text(score.toString()),
                ),
              ))
                  .toList(),
            ),
            SizedBox(height: 8.0),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  record.total.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                ),
                Text(
                  record.average.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

