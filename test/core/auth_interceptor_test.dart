import 'dart:async';

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

  group('guarda de retry único', () {
    test('não refresca novamente se o retry também vier expirado', () async {
      var refreshCalls = 0;
      final interceptor = AuthInterceptor(
        refresh: () async {
          refreshCalls++;
          return true;
        },
        // O retry sempre devolve uma resposta ainda expirada (401).
        retry: (o) async =>
            Response(requestOptions: o, statusCode: 401, data: 'still expired'),
      );

      final options = RequestOptions(path: '/x');
      final initialResponse = Response(
        requestOptions: options,
        statusCode: 401,
      );

      // Primeira passagem: deve chamar refresh, fazer o retry e marcar a
      // RequestOptions como já retentada.
      final firstHandler = _CapturingHandler();
      interceptor.onResponse(initialResponse, firstHandler);
      final firstResult = await firstHandler.completer.future;

      expect(refreshCalls, 1);
      expect(firstResult.statusCode, 401);
      expect(options.extra['auth_retried'], isTrue);

      // Segunda passagem: a resposta retried (401, com a mesma RequestOptions
      // já marcada) reentra no interceptor. O guard deve impedir um novo
      // refresh e apenas repassar a resposta adiante.
      final retriedResponse = Response(
        requestOptions: options,
        statusCode: 401,
      );
      final secondHandler = _CapturingHandler();
      interceptor.onResponse(retriedResponse, secondHandler);
      final secondResult = await secondHandler.completer.future;

      expect(refreshCalls, 1, reason: 'refresh não deve ser chamado de novo');
      expect(secondResult.statusCode, 401);
    });
  });
}

/// Handler de teste que captura a resposta resultante (via `next` ou
/// `resolve`) sem depender da API interna/protegida do dio.
class _CapturingHandler extends ResponseInterceptorHandler {
  final completer = Completer<Response>();

  @override
  void next(Response response) {
    completer.complete(response);
  }

  @override
  void resolve(Response response) {
    completer.complete(response);
  }

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {
    completer.completeError(error);
  }
}
