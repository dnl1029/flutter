import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'permission_information.dart';
import 'main_screen.dart';
import 'login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasPermission = false;
  String? _jwtToken;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _checkPermissionAndToken();
    });
  }

  Future<void> _checkPermissionAndToken() async {
    _hasPermission = (await storage.read(key: 'hasPermission')) == 'true';
    _jwtToken = await storage.read(key: 'jwtToken');

    if (_hasPermission) {
      if (_jwtToken == null) {
        navigatorKey.currentState?.pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
      } else {
        navigatorKey.currentState?.pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));
      }
    } else {
      navigatorKey.currentState?.pushReplacement(MaterialPageRoute(builder: (context) => PermissionGuideScreen(navigatorKey: navigatorKey)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // MaterialApp에 navigatorKey 할당
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
