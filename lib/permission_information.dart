import 'package:contact/my_flutter_app_icons.dart';
import 'package:contact/storage_custom.dart';
import 'package:flutter/foundation.dart'; // kIsWeb이 포함된 패키지
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'main_screen.dart';

class PermissionGuideScreen extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  PermissionGuideScreen({required this.navigatorKey});

  Future<void> grantPermission() async {
    if (kIsWeb) {
      // 웹에서는 권한 요청을 생략하고 바로 true로 저장
      await StorageCustom.write('hasPhotoPermission', 'true');
    } else {
      // 모바일에서 app에서는 권한을 요청하고 결과를 받아옴
      var status = await Permission.photos.request();

      // 권한이 승인되었는지 확인
      if (status.isGranted) {
        // 승인된 경우에만 true로 저장
        await StorageCustom.write('hasPhotoPermission', 'true');
      } else {
        // 승인되지 않은 경우 false로 저장하거나 다른 처리를 수행할 수 있음
        await StorageCustom.write('hasPhotoPermission', 'false');
      }
    }

    // 메인 화면으로 이동
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(
          CustomIcons.bowling_ball,
          color: Colors.red,
        ),
        backgroundColor: Colors.white,
        title: Text(
          '볼케이노',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 50,
            ),
            Text(
              '볼케이노 앱 이용을 위한 접근 권한 안내',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 25,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 30,
            ),
            Container(
              padding: EdgeInsetsDirectional.fromSTEB(20, 20, 20, 20),
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('사진 및 동영상(선택)',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(
                    height: 5,
                  ),
                  Text('볼링 점수판 사진 등록 시'),
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              '※ 선택 접근권한은 고객님께 더 나은 서비스 제공을 위해 사용되며, 허용하지 않으셔도 앱 이용이 가능합니다.',
              style: TextStyle(color: Colors.black54),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              '※ 접근 권한 변경 안내',
              style: TextStyle(color: Colors.black54),
            ),
            Text(
              '     휴대폰 설정 > 앱 또는 애플리케이션 > 볼케이노',
              style: TextStyle(color: Colors.black54),
            ),
            SizedBox(
              height: 100,
            ),
            ElevatedButton(
              onPressed: () => grantPermission(),
              style: ElevatedButton.styleFrom(
                //9CB3CBFF
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Color(0xFF0D47A1),
                  surfaceTintColor: Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5))
                // padding: EdgeInsets.symmetric(vertical: 20),
              ),
              child: Text('확인',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
