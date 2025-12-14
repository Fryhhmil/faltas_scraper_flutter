import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/login_model.dart';
import '../models/falta_model.dart';
import '../models/horario_model.dart';
import 'api_interface.dart';

class ApiService implements ApiInterface {
  static const String baseUrl = 'http://totvsscrap.ddns.net:8080'; // Substitua pela URL do seu backend

  void _applyCookies(HttpClientRequest request, Map<String, String> cookies) {
    if (cookies.isNotEmpty) {
      final cookieHeader =
          cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      request.headers.set(HttpHeaders.cookieHeader, cookieHeader);
    }
  }

  void _mergeSetCookiesRaw(
    HttpClientResponse resp,
    Map<String, String> cookieMap,
  ) {
    final setCookies = resp.headers[HttpHeaders.setCookieHeader];
    if (setCookies == null) return;

    for (final raw in setCookies) {
      final firstPart = raw.split(';').first;
      final idx = firstPart.indexOf('=');
      if (idx <= 0) continue;

      final name = firstPart.substring(0, idx).trim();
      final value = firstPart.substring(idx + 1);

      // NÃO validar, NÃO escapar
      cookieMap[name] = value;
    }
  }

  @override
  Future<String> login(LoginModel loginData) async {
    const String rmBase = 'https://grupoeducacional127611.rm.cloudtotvs.com.br';
    final cookieMap = <String, String>{};
    final client = HttpClient();

    try {
      // 1) LOGIN (302)
      final loginUri = Uri.parse(
        '$rmBase/Corpore.Net//Source/EDU-EDUCACIONAL/Public/EduPortalAlunoLogin.aspx?AutoLoginType=ExternalLogin',
      );

      final req = await client.postUrl(loginUri);
      req.followRedirects = false;
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded');

      final body =
          'User=${Uri.encodeComponent(loginData.cpf)}'
          '&Pass=${Uri.encodeComponent(loginData.senha)}'
          '&Alias=CorporeRM';

      req.write(body);

      final resp = await req.close();

      if (resp.statusCode != 302) {
        throw Exception('Login não retornou 302 (HTTP ${resp.statusCode})');
      }

      final location = resp.headers.value(HttpHeaders.locationHeader) ?? '';
      if (!location.contains('key=')) {
        throw Exception('Key não encontrada no Location');
      }

      final key = _extractKey(location);

      _mergeSetCookiesRaw(resp, cookieMap);

      // 2) AUTLOGIN PORTAL
      final autoUri =
          Uri.parse('$rmBase/FrameHTML/RM/API/user/AutoLoginPortal?key=$key');

      final req2 = await client.getUrl(autoUri);
      _applyCookies(req2, cookieMap);
      req2.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final resp2 = await req2.close();

      if (resp2.statusCode < 200 || resp2.statusCode >= 300) {
        throw Exception('Erro ao consumir key (HTTP ${resp2.statusCode})');
      }

      _mergeSetCookiesRaw(resp2, cookieMap);

      // 3) CONTEXTO
      final ctxUri =
          Uri.parse('$rmBase/FrameHTML/RM/API/TOTVSEducacional/Contexto');

      final req3 = await client.getUrl(ctxUri);
      _applyCookies(req3, cookieMap);
      req3.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final resp3 = await req3.close();

      if (resp3.statusCode < 200 || resp3.statusCode >= 300) {
        throw Exception('Erro ao buscar Contexto (HTTP ${resp3.statusCode})');
      }

      final body3 = await resp3.transform(utf8.decoder).join();
      final decoded = jsonDecode(body3);
      final data = decoded['data'] as List;
      final ctx = data.first as Map<String, dynamic>;
      // final idContextoAlunoRaw = ctx['IDCONTEXTOALUNO'].toString();

      // final selectionJson = {
      //   "CodColigada": ctx['CODCOLIGADA'],
      //   "CodFilial": ctx['CODFILIAL'],
      //   "CodTipoCurso": ctx['CODTIPOCURSO'],
      //   "IdContextoAluno": ctx['IDCONTEXTOALUNO'],
      //   "IdHabilitacaoFilial": ctx['IDHABILITACAOFILIAL'],
      //   "IdPerlet": ctx['IDPERLET'],
      //   "RA": ctx['RA'],
      //   "AcessoDadosAcademicos": true,
      //   "AcessoDadosFinanceiros": true
      // };

      final selectionJson = {
        "CodColigada": 4,
        "CodFilial": 1,
        "CodTipoCurso": 1,
        "IdContextoAluno": ctx['IDCONTEXTOALUNO'],
        "IdHabilitacaoFilial": 76,
        "IdPerlet": 37,
        "RA": "2092311",
        "AcessoDadosAcademicos": true,
        "AcessoDadosFinanceiros": true
      };

      // 4) SELEÇÃO DE CONTEXTO
      final selUri = Uri.parse(
        '$rmBase/FrameHTML/RM/API/TOTVSEducacional/Contexto/Selecao',
      );

      final req4 = await client.postUrl(selUri);
      _applyCookies(req4, cookieMap);

      req4.headers
        ..set(
          HttpHeaders.contentTypeHeader,
          'application/json;charset=UTF-8',
        )
        ..set(HttpHeaders.acceptHeader, 'application/json')
        // opcional, mas ajuda a evitar heurística estranha no RM
        ..set(
          HttpHeaders.userAgentHeader,
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        );

      // 🔥 SERIALIZA ANTES
      final bodyBytes = utf8.encode(jsonEncode(selectionJson));

      // 🔥 FORÇA CONTENT-LENGTH (impede chunked)
      req4.contentLength = bodyBytes.length;

      // 🔥 ENVIA COMO BYTES (não use write)
      req4.add(bodyBytes);

      final resp4 = await req4.close();


      if (resp4.statusCode < 200 || resp4.statusCode >= 300) {
        throw Exception('Erro ao selecionar contexto (HTTP ${resp4.statusCode})');
      }

      _mergeSetCookiesRaw(resp4, cookieMap);

      // COOKIE FINAL (para enviar ao backend)
      String cookie = cookieMap.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
        print('Cookies: ${cookie}');

      return cookie;
    } finally {
      client.close(force: true);
    }
  }

  String _extractKey(String location) {
    final idx = location.indexOf('key=');
    if (idx < 0) return '';
    return location.substring(idx + 4);
  }

  @override
  Future<List<FaltaModel>> buscarFaltas(String cookie) async {
    final response = await http.post(
      Uri.parse('$baseUrl/buscar-faltas'),
      headers: {'Content-Type': 'application/json'},
      body: cookie,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FaltaModel.fromJson(json)).toList();
    } else if (response.statusCode == 406) {
      throw Exception('Cookie inválido');
    } else {
      throw Exception('Falha ao buscar faltas: ${response.statusCode}');
    }
  }

  @override
  Future<HorarioAlunoModel> buscarHorario(String cookie) async {
    final response = await http.post(
      Uri.parse('$baseUrl/buscar-horario'),
      headers: {'Content-Type': 'application/json'},
      body: cookie,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return HorarioAlunoModel.fromJson(data);
    } else if (response.statusCode == 406) {
      throw Exception('Cookie inválido');
    } else {
      throw Exception('Falha ao buscar horário: ${response.statusCode}');
    }
  }
}
