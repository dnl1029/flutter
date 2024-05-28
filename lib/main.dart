import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naver Login',
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back, color: Colors.black),
        //   onPressed: () {},
        // ),
      ),
      body:
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '아이디',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        //9CB3CBFF
                        // backgroundColor: Colors.lightGreen, // Updated parameter
                        backgroundColor: Color(0xff99B2CC),
                        padding: EdgeInsets.symmetric(vertical: 23),
                      ),
                      child: Text('로그인',style: TextStyle(color: Colors.white,fontSize: 20)),
                    ),
                  ),
                  SizedBox(height: 25),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(onPressed: () {},
                            child: Text('비밀번호 찾기',style: TextStyle(color: Colors.grey),)
                        ),
                        Text(' | ',style: TextStyle(color: Colors.grey),),
                        TextButton(onPressed: () {},
                            child: Text('아이디 찾기',style: TextStyle(color: Colors.grey),)
                        ),
                        Text(' | ',style: TextStyle(color: Colors.grey),),
                        TextButton(onPressed: () {},
                            child: Text('회원가입',style: TextStyle(color: Colors.blue),)
                        )
                      ],
                    ),),
                ],
              ),
            ),
          )

    );
  }
}
