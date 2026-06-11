import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faltas_scraper_flutter/core/network/auth_interceptor.dart';

void main() {
  group('AuthInterceptor.isExpired', () {
    test('200 com JSON não é expirado', () {
      final r = Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: {'data': []},
      );
      expect(AuthInterceptor.isExpired(r), isFalse);
    });
    test('401 é expirado', () {
      final r = Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 401,
      );
      expect(AuthInterceptor.isExpired(r), isTrue);
    });
    test('302 para Login.aspx é expirado', () {
      final r = Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 302,
        headers: Headers.fromMap({
          'location': ['https://x/EduPortalAlunoLogin.aspx?foo']
        }),
      );
      expect(AuthInterceptor.isExpired(r), isTrue);
    });
    test('200 com HTML de login é expirado', () {
      final r = Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 200,
        data: '<html>EduPortalAlunoLogin.aspx</html>',
      );
      expect(AuthInterceptor.isExpired(r), isTrue);
    });
  });

  group('single-flight refresh', () {
    test('múltiplas chamadas concorrentes refrescam uma vez', () async {
      var calls = 0;
      final int = AuthInterceptor(
        refresh: () async {
          calls++;
          await Future.delayed(const Duration(milliseconds: 20));
          return true;
        },
        retry: (o) async =>
            Response(requestOptions: o, statusCode: 200, data: {'ok': true}),
      );
      await Future.wait([int.runRefresh(), int.runRefresh(), int.runRefresh()]);
      expect(calls, 1);
    });
  });
}
