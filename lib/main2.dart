import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      // home: Text('안녕ㅎ')
      // home: Icon(Icons.shop)
      // home: Image.asset('sample.png')
      // home: Container( width: 50, height: 50, color: Colors.blue )
      // home: Center(
      //   child: Container( width: 50, height: 50, color: Colors.blue )
      // )
      // 상중하로 나눠주기
      home: Scaffold(
        // appBar: AppBar(),
        // body: Container(
        //   child: Icon(Icons.star),
        // ),
        // bottomNavigationBar: BottomAppBar(child: Text('bottom')),
        // 여러위젯 가로로 배치하는 법
        // body : Row(
        // body: Column(
        //   //가운데 정렬
        //   // mainAxisAlignment: MainAxisAlignment.center,
        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //   //ctrl + space : 자동완성
        //   // crossAxisAlignment: CrossAxisAlignment.center,
        //   children: [
        //     Icon(Icons.star),
        //     Icon(Icons.star),
        //     Icon(Icons.star),
        //   ],
        // )
        appBar: AppBar(
          leading: Icon(Icons.star),
          title: Text('앱임'),
          titleTextStyle: TextStyle(fontSize: 20,color: Colors.white),
          backgroundColor: Colors.blue,
          actions: [Icon(Icons.star), Icon(Icons.star)],
        ),
        // body: Text('안녕'),
        // body: Center(
        // body: Align(
        //   alignment: Alignment.bottomCenter,
        //   child: Container(
        //     width: double.infinity, height: 50,
        //     // , color: Colors.blue,
        //     // margin: EdgeInsets.all(20),
        //     // margin은 컨테이너 바깥쪽 여백, padding은 container 안쪽 여백
        //     // 나머지 박스 스타일은 decoration 안에 넣어야함
        //     padding: EdgeInsets.all(20),
        //     margin: EdgeInsets.fromLTRB(0, 30, 0, 30),
        //     // decoration: BoxDecoration(
        //     //   border: Border.all(color: Colors.black)
        //     // ),
        //     color: Colors.blue,
        //   ),
        // )
        // body: Container(
        //   child: Text('안녕'),
        // ),
        // row는 상하폭 조절이 안돼서, Container 안에 Row를 넣음. Row 클릭하여 전구클릭. 
        // width, height, child만 필요하면 무거운 Container대신 SizedBox 사용
        //   body: SizedBox(
        //     child: Text('안녕하세요',
        //     style: TextStyle(
        //         color: Color(0xff4b78ff),
        //         fontSize: 50,
        //         fontWeight: FontWeight.w700),),
        //   )
        // 버튼 위젯은 TextButton(), IconButton(), ElevatedButton() 택1
        //   body: SizedBox(
        //     child: ElevatedButton(
        //       child: Text('글자')
        //       ,onPressed: (){},
        //     style: ButtonStyle(),
        //     ),
        //
        //   )
          body: Container(
            width: double.infinity,
            height: 600,
            child: Row(
              children: [Image.asset('sample.png',width: 500,height: 500,fit: BoxFit.contain,),
              Container(
                child: Column(
                  children: [
                    Text('캐논 DSLR 100D (단렌즈, 충전기 16기가SD 포함)'),
                    Text('성동구 행당동 · 끌올 10분 전'),
                    Text('210,000원'),
                    Container(
                      child: Row(
                        children: [
                          Icon(Icons.heart_broken),
                          Text('4')
                        ],
                      ),
                    )
                  ],
                ),
              )
              ],
            ),
          )
        ,
        bottomNavigationBar: BottomAppBar(
          child: SizedBox(
            height: 70,
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.phone),
              Icon(Icons.message),
              Icon(Icons.contact_page)
            ],
                    ),
          ),),
      ),
    );

  }
}
