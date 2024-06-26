import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_interceptor.dart'; // ApiInterceptor 클래스 import

import 'login.dart';
import 'main_screen.dart';

class ProfilePictureSelection extends StatefulWidget {
  @override
  _ProfilePictureSelectionState createState() => _ProfilePictureSelectionState();
}

class _ProfilePictureSelectionState extends State<ProfilePictureSelection> {
  int? selectedPictureIndex; // null 허용 타입으로 변경
  String? imageFileName;

  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final dio.Dio _dio = dio.Dio();

  _ProfilePictureSelectionState() {
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

  Future<void> _saveImageFileName() async {
    final storedToken = await _storage.read(key: 'jwtToken');
    final editImageFileNameUrl = 'https://bowling-rolling.com/api/v1/edit/myImageFileName';

    if (selectedPictureIndex != null) {
      final imageFileName = '${selectedPictureIndex! + 1}.png';
      checkTokenValidity();

      try {
        final response = await _dio.post(
          editImageFileNameUrl,
          options: dio.Options(
            headers: {"jwtToken": storedToken},
          ),
          data: jsonEncode({"imageFileName": imageFileName}),
        );

        if (response.statusCode == 200 && response.data['code'] == '200') {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text('이미지 수정을 성공했습니다.'),
          //   ),
          // );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미지 수정 실패: ${response.data['message']}'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 수정 실패: $e'),
          ),
        );
      }
    }
  }

  Future<void> checkTokenValidity() async {
    final storedToken = await _storage.read(key: 'jwtToken');
    if (storedToken == null) {
      _logout(); // Logout if token is null
      return;
    }

    final validationUrl = 'https://bowling-rolling.com/api/v1/jwt/validation';
    try {
      final response = await _dio.post(
        validationUrl,
        data: jsonEncode({"jwtToken": storedToken}),
      );

      if (response.statusCode == 200 && response.data['code'] == '200') {
        final isValid = response.data['message'];
        if (isValid == 'true') {
          print('JWT Token is valid.');
        } else {
          _logout(); // Logout if token is invalid
        }
      } else {
        _logout(); // Logout on validation failure
        print('JWT Token validation failed');
      }
    } catch (e) {
      _logout(); // Logout on network error
      print('JWT Token validation error: $e');
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'jwtToken'); // 토큰 삭제
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 이미지 선택'),
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white, // 배경을 흰색으로 설정
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(10),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPictureIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white, // 이미지 컨테이너 배경을 흰색으로 설정
                        border: Border.all(
                          color: selectedPictureIndex == index
                              ? Colors.blue
                              : Colors.black26, // 선택되지 않은 이미지는 검은색 테두리
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Image.asset(
                              '${index + 1}.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (selectedPictureIndex == index)
                            Align(
                              alignment: Alignment.topRight,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: 16,),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D47A1),
                    surfaceTintColor: Color(0xFF0D47A1),
                    foregroundColor: Colors.white
                ),
                onPressed: selectedPictureIndex != null
                    ? _saveImageFileName // 저장 버튼 클릭 시 _saveImageFileName 호출
                    : null,
                child: Text('저장')
            )
          ],
        ),
      )
    );
  }
}
