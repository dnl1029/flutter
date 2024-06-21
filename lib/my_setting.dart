import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'my_flutter_app_icons.dart';
import 'name_edit.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String name = ''; // 이름을 API에서 가져오므로 빈 문자열로 초기화
  bool photoPermission = false;
  final dio.Dio _dio = dio.Dio();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  List<Member> members = [];

  _SettingsPageState() {
    _dio.interceptors.add(dio.InterceptorsWrapper(
      onRequest: (options, handler) {
        print("Request[${options.method}] => PATH: ${options.path}");
        print("Headers: ${options.headers}");
        return handler.next(options); // continue
      },
      onResponse: (response, handler) {
        print("Response[${response.statusCode}] => DATA: ${response.data}");
        return handler.next(response); // continue
      },
      onError: (dio.DioError e, handler) {
        print("Error[${e.response?.statusCode}] => MESSAGE: ${e.message}");
        return handler.next(e); // continue
      },
    ));
  }

  @override
  void initState() {
    super.initState();
    _loadName(); // 초기화 시에 이름을 가져오도록 호출
    _loadPhotoPermission();
    _fetchMembers();
  }

  Future<void> _loadName() async {
    final storedToken = await _storage.read(key: 'jwtToken');
    final getNameUrl = 'https://bowling-rolling.com/api/v1/get/myName';

    try {
      final getNameResponse = await _dio.get(
        getNameUrl,
        options: dio.Options(
          headers: {"jwtToken": storedToken},
        ),
      );

      if (getNameResponse.statusCode == 200 && getNameResponse.data['code'] == '200') {
        setState(() {
          name = getNameResponse.data['message']; // API에서 정상적으로 이름을 가져와서 설정
        });
      } else {
        setState(() {
          name = ''; // 비정상 응답 시 이름을 빈 문자열로 설정
        });
        print('이름 가져오기 실패: ${getNameResponse.data['message']}');
      }
    } catch (e) {
      setState(() {
        name = ''; // 오류 발생 시 이름을 빈 문자열로 설정
      });
      print('이름 가져오기 실패: $e');
    }
  }

  Future<void> _loadPhotoPermission() async {
    String? permission = await _storage.read(key: 'hasPermission');
    setState(() {
      photoPermission = permission == 'true';
    });
  }

  Future<void> _fetchMembers() async {
    final storedToken = await _storage.read(key: 'jwtToken');
    print('SettingPage jwtToken : $storedToken');
    final response = await _dio.get(
      'https://bowling-rolling.com/api/v1/member/getAll',
      options: dio.Options(
        headers: {'jwtToken': storedToken},
      ),
    );

    setState(() {
      members = (response.data as List)
          .map((json) => Member.fromJson(json))
          .toList();
    });
  }

  void _togglePhotoPermission() async {
    setState(() {
      photoPermission = !photoPermission;
    });
    await _storage.write(
        key: 'hasPermission', value: photoPermission.toString());
  }

  void _navigateToNameEditScreen(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    nameController.text = name; // 현재 이름을 기본값으로 설정

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NameEditScreen(nameController: nameController),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        name = result; // 수정된 이름을 설정
      });
    }
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
                    ],
                  ),
                  Spacer(),
                  TextButton.icon(
                    icon: Icon(Icons.edit),
                    label: Text('이름 수정'),
                    onPressed: () {
                      _navigateToNameEditScreen(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextButton.icon(
                icon: Icon(Icons.image),
                label: Text('내 프로필 이미지 수정'),
                onPressed: () {
                  // 버튼 눌렀을 때의 동작 비워둠
                },
              ),
              SizedBox(height: 20),
              SwitchListTile(
                title: Text('사진 권한 접근'),
                subtitle: Text('사진 업로드 기능을 사용 하기 위한 권한 접근 설정입니다.'),
                value: photoPermission,
                onChanged: (bool value) {
                  print('변경 전 사진 권한 : $photoPermission');
                  _togglePhotoPermission();
                  print('변경 후 사진 권한 : $photoPermission');
                },
              ),
              SizedBox(height: 20),
              Container(
                child: Table(
                  border: TableBorder.all(),
                  children: [
                    TableRow(children: [
                      Text('User ID'),
                      Text('User Name'),
                      Text('Image File'),
                      Text('Status'),
                      Text('Role'),
                    ]),
                    ...members.map((member) {
                      return TableRow(children: [
                        Text(member.userId.toString()),
                        Text(member.userName),
                        Text(member.imageFileName ?? ''),
                        Text(member.statusYn),
                        Text(member.role ?? ''),
                      ]);
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Member {
  final int userId;
  final String userName;
  final String? imageFileName;
  final String statusYn;
  final String? role;

  Member({
    required this.userId,
    required this.userName,
    this.imageFileName,
    required this.statusYn,
    this.role,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      userId: json['userId'],
      userName: json['userName'],
      imageFileName: json['imageFileName'],
      statusYn: json['statusYn'],
      role: json['role'],
    );
  }
}
