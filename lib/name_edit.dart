import 'dart:convert';

import 'package:contact/utils.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';

class NameEditScreen extends StatefulWidget {
  final TextEditingController nameController;
  final Widget targetScreen;

  NameEditScreen({required this.nameController, required this.targetScreen});

  @override
  _NameEditScreenState createState() => _NameEditScreenState();
}

class _NameEditScreenState extends State<NameEditScreen> {
  final ApiClient _apiClient = ApiClient();

  Future<void> _saveName(BuildContext context) async {
    String name = widget.nameController.text;
    if (name.isEmpty) {
      Utils.showAlertDialog(context, '입력된 이름이 없습니다.',onConfirmed: () {
        return;
      });
    } else if (name.length > 20) {
      Utils.showAlertDialog(context, '이름이 20글자를 초과하였습니다.',onConfirmed: () {
        return;
      });
    }

    final saveNameUrl = "https://bowling-rolling.com/api/v1/edit/myName";
    try {
      final saveNameResponse = await _apiClient.post(context,
        saveNameUrl,
        data: jsonEncode({"userName": name}),
      );

      final responseBody = saveNameResponse.data;
      if (saveNameResponse.statusCode == 200 && responseBody['code'] == '200') {
        print('이름 저장 성공: $name');
        Utils.showAlertDialog(context, '이름이 성공적으로 저장되었습니다.', onConfirmed: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => widget.targetScreen));
        });
      } else {
        Utils.showAlertDialog(context, '이름 저장에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      Utils.showAlertDialog(context, '이름 저장 중 오류가 발생했습니다. 다시 시도해주세요.');
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
