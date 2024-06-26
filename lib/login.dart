import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:convert';
import 'image_edit.dart';
import 'main_screen.dart';
import 'name_edit.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _userIdController = TextEditingController();
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final dio.Dio _dio = dio.Dio();
  final TextEditingController nameController = TextEditingController();

  LoginScreen() {
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

  Future<void> _login(BuildContext context) async {
    final int? userId = int.tryParse(_userIdController.text);
    if (userId == null) {
      _showAlertDialog(context, '사번을 올바르게 숫자로 입력해주세요.');
      return;
    }

    final url = 'https://bowling-rolling.com/api/v1/login';

    try {
      final response = await _dio.post(
        url,
        options: dio.Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: jsonEncode({"userId": userId}),
      );

      final responseBody = response.data;
      if (response.statusCode == 200) {
        if (responseBody['code'] == '200') {
          final jwtToken = responseBody['message'].toString();
          await _storage.write(key: 'jwtToken', value: jwtToken);
          print('LoginScreen jwtToken : $jwtToken');

          final getNameUrl = 'https://bowling-rolling.com/api/v1/get/myName';
          final getImageFileNameUrl = 'https://bowling-rolling.com/api/v1/get/myImage';

          final storedToken = await _storage.read(key: 'jwtToken');
          if (storedToken == null) {
            _showAlertDialog(context, 'JWT 토큰을 가져오는 데 실패했습니다.');
            return;
          }

          final getNameResponse = await _dio.get(
            getNameUrl,
            options: dio.Options(
              headers: {"jwtToken": storedToken,
              },
            ),
          );

          final getImageFileNameResponse = await _dio.get(
            getImageFileNameUrl,
            options: dio.Options(
              headers: {"jwtToken": storedToken},
            ),
          );

          final getNameResponseBody = getNameResponse.data;
          final getImageFileNameResponseBody = getImageFileNameResponse.data;

          if (getNameResponseBody['code'] == '204' && getImageFileNameResponseBody['code'] == '204') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NameEditScreen(
                  nameController: nameController,
                  targetScreen: ProfilePictureSelection(),
                ),
              ),
            );
          }
          else if(getNameResponseBody['code'] == '204' && getImageFileNameResponseBody['code'] == '200'){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NameEditScreen(
                  nameController: nameController,
                  targetScreen: MainScreen(),
                ),
              ),
            );
          }
          else if(getNameResponseBody['code'] == '200' && getImageFileNameResponseBody['code'] == '204'){
            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePictureSelection()));
          }
          else if (getNameResponseBody['code'] == '200' && getImageFileNameResponseBody['code'] == '200') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
          }
        } else {
          _showAlertDialog(context, '${responseBody['message']}');
        }
      } else {
        _showAlertDialog(context, '${responseBody['message']}');
      }
    } on dio.DioError catch (e) {
      if (e.response?.statusCode == 404) {
        _showAlertDialog(context, '취미반에 등록된 회원 정보가 없어 로그인 할 수 없습니다. 관리자에게 문의해주세요.\n(위형규 프로 / 010-6612-6330)');
      } else {
        _showAlertDialog(context, '로그인 중 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      _showAlertDialog(context, '로그인 중 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.background,
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
              SizedBox(width: 10),
              Text(
                "로그인 오류",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 32),
              TextField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: '사번',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _login(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D47A1),
                    surfaceTintColor: Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 23),
                  ),
                  child: Text('로그인', style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 25),
              Container(
                width: double.infinity,
                child: Text('※비밀번호 없이 사번 입력만으로 로그인 가능합니다. 본인의 사번으로만 로그인 해주세요.',style: TextStyle(color: Colors.grey,),textAlign: TextAlign.left,),
              )
            ],
          ),
        ),
      ),
    );
  }

}
