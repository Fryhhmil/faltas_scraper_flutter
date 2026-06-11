import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'auth_interceptor.dart';
import 'cookie_store.dart';

/// Encapsula o Dio com um cookie store tolerante e persistente
/// (cookies sobrevivem a restart; valores com `\` do RM são aceitos).
class DioClient {
  late final Dio dio;
  late final CookieStore cookieStore;

  DioClient._();

  static Future<DioClient> create() async {
    final c = DioClient._();
    final dir = await getApplicationSupportDirectory();
    c.cookieStore = CookieStore(File('${dir.path}/cookies.json'));
    await c.cookieStore.load();
    c.dio = Dio(BaseOptions(
      followRedirects: false,
      validateStatus: (s) => s != null && s < 500,
      headers: {'Accept': 'application/json'},
    ));
    c.dio.interceptors.add(CookieInterceptor(c.cookieStore));
    return c;
  }

  /// Liga o AuthInterceptor. `refresh` re-autentica; o retry reusa o próprio dio.
  void attachAuth(Future<bool> Function() refresh) {
    dio.interceptors.add(AuthInterceptor(
      refresh: refresh,
      retry: (o) => dio.fetch(o),
    ));
  }

  Future<bool> hasSession() async => cookieStore.hasSession;

  Future<void> clearCookies() => cookieStore.clear();
}
