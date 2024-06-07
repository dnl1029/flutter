import 'package:contact/my_flutter_app_icons.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settings Page',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 기본 배경 색상을 흰색으로 설정
      ),
      home: SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String name = '위형규';
  bool photoPermission = false;

  void _togglePhotoPermission() {
    setState(() {
      photoPermission = !photoPermission;
    });
  }

  void _showNameChangeDialog() {
    TextEditingController _nameController = TextEditingController(text: name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('이름 변경'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '새 이름',
            ),
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('확인'),
              onPressed: () {
                setState(() {
                  name = _nameController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                    '설정',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    // backgroundImage: AssetImage('assets/profile.jpg'), // 프로필 이미지 경로
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('볼링왕'), // 추가 텍스트
                      Text('dn1029@jr.naver.com'),
                    ],
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: _showNameChangeDialog,
                  ),
                ],
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text('공지사항'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              SwitchListTile(
                title: Text('사진 권한 접근'),
                subtitle: Text('사진 업로드 기능을 사용 하기 위한 권한 접근 설정입니다.'),
                value: photoPermission,
                onChanged: (bool value) {
                  _togglePhotoPermission();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
