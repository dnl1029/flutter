import 'package:flutter/material.dart';

class Utils {
  static void showAlertDialog(BuildContext context, String message, {VoidCallback? onConfirmed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text("알림"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
                if (onConfirmed != null) {
                  onConfirmed();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
