import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/login_model.dart';
import '../models/falta_model.dart';
import '../models/horario_model.dart';
import '../models/contexto_aluno.dart';
import 'api_interface.dart';

class ApiService implements ApiInterface {
  static const String baseUrl = 'http://totvsscrap.ddns.net:8080'; // Substitua pela URL do seu backend
  static const String _rmBase = 'https://grupoeducacional127611.rm.cloudtotvs.com.br';

  final HttpClient _client = HttpClient();
  final Map<String, String> _cookieMap = {};

  void _applyCookies(HttpClientRequest request, Map<String, String> cookies) {
    if (cookies.isNotEmpty) {
      final cookieHeader = cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
      request.headers.set(HttpHeaders.cookieHeader, cookieHeader);
    }
  }

  void _mergeSetCookiesRaw(HttpClientResponse resp, Map<String, String> cookieMap) {
    final setCookies = resp.headers[HttpHeaders.setCookieHeader];
    if (setCookies == null) return;

    for (final raw in setCookies) {
      final firstPart = raw.split(';').first;
      final idx = firstPart.indexOf('=');
      if (idx <= 0) continue;

      final name = firstPart.substring(0, idx).trim();
      final value = firstPart.substring(idx + 1);

      cookieMap[name] = value;
    }
  }

  @override
  Future<String> login(LoginModel loginData) async {
    // Compatibilidade: realiza o fluxo completo e retorna cookie
    await autenticar(loginData);
    final contexts = await buscarContextos();
    if (contexts.isEmpty) throw Exception('Nenhum contexto disponível');
    final cookie = await selecionarContexto(contexts.first);
    return cookie;
  }

  @override
  Future<void> autenticar(LoginModel loginData) async {
    _cookieMap.clear();

    final loginUri = Uri.parse('$_rmBase/Corpore.Net//Source/EDU-EDUCACIONAL/Public/EduPortalAlunoLogin.aspx?AutoLoginType=ExternalLogin');
    final req = await _client.postUrl(loginUri);
    req.followRedirects = false;
    req.headers.set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded');

    final body = 'User=${Uri.encodeComponent(loginData.cpf)}&Pass=${Uri.encodeComponent(loginData.senha)}&Alias=CorporeRM';
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
    _mergeSetCookiesRaw(resp, _cookieMap);

    final autoUri = Uri.parse('$_rmBase/FrameHTML/RM/API/user/AutoLoginPortal?key=$key');
    final req2 = await _client.getUrl(autoUri);
    _applyCookies(req2, _cookieMap);
    req2.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final resp2 = await req2.close();
    if (resp2.statusCode < 200 || resp2.statusCode >= 300) {
      throw Exception('Erro ao consumir key (HTTP ${resp2.statusCode})');
    }
    _mergeSetCookiesRaw(resp2, _cookieMap);
  }

  @override
  Future<List<ContextoAluno>> buscarContextos() async {
    print('[ApiService] buscarContextos()');
    print('[ApiService] cookieMap before request: $_cookieMap');
    final ctxUri = Uri.parse('$_rmBase/FrameHTML/RM/API/TOTVSEducacional/Contexto');
    final req3 = await _client.getUrl(ctxUri);
    // ensure Cookie header is explicitly set from current cookie map
    final cookieHeader = _cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
    if (cookieHeader.isNotEmpty) {
      req3.headers.set(HttpHeaders.cookieHeader, cookieHeader);
      print('[ApiService] sending Cookie: $cookieHeader');
    } else {
      print('[ApiService] no cookies to send');
    }
    req3.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final resp3 = await req3.close();
    if (resp3.statusCode < 200 || resp3.statusCode >= 300) {
      throw Exception('Erro ao buscar Contexto (HTTP ${resp3.statusCode})');
    }

    _mergeSetCookiesRaw(resp3, _cookieMap);

    final body3 = await resp3.transform(utf8.decoder).join();
    print('[ApiService] buscarContextos() response length=${body3.length}');
    final decoded = jsonDecode(body3);
    final data = decoded['data'] as List<dynamic>;
    print('[ApiService] buscarContextos() parsed ${data.length} contexts');
    return data.map((e) => ContextoAluno.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> selecionarContexto(ContextoAluno ctx) async {
    final selectionJson = {
      "CodColigada": ctx.codColigada,
      "CodFilial": ctx.codFilial,
      "CodTipoCurso": ctx.codTipoCurso,
      "IdContextoAluno": ctx.idContextoAluno,
      "IdHabilitacaoFilial": ctx.idHabilitacaoFilial,
      "IdPerlet": ctx.idPerlet,
      "RA": ctx.ra,
      "AcessoDadosAcademicos": true,
      "AcessoDadosFinanceiros": true
    };

    final selUri = Uri.parse('$_rmBase/FrameHTML/RM/API/TOTVSEducacional/Contexto/Selecao');
    final req4 = await _client.postUrl(selUri);
    _applyCookies(req4, _cookieMap);

    req4.headers
      ..set(HttpHeaders.contentTypeHeader, 'application/json;charset=UTF-8')
      ..set(HttpHeaders.acceptHeader, 'application/json')
      ..set(HttpHeaders.userAgentHeader, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');

    final bodyBytes = utf8.encode(jsonEncode(selectionJson));
    req4.contentLength = bodyBytes.length;
    req4.add(bodyBytes);

    final resp4 = await req4.close();
    if (resp4.statusCode < 200 || resp4.statusCode >= 300) {
      throw Exception('Erro ao selecionar contexto (HTTP ${resp4.statusCode})');
    }
    _mergeSetCookiesRaw(resp4, _cookieMap);

    final cookie = _cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
    return cookie;
  }

  String _extractKey(String location) {
    final idx = location.indexOf('key=');
    if (idx < 0) return '';
    return location.substring(idx + 4);
  }

  @override
  Future<List<FaltaModel>> buscarFaltas(String cookie) async {
    // Chama a API RM diretamente para obter faltas por etapa
    final uri = Uri.parse('$_rmBase/FrameHTML/RM/API/TOTVSEducacional/FaltaEtapa');
    final req = await _client.getUrl(uri);

    // aplicar cookies a partir do cookie map se disponível
    final cookieHeader = _cookieMap.entries.map((e) => '${e.key}=${e.value}').join('; ');
    if (cookieHeader.isNotEmpty) {
      req.headers.set(HttpHeaders.cookieHeader, cookieHeader);
    }
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final resp = await req.close();
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      if (resp.statusCode == 401 || resp.statusCode == 406) {
        throw Exception('Cookie inválido (HTTP ${resp.statusCode})');
      }
      throw Exception('Falha ao buscar faltas (HTTP ${resp.statusCode})');
    }

    final body = await resp.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);

    // Estrutura esperada: { "data": { "FaltasEtapa": [ ... ] } }
    final faltasList = <dynamic>[];
    try {
      final data = decoded['data'];
      if (data is Map<String, dynamic> && data['FaltasEtapa'] is List) {
        faltasList.addAll(data['FaltasEtapa'] as List);
      } else if (decoded['FaltasEtapa'] is List) {
        faltasList.addAll(decoded['FaltasEtapa'] as List);
      }
    } catch (_) {}

    List<FaltaModel> result = [];
    for (final item in faltasList) {
      if (item is Map<String, dynamic>) {
        // nome da matéria
        final nome = (item['Disciplina'] ?? item['Disciplina '])?.toString() ?? 'Matéria não identificada';

        // tentativas de extrair total de faltas a partir de chaves conhecidas
        int parseIntField(dynamic v) {
          if (v == null) return 0;
          if (v is int) return v;
          final s = v.toString();
          final digits = RegExp(r'-?\d+').stringMatch(s);
          return digits != null ? int.tryParse(digits) ?? 0 : 0;
        }

        final faltas = parseIntField(item['3 - TOTAL FALTAS'] ?? item['TOTAL FALTAS'] ?? item['FALTAS'] ?? item['3']);
        final percentual = (item['PERCENTUAL'] is num) ? (item['PERCENTUAL'] as num).toDouble() : (double.tryParse(item['PERCENTUAL']?.toString() ?? '') ?? 0.0);

        result.add(FaltaModel(
          nomeMateria: nome,
          faltas: faltas,
          podeFaltar: 0,
          percentual: percentual,
        ));
      }
    }

    return result;
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

  int calcularLimiteDeFaltas({
    int? faltas,
    double? porcentagem,
  }) {
    if (faltas == null || porcentagem == null) return 0;
    if (faltas == 0 || porcentagem == 0) return 0;
    faltas = (faltas! / 2).truncate();

    // Regra de 3
    final double resultado = (faltas * 25) / porcentagem;

    final int parteInteira = resultado.floor();
    final double parteDecimal = resultado - parteInteira;

    // Só arredonda para cima se decimal > 0.7
    if (parteDecimal > 0.7) {
      return parteInteira + 1;
    }

    return parteInteira;
  }


}
