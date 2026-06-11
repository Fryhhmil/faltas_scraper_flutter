import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

/// Encapsula o Dio com cookie jar persistente (cookies sobrevivem a restart).
class DioClient {
  late final Dio dio;
  late final PersistCookieJar cookieJar;

  DioClient._();

  static Future<DioClient> create() async {
    final c = DioClient._();
    final dir = await getApplicationSupportDirectory();
    c.cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
    );
    c.dio = Dio(BaseOptions(
      followRedirects: false,
      validateStatus: (s) => s != null && s < 500,
      headers: {'Accept': 'application/json'},
    ));
    c.dio.interceptors.add(CookieManager(c.cookieJar));
    return c;
  }

  Future<bool> hasSession() async {
    final cookies = await cookieJar.loadForRequest(
      Uri.parse('https://grupoeducacional127611.rm.cloudtotvs.com.br'),
    );
    return cookies.any((ck) => ck.name == '.ASPXAUTH');
  }

  Future<void> clearCookies() => cookieJar.deleteAll();
}
