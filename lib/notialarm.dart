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
        body: Container(
          // color: Colors.white,
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(20),
          width: 350,
          height: 230,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black26),
              color: Colors.white
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20,),
              Icon(Icons.notifications_none,color: Colors.blue,),
              SizedBox(height: 10,),
              Text('볼케이노에서 알림을 보내도록 허용하시겠습니까?',style: TextStyle(color: Colors.black,fontSize: 14),),
              SizedBox(height: 20,),
              TextButton(onPressed: (){}, child: Text('허용',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black, fontSize: 18),)),
              SizedBox(height: 20,),
              TextButton(onPressed: (){}, child: Text('허용 안함',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.black, fontSize: 18),)),
            ],
          ),
        )
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

