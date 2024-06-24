import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProfilePictureSelection(),
    );
  }
}

class ProfilePictureSelection extends StatefulWidget {
  @override
  _ProfilePictureSelectionState createState() => _ProfilePictureSelectionState();
}

class _ProfilePictureSelectionState extends State<ProfilePictureSelection> {
  int? selectedPictureIndex; // null 허용 타입으로 변경

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('프로필 이미지 선택'),
      ),
      body: Column(
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
                      border: Border.all(
                        color: selectedPictureIndex == index
                            ? Colors.blue
                            : Colors.transparent,
                        width: 3,
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
          Padding(
            padding: EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: selectedPictureIndex != null
                  ? () {
                // 확인 버튼 클릭시 처리할 로직
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile picture ${selectedPictureIndex! + 1} selected'),
                  ),
                );
              }
                  : null,
              child: Text('확인'),
            ),
          ),
        ],
      ),
    );
  }
}
