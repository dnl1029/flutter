import 'dart:html';

class WebStorage {
  // JWT 토큰 저장
  void write(String key, String value) {
    window.localStorage[key] = value;
  }

  // JWT 토큰 읽기
  String? read(String key) {
    return window.localStorage[key];
  }

  // JWT 토큰 삭제
  void delete(String key) {
    window.localStorage.remove(key);
  }
}