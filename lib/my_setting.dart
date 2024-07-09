import 'package:contact/storage_custom.dart';
import 'package:contact/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';
import 'image_edit.dart';
import 'login.dart';
import 'main_screen.dart';
import 'my_flutter_app_icons.dart';
import 'name_edit.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String name = ''; // 이름을 API에서 가져오므로 빈 문자열로 초기화
  String? imageFileName;
  String? role;
  bool photoPermission = false;
  final ApiClient _apiClient = ApiClient();
  List<Member> members = [];

  @override
  void initState() {
    super.initState();
    _apiClient.checkTokenValidity(context);
    _loadName(); // 초기화 시에 이름을 가져오도록 호출
    _loadImageFileName(); // 초기화 시에 이미지를 가져오도록 호출
    _loadPhotoPermission();
    _fetchMembers();
    _loadRole();
  }

  Future<void> _loadName() async {
    final getNameUrl = 'https://bowling-rolling.com/api/v1/get/myName';

    try {
      final getNameResponse = await _apiClient.get(context,getNameUrl);

      if (getNameResponse.statusCode == 200 &&
          getNameResponse.data['code'] == '200') {
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

  Future<void> _loadRole() async {
    final getRoleUrl = 'https://bowling-rolling.com/api/v1/get/myRole';

    try {
      final getRoleResponse = await _apiClient.get(context,getRoleUrl);


      if (getRoleResponse.statusCode == 200 &&
          getRoleResponse.data['code'] == '200') {
        setState(() {
          role = getRoleResponse
              .data['message']; // API에서 정상적으로 role을 가져옴
        });
      } else {
        print('role 가져오기 실패: ${getRoleResponse.data['message']}');
      }
    } catch (e) {
      print('role 가져오기 실패: $e');
    }
  }

  Future<void> _loadPhotoPermission() async {
    String? permission = await StorageCustom.read('hasPhotoPermission');
    setState(() {
      photoPermission = permission == 'true';
    });
  }

  Future<void> _fetchMembers() async {
    final fetchMembersUrl = 'https://bowling-rolling.com/api/v1/member/getAll';
    final response = await _apiClient.get(context,fetchMembersUrl);

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
    _apiClient.checkTokenValidity(context);
    await StorageCustom.write('hasPhotoPermission',photoPermission.toString());
  }

  void _navigateToNameEditScreen(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    nameController.text = name; // 현재 이름을 기본값으로 설정

    _apiClient.checkTokenValidity(context);
    final result = await
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NameEditScreen(
              nameController: nameController,
              targetScreen: MainScreen(),
            ),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        name = result; // 수정된 이름을 설정
      });
    }
  }

  void _logout() async {
    await StorageCustom.delete('jwtToken'); // 토큰 삭제
    Utils.showAlertDialog(context, '정상적으로 로그아웃 되었습니다.',onConfirmed: () {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
    });
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
                  decoration: InputDecoration(labelText: '프로필 이미지 이름'),
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
              child: Text('저장'),
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
      final addMemberUrl = 'https://bowling-rolling.com/api/v1/member/create';

      try {
        await _apiClient.post(context,addMemberUrl,
        data: {
          'userId': int.parse(result['userId']!),
          'userName': result['userName'],
          'imageFileName': result['imageFileName'],
          'statusYn': result['statusYn'],
          'role': result['role'],
        },);
        Utils.showAlertDialog(context, '멤버가 정상적으로 추가되었습니다.',onConfirmed: () {
          _fetchMembers();
        });
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 400 && e.response?.data['code'] == 'INVALID_PARAMETER') {
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
            Utils.showAlertDialog(context, '멤버 추가를 실패했습니다.');
            print('멤버 추가 실패: ${e.response?.data}');
          }
        } else {
          Utils.showAlertDialog(context, '멤버 추가를 실패했습니다.');
          print('멤버 추가 실패: $e');
        }
      }
    }
  }

  Future<void> _editMembers() async {
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
              insetPadding: EdgeInsets.symmetric(horizontal: 20.0), // 화면 좌우의 여백을 설정
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9, // 전체 화면의 90% 너비로 설정
                  maxHeight: MediaQuery.of(context).size.height * 0.8, // 전체 화면의 80% 높이로 설정
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
                            Table(
                              border: TableBorder.all(color: Colors.grey[300]!),
                              columnWidths: {
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(2),
                                2: FlexColumnWidth(3),
                                3: FlexColumnWidth(3),
                                4: FlexColumnWidth(2),
                                5: FlexColumnWidth(2),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey[50],
                                  ),
                                  children: [
                                    TableCell(child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('순번', style: TextStyle(fontWeight: FontWeight.bold)),
                                    )),
                                    TableCell(child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('사번', style: TextStyle(fontWeight: FontWeight.bold)),
                                    )),
                                    TableCell(child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('이름', style: TextStyle(fontWeight: FontWeight.bold)),
                                    )),
                                    TableCell(child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('프로필 이미지 이름', style: TextStyle(fontWeight: FontWeight.bold)),
                                    )),
                                    TableCell(child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('계정 상태', style: TextStyle(fontWeight: FontWeight.bold)),
                                    )),
                                    TableCell(child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('권한', style: TextStyle(fontWeight: FontWeight.bold)),
                                    )),
                                  ],
                                ),
                                ...updatedMembers.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  Member member = entry.value;
                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                    ),
                                    children: [
                                      TableCell(child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('${index + 1}'), // 순번
                                      )),
                                      TableCell(child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          initialValue: member.userId.toString(),
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          maxLines: null, // 줄바꿈 허용
                                        ),
                                      )),
                                      TableCell(child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          initialValue: member.userName,
                                          onChanged: (value) {
                                            setState(() {
                                              member.userName = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          maxLines: null, // 줄바꿈 허용
                                        ),
                                      )),
                                      TableCell(child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          initialValue: member.imageFileName ?? '',
                                          onChanged: (value) {
                                            setState(() {
                                              member.imageFileName = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          maxLines: null, // 줄바꿈 허용
                                        ),
                                      )),
                                      TableCell(child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          initialValue: member.statusYn,
                                          onChanged: (value) {
                                            setState(() {
                                              member.statusYn = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          maxLines: null, // 줄바꿈 허용
                                        ),
                                      )),
                                      TableCell(child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: TextFormField(
                                          initialValue: member.role ?? '',
                                          onChanged: (value) {
                                            setState(() {
                                              member.role = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          maxLines: null, // 줄바꿈 허용
                                        ),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
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
        final editMembersUrl = 'https://bowling-rolling.com/api/v1/member/edit/all';

        try {
          for (var member in modifiedMembers) {
            await _apiClient.post(context, editMembersUrl, data: member.toJson());
          }
          Utils.showAlertDialog(context, '멤버 수정을 성공했습니다.');
        } catch (e) {
          Utils.showAlertDialog(context, '멤버 수정을 실패했습니다.');
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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width - 60,
                        ),
                        child: Table(
                          border: TableBorder.all(color: Colors.grey[300]!),
                          columnWidths: {
                            0: FlexColumnWidth(0.2),
                            1: FlexColumnWidth(0.3),
                            2: FlexColumnWidth(0.4),
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: Colors.blueGrey[50],
                              ),
                              children: [
                                TableCell(child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('대상', style: TextStyle(fontWeight: FontWeight.bold)),
                                )),
                                TableCell(child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('사번', style: TextStyle(fontWeight: FontWeight.bold)),
                                )),
                                TableCell(child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('이름', style: TextStyle(fontWeight: FontWeight.bold)),
                                )),
                              ],
                            ),
                            ...members.asMap().entries.map((entry) {
                              int index = entry.key;
                              Member member = entry.value;
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                ),
                                children: [
                                  TableCell(child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Checkbox(
                                      value: checkedList[index],
                                      onChanged: (value) {
                                        setState(() {
                                          checkedList[index] = value!;
                                        });
                                      },
                                    ),
                                  )),
                                  TableCell(child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(member.userId.toString()),
                                  )),
                                  TableCell(child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(member.userName),
                                  )),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
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
      final deleteMembersUrl = 'https://bowling-rolling.com/api/v1/member/delete';

      try {
        for (var member in result) {
          await _apiClient.post(context,deleteMembersUrl,data: {'userId': member.userId});
        }
        Utils.showAlertDialog(context, '멤버 삭제를 성공했습니다.');
      } catch (e) {
        Utils.showAlertDialog(context, '멤버 삭제를 실패했습니다.');
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
        appBar: AppBar(
          backgroundColor: Colors.white, // Make sure the background is white
          elevation: 0, // No shadow or elevation
          centerTitle: true, // Center the title
          title: Text(
          '설정',
          style: TextStyle(
            color: Colors.black, // Text color should be black
            fontSize: 18,
            fontWeight: FontWeight.bold,
            ),
          )
        ),
        body: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: imageFileName != null
                              ? AssetImage('$imageFileName')
                              : AssetImage('default.png'), // 예시로 기본 이미지를 설정할 수 있습니다.
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
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
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: Column(
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
                                Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => ProfilePictureSelection()));
                              },
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                // SizedBox(height: 20),
                // SwitchListTile(
                //   title: Text('사진 권한 접근'),
                //   subtitle: Text('사진 업로드 기능을 사용 하기 위한 권한 접근 설정입니다.'),
                //   value: photoPermission,
                //   onChanged: (bool value) {
                //     print('변경 전 사진 권한 : $photoPermission');
                //     _togglePhotoPermission();
                //     print('변경 후 사진 권한 : $photoPermission');
                //   },
                // ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        '취미반 멤버',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 8,
                      child: Row(
                        children: [
                          if (role == 'ADMIN') ...[
                            Flexible(
                              child: TextButton.icon(
                                icon: Icon(Icons.add),
                                label: Text('추가'),
                                onPressed: _addMember,
                              ),
                            ),
                            Flexible(
                              child: TextButton.icon(
                                icon: Icon(Icons.edit),
                                label: Text('수정'),
                                onPressed: _editMembers,
                              ),
                            ),
                            Flexible(
                              child: TextButton.icon(
                                icon: Icon(Icons.delete),
                                label: Text('삭제'),
                                onPressed: _deleteMember,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey, width: 1),
                    columnWidths: role == 'ADMIN'
                        ? {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(3),
                      3: FlexColumnWidth(3),
                      4: FlexColumnWidth(2),
                      5: FlexColumnWidth(2),
                    }
                        : {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(3),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '순번',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '사번',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '이름',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (role == 'ADMIN') ...[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '프로필 이미지 이름',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '계정 상태',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '권한',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      ...members.map((member) {
                        int index = members.indexOf(member);
                        return TableRow(
                          decoration: BoxDecoration(
                            color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('${index + 1}'),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(member.userId.toString()),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(member.userName),
                            ),
                            if (role == 'ADMIN') ...<Widget>[
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(member.imageFileName ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(member.statusYn),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(member.role ?? ''),
                              ),
                            ],
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.white,
          shape: CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: kBottomNavigationBarHeight,
            child: Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], // 그라데이션 색상
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.home, color: Colors.white, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: (kBottomNavigationBarHeight - 42) / 2, // 높이를 맞추기 위해 조정
                  child: ElevatedButton(
                    onPressed: _logout,
                    child: Text(
                      '로그아웃',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF42A5F5), // 밝은 하늘색으로 변경
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // padding 조정
                      elevation: 4,
                      textStyle: TextStyle(fontSize: 16),
                      minimumSize: Size(120, 50), // 버튼 크기를 홈 버튼과 맞춤
                    ),
                  ),
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
