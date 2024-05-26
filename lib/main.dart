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
      home: Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue,),
        body: ShopItem()
      )
    );

  }
}

//커스텀위젯만드려면, stless 쳐서 이거 만들어서 return에 길고 복잡한 레이아웃 넣음.
//column 대신 ListView를 쓰면 스크롤바생기고, 메모리 절약기능도 있음.
class ShopItem extends StatelessWidget {
  const ShopItem({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Text('안녕'),
    );
  }
}

