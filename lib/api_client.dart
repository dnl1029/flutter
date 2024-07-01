import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html; // dart:html 패키지 임포트

import 'package:contact/storage_custom.dart';
import 'package:contact/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 추가

import 'login.dart';

class ApiClient {
  final Dio _dio = Dio();

  ApiClient() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storedToken = await StorageCustom.read('jwtToken');
          options.headers["jwtToken"] = storedToken;
          print("Request[${options.method}] => PATH: ${options.path}");
          print("Headers: ${options.headers}");
          return handler.next(options); // continue
        },
        onResponse: (response, handler) {
          print("Response[${response.statusCode}] => DATA: ${response.data}");
          return handler.next(response); // continue
        },
        onError: (DioException e, handler) {
          print("Error[${e.response?.statusCode}] => MESSAGE: ${e.message}");
          return handler.next(e); // continue
        },
      ),
    );
  }

  Future<Response> get(BuildContext context, String url, {Map<String, dynamic>? params}) async {
    await checkTokenValidity(context);
    return _dio.get(url, queryParameters: params);
  }

  Future<Response> post(BuildContext context, String url, {dynamic data}) async {
    await checkTokenValidity(context);
    return _dio.post(url, data: data);
  }

  // 유사하게 put, delete 등의 메서드도 추가
  Future<Response> put(BuildContext context, String url, {dynamic data}) async {
    await checkTokenValidity(context);
    return _dio.put(url, data: data);
  }

  Future<Response> delete(BuildContext context, String url, {dynamic data}) async {
    await checkTokenValidity(context);
    return _dio.delete(url, data: data);
  }

  Future<void> checkTokenValidity(BuildContext context) async {
    final storedToken = await StorageCustom.read('jwtToken');
    if (storedToken == null) {
      logout(context); // Logout if token is null
      return;
    }

    final validationUrl = 'https://bowling-rolling.com/api/v1/jwt/validation';
    try {
      final response = await _dio.post(
        validationUrl,
        data: jsonEncode({"jwtToken": storedToken}),
      );

      if (response.statusCode == 200 && response.data['code'] == '200') {
        final isValid = response.data['message'];
        if (isValid == 'true') {
          print('JWT Token is valid.');
        } else {
          logout(context); // Logout if token is invalid
        }
      } else {
        logout(context); // Logout on validation failure
        print('JWT Token validation failed');
      }
    } catch (e) {
      logout(context); // Logout on network error
      print('JWT Token validation error: $e');
    }
  }

  Future<Response> uploadFile(BuildContext context, String url, dynamic file) async {
    await checkTokenValidity(context);

    FormData formData;

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      formData = FormData.fromMap({
        "image": MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      });
    } else {
      Uint8List bytes = file.readAsBytesSync();
      formData = FormData.fromMap({
        "image": MultipartFile.fromBytes(
          bytes,
          filename: file.path.split('/').last,
        ),
      });
    }

    return _dio.post(url, data: formData);
  }


  Future<Uint8List> _readBlobAsUint8List(html.Blob blob) async {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(blob);
    await reader.onLoadEnd.first;
    return reader.result as Uint8List;
  }

  Future<void> logout(BuildContext context) async {
    await StorageCustom.delete('jwtToken'); // 토큰 삭제
    Utils.showAlertDialog(context, '로그인이 만료되었습니다. 다시 로그인해주세요.',onConfirmed: (){
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    });
  }
}
