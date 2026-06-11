import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';

/// Armazena cookies de forma tolerante e os persiste em disco.
///
/// O Portal RM devolve cookies cujos valores contêm `\` (barra invertida) e
/// outros caracteres que o `cookie_jar`/`dart:io` rejeitam com FormatException.
/// Aqui fazemos o parsing "na unha" (igual ao código legado que funcionava):
/// pegamos `nome=valor` cru, sem validar o conteúdo do valor.
class CookieStore {
  final File _file;
  final Map<String, String> _cookies = {};

  CookieStore(this._file);

  /// Carrega os cookies persistidos (sobrevive a reinício do app).
  Future<void> load() async {
    try {
      if (await _file.exists()) {
        final map = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
        _cookies.addAll(map.map((k, v) => MapEntry(k, v.toString())));
      }
    } catch (_) {
      // arquivo corrompido/ausente: começa vazio
    }
  }

  Future<void> _persist() async {
    try {
      await _file.create(recursive: true);
      await _file.writeAsString(jsonEncode(_cookies));
    } catch (_) {}
  }

  /// Mescla os `Set-Cookie` de uma resposta, de forma tolerante.
  void mergeSetCookies(List<String>? setCookies) {
    if (setCookies == null || setCookies.isEmpty) return;
    for (final raw in setCookies) {
      final first = raw.split(';').first;
      final idx = first.indexOf('=');
      if (idx <= 0) continue;
      final name = first.substring(0, idx).trim();
      final value = first.substring(idx + 1);
      if (name.isEmpty) continue;
      _cookies[name] = value;
    }
    _persist();
  }

  /// Header `Cookie` a enviar nas requisições.
  String header() =>
      _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  bool get hasSession => _cookies.containsKey('.ASPXAUTH');

  Future<void> clear() async {
    _cookies.clear();
    await _persist();
  }
}

/// Interceptor que injeta o header Cookie nas requisições e captura os
/// Set-Cookie das respostas, usando o [CookieStore] tolerante.
class CookieInterceptor extends Interceptor {
  final CookieStore store;
  CookieInterceptor(this.store);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final h = store.header();
    if (h.isNotEmpty) options.headers['cookie'] = h;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    store.mergeSetCookies(response.headers.map['set-cookie']);
    handler.next(response);
  }
}
