import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart' as dio;

import 'main_screen.dart';

class NameEditScreen extends StatefulWidget {
  final TextEditingController nameController;
  final Widget targetScreen;

  NameEditScreen({required this.nameController, required this.targetScreen});

  @override
  _NameEditScreenState createState() => _NameEditScreenState();
}

class _NameEditScreenState extends State<NameEditScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final dio.Dio _dio = dio.Dio();

  _NameEditScreenState() {
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

  void _showAlertDialog(BuildContext context, String message, {VoidCallback? onConfirmed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("알림"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirmed != null) {
                  onConfirmed();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveName(BuildContext context) async {
    String name = widget.nameController.text;
    final storedToken = await _storage.read(key: 'jwtToken');
    if (storedToken == null) {
      _showAlertDialog(context, 'JWT 토큰을 가져오는 데 실패했습니다.');
      return;
    }
    if (name.isEmpty) {
      _showAlertDialog(context, '입력된 이름이 없습니다.');
      return;
    } else if (name.length > 20) {
      _showAlertDialog(context, '이름이 20글자를 초과하였습니다.');
      return;
    }

    final saveNameUrl = "https://bowling-rolling.com/api/v1/edit/myName";

    try {
      final saveNameResponse = await _dio.post(
        saveNameUrl,
        options: dio.Options(
          headers: {'Content-Type': 'application/json', 'jwtToken': storedToken},
        ),
        data: jsonEncode({"userName": name}),
      );

      final responseBody = saveNameResponse.data;
      if (saveNameResponse.statusCode == 200 && responseBody['code'] == '200') {
        print('이름 저장 성공: $name');
        _showAlertDialog(context, '이름이 성공적으로 저장되었습니다.', onConfirmed: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => widget.targetScreen));
        });
      } else {
        _showAlertDialog(context, '이름 저장에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      _showAlertDialog(context, '이름 저장 중 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('이름 추가/변경'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: widget.nameController,
              decoration: InputDecoration(
                labelText: '이름을 입력해주세요',
                border: OutlineInputBorder(),
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
                onPressed: () => _saveName(context),
                child: Text('저장')
            )
          ],
        ),
      )
    );
  }
}
