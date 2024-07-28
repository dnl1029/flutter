import 'dart:convert';
import 'package:contact/utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import 'main_screen.dart';

class ProfilePictureSelection extends StatefulWidget {
  @override
  _ProfilePictureSelectionState createState() => _ProfilePictureSelectionState();
}

class _ProfilePictureSelectionState extends State<ProfilePictureSelection> {
  int? selectedPictureIndex; // null 허용 타입으로 변경
  String? imageFileName;
  String? uploadedImageUrl;

  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();
  final int serverImageCount = 9; // 서버에 있는 이미지 개수

  @override
  void initState() {
    super.initState();
    _apiClient.checkTokenValidity(context);
  }

  Future<void> _saveImageFileName() async {
    final editImageFileNameUrl = 'https://bowling-rolling.com/api/v1/edit/myImageFileName';

    String? finalImageFileName;
    if (selectedPictureIndex != null) {
      finalImageFileName = '${selectedPictureIndex! + 1}.png';
    } else if (uploadedImageUrl != null) {
      finalImageFileName = uploadedImageUrl;
    }

    if (finalImageFileName != null) {
      try {
        final response = await _apiClient.post(
          context,
          editImageFileNameUrl,
          data: jsonEncode({"imageFileName": finalImageFileName}),
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

  Future<void> _uploadImageAndGetUrl() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      try {
        final response = await _apiClient.uploadFile(
          context,
          'https://bowling-rolling.com/api/gpt/upload',
          image,
        );

        if (response.statusCode == 200) {
          final responseData = response.data;
          final link = responseData['data']['link'];
          setState(() {
            uploadedImageUrl = link;
            selectedPictureIndex = null; // 기존 선택 초기화
            print("uploadedImageUrl :$uploadedImageUrl");
          });

          // 이미지 업로드가 성공하면 _saveImageFileName 호출
          await _saveImageFileName();
        } else {
          Utils.showAlertDialog(context, '이미지 업로드를 실패하였습니다.');
        }
      } catch (e) {
        Utils.showAlertDialog(context, '이미지 업로드를 실패하였습니다.');
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
                itemCount: serverImageCount,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedPictureIndex = index;
                        uploadedImageUrl = null; // 업로드된 이미지 선택 초기화
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
            TextButton.icon(
              icon: Icon(Icons.file_upload, color: Colors.blue),
              label: Text(
                '수동으로 프로필 사진 업로드하기',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: _uploadImageAndGetUrl,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D47A1),
                surfaceTintColor: Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: (selectedPictureIndex != null || uploadedImageUrl != null)
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
