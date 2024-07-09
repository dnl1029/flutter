import 'dart:convert';
import 'package:contact/utils.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'main_screen.dart';

class ProfilePictureSelection extends StatefulWidget {
  @override
  _ProfilePictureSelectionState createState() => _ProfilePictureSelectionState();
}

class _ProfilePictureSelectionState extends State<ProfilePictureSelection> {
  int? selectedPictureIndex; // null 허용 타입으로 변경
  String? imageFileName;

  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _apiClient.checkTokenValidity(context);
  }

  Future<void> _saveImageFileName() async {
    final editImageFileNameUrl = 'https://bowling-rolling.com/api/v1/edit/myImageFileName';

    if (selectedPictureIndex != null) {
      final imageFileName = '${selectedPictureIndex! + 1}.png';
      try {
        final response = await _apiClient.post(context,
          editImageFileNameUrl,
          data: jsonEncode({"imageFileName": imageFileName}),
        );

        if (response.statusCode == 200 && response.data['code'] == '200') {
          Utils.showAlertDialog(context, '프로필 사진이 성공적으로 저장되었습니다.', onConfirmed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen()));
          });
        } else {
          Utils.showAlertDialog(context, '프로필 사진 수정을 실패하였습니다.');
        }
      } catch (e) {
        Utils.showAlertDialog(context, '프로필 사진 수정을 실패하였습니다.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 이미지 선택'),
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white,
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
                        color: Colors.white,
                        border: Border.all(
                          color: selectedPictureIndex == index
                              ? Colors.blue
                              : Colors.black26,
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
            SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D47A1),
                surfaceTintColor: Color(0xFF0D47A1),
                foregroundColor: Colors.white,
              ),
              onPressed: selectedPictureIndex != null
                  ? _saveImageFileName
                  : null,
              child: Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
