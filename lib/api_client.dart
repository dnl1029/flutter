import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:contact/storage_custom.dart';
import 'package:contact/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login.dart';

class ApiClient {
  final Dio _dio = Dio();
  bool _isLoggingOut = false;
  Completer<void>? _tokenCheckCompleter;
  Completer<void>? _logoutCompleter; // 추가된 로그아웃 관리용 컴플리터

  ApiClient() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final storedToken = await StorageCustom.read('jwtToken');
          options.headers["jwtToken"] = storedToken;
          print("Request[${options.method}] => PATH: ${options.path}");
          print("Headers: ${options.headers}");
          if (options.method == 'POST') {
            print("Request Body: ${options.data}");
          }
          return handler.next(options); // continue
        },
        onResponse: (response, handler) {
          print("Response[${response.statusCode}] => DATA: ${response.data}");
          return handler.next(response); // continue
        },
        onError: (DioException e, handler) {
          print("Error[${e.response?.statusCode}] => MESSAGE: ${e.message}");
          if (e.response?.statusCode == 401) {
            _handleUnauthorized(e.requestOptions);
          }
          return handler.next(e); // continue
        },
      ),
    );
  }

  Future<void> _handleUnauthorized(RequestOptions requestOptions) async {
    await checkTokenValidity(requestOptions.extra['context']);
  }

  Future<Response> get(BuildContext context, String url, {Map<String, dynamic>? params}) async {
    await checkTokenValidity(context);
    return _dio.get(url, queryParameters: params);
  }

  Future<Response> post(BuildContext context, String url, {dynamic data}) async {
    await checkTokenValidity(context);
    return _dio.post(url, data: data);
  }

  Future<Response> put(BuildContext context, String url, {dynamic data}) async {
    await checkTokenValidity(context);
    return _dio.put(url, data: data);
  }

  Future<Response> delete(BuildContext context, String url, {dynamic data}) async {
    await checkTokenValidity(context);
    return _dio.delete(url, data: data);
  }

  Future<void> checkTokenValidity(BuildContext context) async {
    if (_tokenCheckCompleter != null) {
      await _tokenCheckCompleter!.future;
      return;
    }

    _tokenCheckCompleter = Completer<void>();

    final storedToken = await StorageCustom.read('jwtToken');
    if (storedToken == null) {
      await _performLogout(context);
      _tokenCheckCompleter!.complete();
      _tokenCheckCompleter = null;
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
          await _performLogout(context);
        }
      } else {
        await _performLogout(context);
        print('JWT Token validation failed');
      }
    } catch (e) {
      await _performLogout(context);
      print('JWT Token validation error: $e');
    } finally {
      _tokenCheckCompleter!.complete();
      _tokenCheckCompleter = null;
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    if (_logoutCompleter != null) {
      await _logoutCompleter!.future;
      return;
    }

    _logoutCompleter = Completer<void>();

    await StorageCustom.delete('jwtToken');
    Utils.showAlertDialog(context, '로그인이 만료되었습니다. 다시 로그인해주세요.', onConfirmed: () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    });

    _logoutCompleter!.complete();
    _logoutCompleter = null;
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
}
