import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'login.dart';

class ApiInterceptor {
  final dio.Dio _dio;
  final FlutterSecureStorage _storage;
  final GlobalKey<NavigatorState> navigatorKey; // Add navigatorKey here

  ApiInterceptor(this._dio, this._storage, this.navigatorKey) {
    _dio.interceptors.add(dio.InterceptorsWrapper(
      onRequest: (options, handler) async {
        await checkTokenValidity(options as dio.Options); // Pass options to checkTokenValidity
        final storedToken = await _storage.read(key: 'jwtToken');
        if (storedToken != null) {
          options.headers["jwtToken"] = storedToken;
        }
        print("Request[${options.method}] => PATH: ${options.path}");
        print("Headers: ${options.headers}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print("Response[${response.statusCode}] => DATA: ${response.data}");
        return handler.next(response);
      },
      onError: (dio.DioError e, handler) {
        print("Error[${e.response?.statusCode}] => MESSAGE: ${e.message}");
        return handler.next(e);
      },
    ));
  }

  Future<void> checkTokenValidity(dio.Options options) async {
    final storedToken = await _storage.read(key: 'jwtToken');
    if (storedToken == null) {
      _logout(); // Logout if token is null
      return;
    }

    final validationUrl = 'https://bowling-rolling.com/api/v1/jwt/validation';
    try {
      final response = await _dio.post(
        validationUrl,
        data: jsonEncode({"jwtToken": storedToken}),
        options: options, // Pass options here
      );

      if (response.statusCode == 200 && response.data['code'] == '200') {
        final isValid = response.data['message'];
        if (isValid == 'true') {
          print('JWT Token is valid.');
        } else {
          _logout(); // Logout if token is invalid
        }
      } else {
        _logout(); // Logout on validation failure
        print('JWT Token validation failed');
      }
    } catch (e) {
      _logout(); // Logout on network error
      print('JWT Token validation error: $e');
    }
  }

  void _logout() {
    _storage.delete(key: 'jwtToken'); // Delete token
    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }
}
