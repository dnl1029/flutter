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
  String? imageFileName;
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
    _loadImageFileName(); // 초기화 시에 이미지를 가져오도록 호출
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

  Future<void> _loadImageFileName() async {
    final storedToken = await _storage.read(key: 'jwtToken');
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

  Future<void> _addMember() async {
    final TextEditingController userIdController = TextEditingController();
    final TextEditingController userNameController = TextEditingController();
    final TextEditingController imageFileNameController = TextEditingController();
    final TextEditingController statusYnController = TextEditingController(text: 'Y');
    final TextEditingController roleController = TextEditingController(text: 'USER');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('멤버 추가'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: userIdController,
                  decoration: InputDecoration(labelText: '사번'),
                ),
                TextField(
                  controller: userNameController,
                  decoration: InputDecoration(labelText: '이름'),
                ),
                TextField(
                  controller: imageFileNameController,
                  decoration: InputDecoration(labelText: 'Image File'),
                ),
                TextField(
                  controller: statusYnController,
                  decoration: InputDecoration(labelText: '계정 상태'),
                ),
                TextField(
                  controller: roleController,
                  decoration: InputDecoration(labelText: '권한'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'userId': userIdController.text,
                  'userName': userNameController.text,
                  'imageFileName': imageFileNameController.text,
                  'statusYn': statusYnController.text,
                  'role': roleController.text,
                });
              },
              child: Text('추가'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final storedToken = await _storage.read(key: 'jwtToken');
      final addMemberUrl = 'https://bowling-rolling.com/api/v1/member/create';

      try {
        await _dio.post(
          addMemberUrl,
          options: dio.Options(
            headers: {'jwtToken': storedToken},
          ),
          data: {
            'userId': int.parse(result['userId']!),
            'userName': result['userName'],
            'imageFileName': result['imageFileName'],
            'statusYn': result['statusYn'],
            'role': result['role'],
          },
        );
        _fetchMembers();
      } catch (e) {
        if (e is dio.DioError) {
          if (e.response?.statusCode == 400 && e.response?.data['code'] == 'INVALID_PARAMETER') {
            // 서버에서 반환한 에러 메시지를 사용자에게 알림
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('오류'),
                  content: Text('해당 사번으로 기존에 추가된 멤버가 있습니다.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('확인'),
                    ),
                  ],
                );
              },
            );
          } else {
            // 다른 오류 처리
            print('멤버 추가 실패: ${e.response?.data}');
          }
        } else {
          // 기타 예외 처리
          print('멤버 추가 실패: $e');
        }
      }
    }
  }


  Future<void> _editMembers() async {
    // 원본 멤버 목록을 깊은 복사합니다.
    final List<Member> updatedMembers = members.map((member) => Member(
      userId: member.userId,
      userName: member.userName,
      imageFileName: member.imageFileName,
      statusYn: member.statusYn,
      role: member.role,
    )).toList();

    final result = await showDialog<List<Member>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 20.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 40,
                  maxHeight: MediaQuery.of(context).size.height * 4 / 5,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('멤버 수정', style: TextStyle(fontSize: 24.0)),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: MediaQuery.of(context).size.width - 60,
                                ),
                                child: Table(
                                  border: TableBorder.all(),
                                  children: [
                                    TableRow(children: [
                                      Text(
                                        '순번',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '사번',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '이름',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Image File',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '계정 상태',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '권한',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ]),
                                    ...updatedMembers.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      Member member = entry.value;
                                      return TableRow(children: [
                                        Text('${index + 1}'), // 순번
                                        TextFormField(
                                          initialValue: member.userId.toString(),
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                        ),
                                        TextFormField(
                                          initialValue: member.userName,
                                          onChanged: (value) {
                                            setState(() {
                                              member.userName = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                        ),
                                        TextFormField(
                                          initialValue: member.imageFileName ?? '',
                                          onChanged: (value) {
                                            setState(() {
                                              member.imageFileName = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                        ),
                                        TextFormField(
                                          initialValue: member.statusYn,
                                          onChanged: (value) {
                                            setState(() {
                                              member.statusYn = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                        ),
                                        TextFormField(
                                          initialValue: member.role ?? '',
                                          onChanged: (value) {
                                            setState(() {
                                              member.role = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(updatedMembers);
                          },
                          child: Text('저장'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('취소'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      final modifiedMembers = result.where((member) {
        final originalMember = members.firstWhere((original) => original.userId == member.userId);
        return member.userName != originalMember.userName ||
            member.imageFileName != originalMember.imageFileName ||
            member.statusYn != originalMember.statusYn ||
            member.role != originalMember.role;
      }).toList();

      if (modifiedMembers.isNotEmpty) {
        final storedToken = await _storage.read(key: 'jwtToken');
        final editMembersUrl = 'https://bowling-rolling.com/api/v1/member/edit/all';

        try {
          for (var member in modifiedMembers) {
            await _dio.post(
              editMembersUrl,
              options: dio.Options(
                headers: {'jwtToken': storedToken},
              ),
              data: member.toJson(),
            );
          }
        } catch (e) {
          print('멤버 수정 실패: $e');
        }
      }
      await _fetchMembers(); // 모든 멤버 업데이트가 완료된 후 멤버 목록을 다시 로드
      await _loadImageFileName(); // 내 이미지 파일을 다시 로드
      await _loadName(); // 내 이름을 다시 로드
    }
  }


  Future<void> _deleteMember() async {
    List<bool> checkedList = List.generate(members.length, (index) => false);

    final result = await showDialog<List<Member>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('멤버 삭제'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('대상')),
                          DataColumn(label: Text('사번')),
                          DataColumn(label: Text('이름')),
                        ],
                        rows: members
                            .asMap()
                            .entries
                            .map((entry) => DataRow(
                          cells: [
                            DataCell(
                              Checkbox(
                                value: checkedList[entry.key],
                                onChanged: (value) {
                                  setState(() {
                                    checkedList[entry.key] = value!;
                                  });
                                },
                              ),
                            ),
                            DataCell(Text(entry.value.userId.toString())),
                            DataCell(Text(entry.value.userName)),
                          ],
                        ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      members.where((member) => checkedList[members.indexOf(member)]).toList(),
                    );
                  },
                  child: Text('삭제'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('취소'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final storedToken = await _storage.read(key: 'jwtToken');
      final deleteMembersUrl = 'https://bowling-rolling.com/api/v1/member/delete';

      try {
        for (var member in result) {
          await _dio.post(
            deleteMembersUrl,
            options: dio.Options(
              headers: {'jwtToken': storedToken},
            ),
            data: {'userId': member.userId},
          );
        }
      } catch (e) {
        print('멤버 삭제 실패: $e');
      }
      await _fetchMembers(); // 모든 멤버 업데이트가 완료된 후 멤버 목록을 다시 로드
      await _loadImageFileName(); // 내 이미지 파일을 다시 로드
      await _loadName(); // 내 이름을 다시 로드
    }
  }






  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      child: Scaffold(
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
                      radius: 50,
                      backgroundImage: imageFileName != null
                          ? AssetImage('$imageFileName')
                          : AssetImage('1.png'), // 예시로 기본 이미지를 설정할 수 있습니다.
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.edit),
                          label: Text('이름 수정'),
                          onPressed: () {
                            _navigateToNameEditScreen(context);
                          },
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.image),
                          label: Text('내 프로필 이미지 수정'),
                          onPressed: () {
                            // 버튼 눌렀을 때의 동작 비워둠
                          },
                        ),
                      ],
                    ),
                  ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '취미반 멤버',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('추가'),
                          onPressed: _addMember,
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.edit),
                          label: Text('수정'),
                          onPressed: _editMembers,
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.delete),
                          label: Text('삭제'),
                          onPressed: _deleteMember,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  child: Table(
                    border: TableBorder.all(),
                    children: [
                      TableRow(children: [
                        Text(
                          '순번',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '사번',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '이름',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Image File',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '계정 상태',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '권한',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ]),
                      // 순번과 함께 멤버를 표시
                      ...members.asMap().entries.map((entry) {
                        int index = entry.key;
                        Member member = entry.value;
                        return TableRow(children: [
                          Text('${index + 1}'), // 순번
                          Text(member.userId.toString()),
                          Text(member.userName),
                          Text(member.imageFileName ?? ''),
                          Text(member.statusYn),
                          Text(member.role ?? ''),
                        ]);
                      }).toList(),
                    ],
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Member {
  int userId;
  String userName;
  String? imageFileName;
  String statusYn;
  String? role;

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

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'imageFileName': imageFileName,
      'statusYn': statusYn,
      'role': role,
    };
  }

  @override
  String toString() {
    return 'Member(userId: $userId, userName: $userName, imageFileName: $imageFileName, statusYn: $statusYn, role: $role)';
  }
}
