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
        // body: Row(
        //   children: [
        //     //Flexible로 비율 설정할수 있음.
        //     Flexible(child: Container(color: Colors.blue,), flex: 3,),
        //     Flexible(child: Container(color: Colors.green,), flex: 7,),
        //     Container(),
        //   ],
        // ),
        body: Container(
          height: 300,
          padding: EdgeInsets.all(10),
          // margin: EdgeInsets.all(10),
          child: Row(
            children: [
              Flexible(child: Image.asset('sample.png'),flex: 4,),
              Flexible(child:
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('   카메라팝니다'),
                    Text('   금호동 3가'),
                    Text('   7000원'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.favorite),
                        Text('4')
                      ],
                    )

                  ],
                ),
              ), flex: 6,)
            ],
          ),
        ),

      )
    );

  }
}
