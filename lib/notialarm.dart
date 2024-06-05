import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 기본 배경 색상을 흰색으로 설정
      ),
      home: Notialarm()
    );

  }
}

class Notialarm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(20),
          width: 350,
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black26),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20,),
              Icon(Icons.notifications_none, color: Colors.blue,),
              SizedBox(height: 10,),
              Text.rich(
                TextSpan(
                  text: '', // 이 부분은 비워둡니다.
                  children: <TextSpan>[
                    TextSpan(
                      text: '볼케이노', // '볼케이노' 텍스트
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 14), // 굵게 표시
                    ),
                    TextSpan(
                      text: '에서 사진 및 동영상에 접근하도록 허용하시겠습니까?', // 나머지 텍스트
                      style: TextStyle(fontWeight: FontWeight.normal,
                          color: Colors.black,
                          fontSize: 14), // 기본 스타일
                    ),
                  ],
                ),
              ),
              // Text('볼케이노에서 사진 및 동영상에 접근하도록 허용하시겠습니까?',style: TextStyle(color: Colors.black,fontSize: 14),),
              SizedBox(height: 20,),
              TextButton(onPressed: () {},
                  child: Text('허용', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 18),)),
              SizedBox(height: 20,),
              TextButton(onPressed: () {},
                  child: Text('허용 안함', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 18),)),
            ],
          ),
        )
    );
  }
}

//커스텀위젯만드려면, stless 쳐서 이거 만들어서 return에 길고 복잡한 레이아웃 넣음.
//column 대신 ListView를 쓰면 스크롤바생기고, 메모리 절약기능도 있음.
// class ShopItem extends StatelessWidget {
//   const ShopItem({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       child: Text('안녕'),
//     );
//   }
// }

