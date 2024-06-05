import 'package:contact/my_flutter_app_icons.dart';
import 'package:flutter/material.dart';

void main() => runApp(BowlingScoresApp());

class BowlingScoresApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 기본 배경 색상을 흰색으로 설정
      ),
      home: BowlingScoresScreen(),
    );
  }
}

class BowlingScoresScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Color(0xFF303F9F),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(CustomIcons.bowling_ball, color: Colors.red),
                    SizedBox(width: 8),
                    Text('점수 기록하기', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(Icons.settings, color: Colors.white, size: 24),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                LaneScores(laneNumber: 1, players: ['위형규', '우경석', '이민지']),
                LaneScores(laneNumber: 2, players: ['김혜지', '최상진', '별이']),
                // Add more lanes as needed
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // Handle save action
          },
          child: Text('Save'),
        ),
      ),
    );
  }
}

class LaneScores extends StatefulWidget {
  final int laneNumber;
  final List<String> players;

  LaneScores({required this.laneNumber, required this.players});

  @override
  _LaneScoresState createState() => _LaneScoresState();
}

class _LaneScoresState extends State<LaneScores> {
  List<int> games = [1, 2]; // Default 3 games

  void addGame() {
    setState(() {
      games.add(games.length + 1);
    });
  }

  void removeGame() {
    setState(() {
      if (games.length > 1) {
        games.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      child: Container(
        color: Color(0xFFE4EAFF),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lane ${widget.laneNumber}',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.players
                        .map(
                          (player) => Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: Text(player, style: TextStyle(fontSize: 16.0)),
                      ),
                    )
                        .toList(),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16.0),
                      for (int gameNumber in games)
                        GameScoreInput(gameNumber: gameNumber),
                      SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: addGame,
                            child: Text('Game 추가'),
                          ),
                          ElevatedButton(
                            onPressed: removeGame,
                            child: Text('Game 삭제'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GameScoreInput extends StatelessWidget {
  final int gameNumber;

  GameScoreInput({required this.gameNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text('Game $gameNumber', style: TextStyle(fontSize: 16.0)),
          SizedBox(width: 8.0),
          IconButton(
            icon: Icon(Icons.camera_alt,size: 30,),
            onPressed: () {
              // Handle camera action
            },
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '수동 입력',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
    );
  }
}
