import 'package:dio/dio.dart';
import '../constants/endpoints.dart';
import 'session_exception.dart';

/// Detecta sessão expirada e reexecuta a requisição após re-login.
/// `refresh` devolve true se conseguiu re-autenticar; `retry` reexecuta.
class AuthInterceptor extends Interceptor {
  final Future<bool> Function() refresh;
  final Future<Response> Function(RequestOptions) retry;

  AuthInterceptor({required this.refresh, required this.retry});

  Future<bool>? _inFlight;

  /// Single-flight: um refresh por vez, demais aguardam o mesmo resultado.
  Future<bool> runRefresh() {
    return _inFlight ??= refresh().whenComplete(() => _inFlight = null);
  }

  static bool isExpired(Response r) {
    final code = r.statusCode ?? 0;
    if (code == 401 || code == 403) return true;
    if (code == 302) {
      final loc = r.headers.value('location') ?? '';
      if (loc.contains(Endpoints.loginPageMarker)) return true;
    }
    final body = r.data;
    if (body is String && body.contains(Endpoints.loginPageMarker)) return true;
    return false;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (!isExpired(response)) return handler.next(response);
    // Não tentar recuperar a própria rota de login.
    if (response.requestOptions.path.contains('EduPortalAlunoLogin')) {
      return handler.next(response);
    }
    // Já tentamos refresh+retry uma vez para esta requisição: não repetir
    // (evita loop infinito caso a sessão continue expirada após o retry).
    if (response.requestOptions.extra['auth_retried'] == true) {
      return handler.next(response);
    }
    final ok = await runRefresh();
    if (!ok) {
      return handler.reject(DioException(
        requestOptions: response.requestOptions,
        error: const SessionExpiredException(),
      ));
    }
    try {
      response.requestOptions.extra['auth_retried'] = true;
      final retried = await retry(response.requestOptions);
      return handler.resolve(retried);
    } catch (e) {
      return handler.reject(DioException(
        requestOptions: response.requestOptions,
        error: e,
      ));
    }
  }
}
