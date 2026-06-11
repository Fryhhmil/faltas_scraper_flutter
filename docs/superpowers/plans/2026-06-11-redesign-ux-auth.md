# Redesign UX + Re-arquitetura de Autenticação — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reconstruir o app Faltas iCEV com tema dark premium, navegação por abas e — prioridade #1 — autenticação confiável com reautenticação automática (fim do logout involuntário).

**Architecture:** Camada pragmática `core / data / presentation`. Rede via `dio` + `cookie_jar` persistente; `AuthInterceptor` detecta sessão expirada (401/403/redirect a Login.aspx/HTML) e re-loga com single-flight, reexecutando a requisição. Repositories isolam datasources; Providers (ChangeNotifier) orquestram a UI. Credenciais/cookies em `flutter_secure_storage`.

**Tech Stack:** Flutter 3.38, Dart 3.10, dio, dio_cookie_manager, cookie_jar, flutter_secure_storage, fl_chart, shimmer, provider, go_router, intl.

---

## Mapa de arquivos (responsabilidades)

```
lib/
├─ core/
│  ├─ constants/endpoints.dart         # URLs base + paths RM
│  ├─ constants/storage_keys.dart      # chaves secure storage
│  ├─ theme/app_colors.dart            # paleta fixa
│  ├─ theme/app_theme.dart             # ThemeData dark M3
│  ├─ network/dio_client.dart          # monta Dio + cookie jar + interceptors
│  ├─ network/auth_interceptor.dart    # detecção de expiração + re-login + retry
│  ├─ network/session_exception.dart   # erros tipados
│  └─ utils/nota_parser.dart           # <font>, vírgula→double, faixa de cor
├─ data/
│  ├─ models/credenciais.dart
│  ├─ models/contexto_aluno.dart       # (migrado do atual)
│  ├─ models/periodo_letivo.dart
│  ├─ models/nota_disciplina.dart
│  ├─ models/falta_disciplina.dart
│  ├─ models/disciplina.dart
│  ├─ models/aula_horario.dart
│  ├─ datasources/secure_storage_ds.dart
│  ├─ datasources/rm_api_ds.dart       # chamadas dio cruas (json)
│  ├─ repositories/auth_repository.dart
│  └─ repositories/academic_repository.dart
├─ presentation/
│  ├─ providers/auth_provider.dart
│  ├─ providers/academic_provider.dart
│  ├─ screens/login_screen.dart
│  ├─ screens/shell_screen.dart        # NavigationBar (4 abas)
│  ├─ screens/dashboard_screen.dart
│  ├─ screens/notas_screen.dart
│  ├─ screens/faltas_screen.dart
│  ├─ screens/horario_screen.dart
│  ├─ screens/settings_screen.dart
│  └─ widgets/ (stat_card, ring_gauge, nota_card, falta_card, aula_tile,
│               status_chip, skeleton, empty_state, period_sheet)
├─ app.dart                            # MaterialApp.router + providers
└─ main.dart
```

**Estratégia de migração:** construir o novo em `core/`, `data/`, `presentation/` e trocar o `main.dart` no final (Fase 6). Os arquivos antigos (`lib/services`, `lib/providers`, `lib/screens`, `lib/models`) permanecem até a Fase 6 para não quebrar o build, e são removidos no fim.

---

## FASE 0 — Setup

### Task 0.1: Adicionar dependências

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Adicionar deps**

No bloco `dependencies:` do `pubspec.yaml`, adicionar:

```yaml
  dio: ^5.7.0
  cookie_jar: ^4.0.8
  dio_cookie_manager: ^3.1.1
  flutter_secure_storage: ^9.2.2
  path_provider: ^2.1.4
  fl_chart: ^0.69.0
  shimmer: ^3.0.0
```

- [ ] **Step 2: Instalar**

Run: `flutter pub get`
Expected: `Got dependencies!` sem erro de resolução.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: adiciona dio, cookie_jar, secure_storage, fl_chart, shimmer"
```

### Task 0.2: Paleta e constantes

**Files:**
- Create: `lib/core/theme/app_colors.dart`
- Create: `lib/core/constants/endpoints.dart`
- Create: `lib/core/constants/storage_keys.dart`

- [ ] **Step 1: app_colors.dart**

```dart
import 'package:flutter/material.dart';

/// Paleta fixa (dark) do app.
class AppColors {
  static const bg = Color(0xFF0D1117);
  static const card = Color(0xFF161B22);
  static const card2 = Color(0xFF1C2128);
  static const border = Color(0xFF21262D);
  static const accent = Color(0xFF58A6FF);
  static const success = Color(0xFF3FB950);
  static const warning = Color(0xFFD29922);
  static const error = Color(0xFFF85149);
  static const text = Color(0xFFF0F6FC);
  static const text2 = Color(0xFF8B949E);
}
```

- [ ] **Step 2: endpoints.dart**

```dart
/// URLs e paths do Portal RM.
class Endpoints {
  static const rmBase = 'https://grupoeducacional127611.rm.cloudtotvs.com.br';

  static const login =
      '$rmBase/Corpore.Net//Source/EDU-EDUCACIONAL/Public/EduPortalAlunoLogin.aspx?AutoLoginType=ExternalLogin';
  static const autoLogin = '$rmBase/FrameHTML/RM/API/user/AutoLoginPortal'; // ?key=
  static const contexto = '$rmBase/FrameHTML/RM/API/TOTVSEducacional/Contexto';
  static const contextoSelecao =
      '$rmBase/FrameHTML/RM/API/TOTVSEducacional/Contexto/Selecao';
  static const notaEtapa = '$rmBase/FrameHTML/RM/API/TOTVSEducacional/NotaEtapa';
  static const faltaEtapa = '$rmBase/FrameHTML/RM/API/TOTVSEducacional/FaltaEtapa';
  static const disciplinas =
      '$rmBase/FrameHTML/RM/API/TOTVSEducacional/DisciplinasAlunoPeriodoLetivo?mostraApenasDiscEmCurso=false';
  static const quadroHorario =
      '$rmBase/FrameHTML/RM/API/TOTVSEducacional/QuadroHorarioAluno';

  /// Marca de página de login (sessão expirada devolve HTML de login).
  static const loginPageMarker = 'EduPortalAlunoLogin.aspx';
}
```

- [ ] **Step 3: storage_keys.dart**

```dart
class StorageKeys {
  static const cpf = 'cred_cpf';
  static const senha = 'cred_senha';
  static const contexto = 'selected_context';
  static const cacheNotasPrefix = 'cache_notas_'; // + idPerlet
  static const cacheFaltasPrefix = 'cache_faltas_';
  static const cacheHorarioPrefix = 'cache_horario_';
}
```

- [ ] **Step 4: Verificar build**

Run: `flutter analyze lib/core`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_colors.dart lib/core/constants
git commit -m "feat(core): paleta e constantes de endpoints/storage"
```

---

## FASE 1 — Fundação de autenticação (prioridade #1)

### Task 1.1: nota_parser (TDD) — base usada já aqui para valores

**Files:**
- Create: `lib/core/utils/nota_parser.dart`
- Test: `test/core/nota_parser_test.dart`

- [ ] **Step 1: Teste que falha**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:faltas_scraper_flutter/core/utils/nota_parser.dart';

void main() {
  group('NotaParser.parseValor', () {
    test('vírgula decimal vira double', () {
      expect(NotaParser.parseValor('8,50'), 8.5);
    });
    test('remove <font color=red> e interpreta', () {
      expect(NotaParser.parseValor('<font color=red>4,00</font>'), 4.0);
    });
    test('null retorna null', () {
      expect(NotaParser.parseValor(null), isNull);
    });
    test('string vazia retorna null', () {
      expect(NotaParser.parseValor(''), isNull);
    });
    test('texto sem número retorna null', () {
      expect(NotaParser.parseValor('—'), isNull);
    });
  });

  group('NotaParser.textoLimpo', () {
    test('remove tags HTML mantendo texto', () {
      expect(NotaParser.textoLimpo('<font color=red>4,00</font>'), '4,00');
    });
  });

  group('NotaParser.faixaCor', () {
    test('>=7 é success', () {
      expect(NotaParser.faixaCor(7.0), Faixa.boa);
      expect(NotaParser.faixaCor(9.5), Faixa.boa);
    });
    test('5 a 6.9 é atencao', () {
      expect(NotaParser.faixaCor(6.9), Faixa.atencao);
      expect(NotaParser.faixaCor(5.0), Faixa.atencao);
    });
    test('<5 é risco', () {
      expect(NotaParser.faixaCor(4.99), Faixa.risco);
    });
    test('null é neutra', () {
      expect(NotaParser.faixaCor(null), Faixa.neutra);
    });
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/core/nota_parser_test.dart`
Expected: FAIL (target not found / NotaParser indefinido).

- [ ] **Step 3: Implementar**

```dart
enum Faixa { boa, atencao, risco, neutra }

/// Interpreta valores de nota vindos da API RM (strings com vírgula,
/// possivelmente embrulhadas em HTML como `<font color=red>4,00</font>`).
class NotaParser {
  static final _tag = RegExp(r'<[^>]*>');

  static String textoLimpo(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll(_tag, '').trim();
  }

  static double? parseValor(String? raw) {
    final limpo = textoLimpo(raw);
    if (limpo.isEmpty) return null;
    final normalizado = limpo.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalizado);
  }

  static Faixa faixaCor(double? valor) {
    if (valor == null) return Faixa.neutra;
    if (valor >= 7) return Faixa.boa;
    if (valor >= 5) return Faixa.atencao;
    return Faixa.risco;
  }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `flutter test test/core/nota_parser_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/nota_parser.dart test/core/nota_parser_test.dart
git commit -m "feat(core): NotaParser com TDD (font HTML, vírgula, faixa de cor)"
```

### Task 1.2: Modelo Credenciais + SessionException

**Files:**
- Create: `lib/data/models/credenciais.dart`
- Create: `lib/core/network/session_exception.dart`

- [ ] **Step 1: credenciais.dart**

```dart
class Credenciais {
  final String cpf;
  final String senha;
  const Credenciais({required this.cpf, required this.senha});
}
```

- [ ] **Step 2: session_exception.dart**

```dart
/// Lançada quando a sessão está inválida e não foi possível recuperar.
class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([this.message = 'Sessão expirada']);
  @override
  String toString() => 'SessionExpiredException: $message';
}

/// Erro genérico de rede/API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/models/credenciais.dart lib/core/network/session_exception.dart
git commit -m "feat(data): modelo Credenciais e exceções de sessão/API"
```

### Task 1.3: SecureStorageDataSource

**Files:**
- Create: `lib/data/datasources/secure_storage_ds.dart`
- Test: `test/data/secure_storage_ds_test.dart`

- [ ] **Step 1: Teste com mock em memória**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:faltas_scraper_flutter/data/datasources/secure_storage_ds.dart';
import 'package:faltas_scraper_flutter/data/models/credenciais.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SecureStorageDataSource ds;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ds = SecureStorageDataSource();
  });

  test('salva e lê credenciais', () async {
    await ds.saveCredenciais(const Credenciais(cpf: '123', senha: 'abc'));
    final c = await ds.getCredenciais();
    expect(c!.cpf, '123');
    expect(c.senha, 'abc');
  });

  test('sem credenciais retorna null', () async {
    expect(await ds.getCredenciais(), isNull);
  });

  test('clear remove credenciais', () async {
    await ds.saveCredenciais(const Credenciais(cpf: '1', senha: '2'));
    await ds.clearCredenciais();
    expect(await ds.getCredenciais(), isNull);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/data/secure_storage_ds_test.dart`
Expected: FAIL (SecureStorageDataSource indefinido).

- [ ] **Step 3: Implementar**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/credenciais.dart';
import '../../core/constants/storage_keys.dart';

class SecureStorageDataSource {
  final FlutterSecureStorage _s;
  SecureStorageDataSource([FlutterSecureStorage? storage])
      : _s = storage ?? const FlutterSecureStorage();

  Future<void> saveCredenciais(Credenciais c) async {
    await _s.write(key: StorageKeys.cpf, value: c.cpf);
    await _s.write(key: StorageKeys.senha, value: c.senha);
  }

  Future<Credenciais?> getCredenciais() async {
    final cpf = await _s.read(key: StorageKeys.cpf);
    final senha = await _s.read(key: StorageKeys.senha);
    if (cpf == null || senha == null) return null;
    return Credenciais(cpf: cpf, senha: senha);
  }

  Future<void> clearCredenciais() async {
    await _s.delete(key: StorageKeys.cpf);
    await _s.delete(key: StorageKeys.senha);
  }
}
```

- [ ] **Step 4: Rodar e ver passar**

Run: `flutter test test/data/secure_storage_ds_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/data/datasources/secure_storage_ds.dart test/data/secure_storage_ds_test.dart
git commit -m "feat(data): SecureStorageDataSource para credenciais (TDD)"
```

### Task 1.4: DioClient + cookie jar persistente

**Files:**
- Create: `lib/core/network/dio_client.dart`

- [ ] **Step 1: Implementar**

`AuthInterceptor` é injetado depois (Task 1.6) para evitar dependência circular; `dio` é exposto para os datasources.

```dart
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
```

- [ ] **Step 2: Analisar**

Run: `flutter analyze lib/core/network/dio_client.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/core/network/dio_client.dart
git commit -m "feat(core): DioClient com PersistCookieJar"
```

### Task 1.5: AuthRepository (login/logout/refresh/restore)

**Files:**
- Create: `lib/data/models/contexto_aluno.dart` (migra o atual, adiciona `nomePeriodo`/`idPerlet` já existentes)
- Create: `lib/data/repositories/auth_repository.dart`

- [ ] **Step 1: contexto_aluno.dart**

Copiar o conteúdo de `lib/models/contexto_aluno.dart` (já existente e correto) para `lib/data/models/contexto_aluno.dart` sem alterações de lógica. (Mesma classe `ContextoAluno` com `fromJson`/`toJson`.)

- [ ] **Step 2: auth_repository.dart**

```dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/endpoints.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/session_exception.dart';
import '../datasources/secure_storage_ds.dart';
import '../models/credenciais.dart';
import '../models/contexto_aluno.dart';

class AuthRepository {
  final DioClient _client;
  final SecureStorageDataSource _storage;
  AuthRepository(this._client, this._storage);

  Dio get _dio => _client.dio;

  /// Fluxo completo: login → key → AutoLoginPortal → Contexto/Selecao.
  /// Persiste credenciais e cookies (via cookie jar).
  Future<void> login(Credenciais cred) async {
    await _autenticar(cred);
    final contextos = await buscarContextos();
    if (contextos.isEmpty) {
      throw const ApiException('Nenhum contexto acadêmico disponível');
    }
    await selecionarContexto(contextos.first);
    await _storage.saveCredenciais(cred);
  }

  /// Persiste o contexto selecionado (para o chip de período e cache).
  Future<void> _saveContexto(ContextoAluno ctx) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(StorageKeys.contexto, jsonEncode(ctx.toJson()));
  }

  Future<ContextoAluno?> getSelectedContexto() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(StorageKeys.contexto);
    if (s == null) return null;
    try {
      return ContextoAluno.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _autenticar(Credenciais cred) async {
    final resp = await _dio.post(
      Endpoints.login,
      data: 'User=${Uri.encodeComponent(cred.cpf)}'
          '&Pass=${Uri.encodeComponent(cred.senha)}&Alias=CorporeRM',
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
        followRedirects: false,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (resp.statusCode != 302) {
      throw const ApiException('Credenciais inválidas', statusCode: 401);
    }
    final location = resp.headers.value('location') ?? '';
    final keyIdx = location.indexOf('key=');
    if (keyIdx < 0) throw const ApiException('Key de login não encontrada');
    final key = location.substring(keyIdx + 4);
    await _dio.get('${Endpoints.autoLogin}?key=$key');
  }

  Future<List<ContextoAluno>> buscarContextos() async {
    final resp = await _dio.get(Endpoints.contexto);
    final data = (resp.data is Map) ? resp.data['data'] as List? : null;
    if (data == null) return [];
    return data
        .map((e) => ContextoAluno.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> selecionarContexto(ContextoAluno ctx) async {
    await _dio.post(
      Endpoints.contextoSelecao,
      data: {
        'CodColigada': ctx.codColigada,
        'CodFilial': ctx.codFilial,
        'CodTipoCurso': ctx.codTipoCurso,
        'IdContextoAluno': ctx.idContextoAluno,
        'IdHabilitacaoFilial': ctx.idHabilitacaoFilial,
        'IdPerlet': ctx.idPerlet,
        'RA': ctx.ra,
        'AcessoDadosAcademicos': true,
        'AcessoDadosFinanceiros': true,
      },
      options: Options(contentType: 'application/json;charset=UTF-8'),
    );
    await _saveContexto(ctx);
  }

  /// Re-loga usando credenciais salvas. Usado pelo interceptor.
  /// Reaproveita o contexto salvo (mantém o período do usuário).
  Future<bool> refreshSession() async {
    final cred = await _storage.getCredenciais();
    if (cred == null) return false;
    try {
      await _autenticar(cred);
      final salvo = await getSelectedContexto();
      if (salvo != null) {
        await selecionarContexto(salvo);
      } else {
        final ctx = await buscarContextos();
        if (ctx.isNotEmpty) await selecionarContexto(ctx.first);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasStoredSession() async {
    if (await _client.hasSession()) return true;
    return (await _storage.getCredenciais()) != null;
  }

  Future<void> logout() async {
    await _client.clearCookies();
    await _storage.clearCredenciais();
  }
}
```

- [ ] **Step 3: Analisar**

Run: `flutter analyze lib/data/repositories/auth_repository.dart lib/data/models/contexto_aluno.dart`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/data/repositories/auth_repository.dart lib/data/models/contexto_aluno.dart
git commit -m "feat(data): AuthRepository (login/refresh/logout) sobre dio+cookie jar"
```

### Task 1.6: AuthInterceptor (detecção + single-flight + retry) — TDD

**Files:**
- Create: `lib/core/network/auth_interceptor.dart`
- Test: `test/core/auth_interceptor_test.dart`

- [ ] **Step 1: Teste da lógica de detecção e retry**

O interceptor recebe um callback `refresh` e um `retry`. Testamos: (a) resposta JSON normal passa; (b) 401 dispara refresh + retry; (c) HTML de login dispara refresh; (d) refresh concorrente roda uma vez só (single-flight).

```dart
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
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/core/auth_interceptor_test.dart`
Expected: FAIL (AuthInterceptor indefinido).

- [ ] **Step 3: Implementar**

```dart
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
    final ok = await runRefresh();
    if (!ok) {
      return handler.reject(DioException(
        requestOptions: response.requestOptions,
        error: const SessionExpiredException(),
      ));
    }
    try {
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
```

- [ ] **Step 4: Rodar e ver passar**

Run: `flutter test test/core/auth_interceptor_test.dart`
Expected: All tests passed.

- [ ] **Step 5: Commit**

```bash
git add lib/core/network/auth_interceptor.dart test/core/auth_interceptor_test.dart
git commit -m "feat(core): AuthInterceptor com detecção de expiração + single-flight retry (TDD)"
```

### Task 1.7: Ligar interceptor ao DioClient

**Files:**
- Modify: `lib/core/network/dio_client.dart`

- [ ] **Step 1: Adicionar método attachAuth**

Adicionar ao `DioClient` (após o construtor `create`):

```dart
  /// Liga o AuthInterceptor. `refresh` re-autentica; o retry reusa o próprio dio.
  void attachAuth(Future<bool> Function() refresh) {
    dio.interceptors.add(AuthInterceptor(
      refresh: refresh,
      retry: (o) => dio.fetch(o),
    ));
  }
```

E o import no topo:

```dart
import 'auth_interceptor.dart';
```

- [ ] **Step 2: Analisar**

Run: `flutter analyze lib/core/network`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/core/network/dio_client.dart
git commit -m "feat(core): DioClient.attachAuth liga o interceptor de sessão"
```

---

## FASE 2 — Camada de dados (modelos + parsers + repositório acadêmico)

### Task 2.1: Modelos acadêmicos (TDD de fromJson)

**Files:**
- Create: `lib/data/models/nota_disciplina.dart`
- Create: `lib/data/models/falta_disciplina.dart`
- Create: `lib/data/models/disciplina.dart`
- Create: `lib/data/models/aula_horario.dart`
- Create: `lib/data/models/periodo_letivo.dart`
- Test: `test/data/models_test.dart`

- [ ] **Step 1: Teste com JSONs reais do PDF**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:faltas_scraper_flutter/data/models/nota_disciplina.dart';
import 'package:faltas_scraper_flutter/data/models/aula_horario.dart';
import 'package:faltas_scraper_flutter/data/models/falta_disciplina.dart';
import 'package:faltas_scraper_flutter/core/utils/nota_parser.dart';

void main() {
  test('NotaDisciplina parse Inglês VII', () {
    final n = NotaDisciplina.fromJson({
      'DISCIPLINA': 'Inglês VII',
      'SITUACAO': 'Aprovado por Média',
      'IDTURMADISC': 7108,
      '1 - P1': '8,50',
      '2 - P2': '10,00',
      '3 - P3': '10,00',
      '6 - MÉDIA FINAL': '9,50',
    });
    expect(n.disciplina, 'Inglês VII');
    expect(n.p1, 8.5);
    expect(n.mediaFinal, 9.5);
    expect(n.faixaMedia, Faixa.boa);
  });

  test('NotaDisciplina sem notas (todas null)', () {
    final n = NotaDisciplina.fromJson({
      'DISCIPLINA': 'Estágio',
      'SITUACAO': 'Período em Curso',
      '1 - P1': null,
      '6 - MÉDIA FINAL': null,
    });
    expect(n.p1, isNull);
    expect(n.semNotas, isTrue);
  });

  test('NotaDisciplina parseia font color', () {
    final n = NotaDisciplina.fromJson({
      'DISCIPLINA': 'Mobile',
      'SITUACAO': 'Período em Curso',
      '2 - P2': '<font color=red>4,00</font>',
    });
    expect(n.p2, 4.0);
  });

  test('AulaHorario parse com mapeamento de dia', () {
    final a = AulaHorario.fromJson({
      'DIASEMANA': '2',
      'HORAINICIAL': '18:30',
      'HORAFINAL': '19:20',
      'NOME': 'Estágio',
      'SALA': null,
    });
    expect(a.diaSemana, 2); // 1=Dom..7=Sáb → 2 = Segunda
    expect(a.nomeDia, 'Segunda');
    expect(a.horaInicial, '18:30');
    expect(a.local, isNull);
  });

  test('FaltaDisciplina calcula percentual sobre limite 25%', () {
    // 8 faltas de carga 32h → max permitido = 25% de 32 = 8 → 100%
    final f = FaltaDisciplina(
      disciplina: 'Redes',
      faltas: 8,
      cargaHoraria: 32,
    );
    expect(f.maxFaltas, 8);
    expect(f.percentualLimite, 100);
    expect(f.nivel, NivelFalta.critico);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/data/models_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar nota_disciplina.dart**

```dart
import '../../core/utils/nota_parser.dart';

class NotaDisciplina {
  final String disciplina;
  final String situacao;
  final int idTurmaDisc;
  final double? p1, p2, p3, mediaSemestre, recFinal, mediaFinal;

  NotaDisciplina({
    required this.disciplina,
    required this.situacao,
    required this.idTurmaDisc,
    this.p1, this.p2, this.p3,
    this.mediaSemestre, this.recFinal, this.mediaFinal,
  });

  factory NotaDisciplina.fromJson(Map<String, dynamic> j) {
    String? s(dynamic v) => v?.toString();
    return NotaDisciplina(
      disciplina: (j['DISCIPLINA'] ?? '').toString().trim(),
      situacao: (j['SITUACAO'] ?? '').toString().trim(),
      idTurmaDisc: (j['IDTURMADISC'] is int)
          ? j['IDTURMADISC'] as int
          : int.tryParse('${j['IDTURMADISC']}') ?? 0,
      p1: NotaParser.parseValor(s(j['1 - P1'])),
      p2: NotaParser.parseValor(s(j['2 - P2'])),
      p3: NotaParser.parseValor(s(j['3 - P3'])),
      mediaSemestre: NotaParser.parseValor(s(j['4 - MÉDIA SEMESTRE'])),
      recFinal: NotaParser.parseValor(s(j['5 - REC FINAL'])),
      mediaFinal: NotaParser.parseValor(s(j['6 - MÉDIA FINAL'])),
    );
  }

  double? get mediaExibida => mediaFinal ?? mediaSemestre;
  Faixa get faixaMedia => NotaParser.faixaCor(mediaExibida);
  bool get semNotas =>
      [p1, p2, p3, mediaSemestre, mediaFinal].every((e) => e == null);

  Map<String, dynamic> toJson() => {
        'DISCIPLINA': disciplina, 'SITUACAO': situacao,
        'IDTURMADISC': idTurmaDisc,
        '1 - P1': p1, '2 - P2': p2, '3 - P3': p3,
        '4 - MÉDIA SEMESTRE': mediaSemestre,
        '5 - REC FINAL': recFinal, '6 - MÉDIA FINAL': mediaFinal,
      };
}
```

- [ ] **Step 4: Implementar aula_horario.dart**

```dart
class AulaHorario {
  final int diaSemana; // 1=Dom ... 7=Sáb (convenção RM)
  final String horaInicial;
  final String horaFinal;
  final String nome;
  final String? local;

  AulaHorario({
    required this.diaSemana,
    required this.horaInicial,
    required this.horaFinal,
    required this.nome,
    this.local,
  });

  static const _dias = [
    '', 'Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado',
  ];

  factory AulaHorario.fromJson(Map<String, dynamic> j) {
    final partes = [j['SALA'], j['BLOCO'], j['PREDIO']]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString())
        .toList();
    return AulaHorario(
      diaSemana: int.tryParse('${j['DIASEMANA']}') ?? 0,
      horaInicial: (j['HORAINICIAL'] ?? '').toString(),
      horaFinal: (j['HORAFINAL'] ?? '').toString(),
      nome: (j['NOME'] ?? '').toString().trim(),
      local: partes.isEmpty ? null : partes.join(' · '),
    );
  }

  String get nomeDia =>
      (diaSemana >= 1 && diaSemana <= 7) ? _dias[diaSemana] : '—';

  Map<String, dynamic> toJson() => {
        'DIASEMANA': diaSemana, 'HORAINICIAL': horaInicial,
        'HORAFINAL': horaFinal, 'NOME': nome, 'SALA': local,
      };
}
```

- [ ] **Step 5: Implementar falta_disciplina.dart**

`cargaHoraria` pode não vir direta da API; quando ausente, derivamos `maxFaltas` do par (faltas, percentual) usando regra de 3 (igual ao app atual), com fallback. O modelo aceita ambas as origens.

```dart
enum NivelFalta { tranquilo, atencao, critico }

class FaltaDisciplina {
  final String disciplina;
  final int faltas;          // faltas em horas/aulas
  final int cargaHoraria;    // 0 se desconhecida
  final double? percentualApi; // PERCENTUAL vindo da API, se houver

  FaltaDisciplina({
    required this.disciplina,
    required this.faltas,
    this.cargaHoraria = 0,
    this.percentualApi,
  });

  /// Máximo de faltas permitido = 25% da carga.
  int get maxFaltas {
    if (cargaHoraria > 0) return (cargaHoraria * 0.25).floor();
    // Deriva via regra de 3 a partir do percentual informado pela API.
    if (percentualApi != null && percentualApi! > 0 && faltas > 0) {
      final carga = (faltas / (percentualApi! / 100));
      return (carga * 0.25).floor();
    }
    return 0;
  }

  /// % do limite legal (25%) já consumido. 100% = atingiu o limite.
  double get percentualLimite {
    final max = maxFaltas;
    if (max <= 0) return 0;
    return (faltas / max * 100).clamp(0, 999).toDouble();
  }

  int get faltasRestantes => (maxFaltas - faltas).clamp(0, 9999);

  NivelFalta get nivel {
    final p = percentualLimite;
    if (p >= 100) return NivelFalta.critico;
    if (p >= 70) return NivelFalta.atencao;
    return NivelFalta.tranquilo;
  }

  factory FaltaDisciplina.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v is int) return v;
      final m = RegExp(r'-?\d+').stringMatch('${v ?? ''}');
      return m != null ? int.tryParse(m) ?? 0 : 0;
    }
    double? asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.'));
    return FaltaDisciplina(
      disciplina: (j['Disciplina'] ?? j['DISCIPLINA'] ?? 'Disciplina')
          .toString().trim(),
      faltas: asInt(j['3 - TOTAL FALTAS'] ?? j['TOTAL FALTAS'] ?? j['FALTAS']),
      cargaHoraria: asInt(j['CARGAHORARIA'] ?? j['CARGA']),
      percentualApi: asDouble(j['PERCENTUAL']),
    );
  }

  Map<String, dynamic> toJson() => {
        'DISCIPLINA': disciplina, '3 - TOTAL FALTAS': faltas,
        'CARGAHORARIA': cargaHoraria, 'PERCENTUAL': percentualApi,
      };
}
```

- [ ] **Step 6: Implementar disciplina.dart e periodo_letivo.dart**

```dart
// disciplina.dart
class Disciplina {
  final String nome;
  final String status; // DESCRICAO
  final String codDisc;
  final int idPerlet;
  Disciplina({required this.nome, required this.status,
      required this.codDisc, required this.idPerlet});
  factory Disciplina.fromJson(Map<String, dynamic> j) => Disciplina(
        nome: (j['NOME'] ?? '').toString().trim(),
        status: (j['DESCRICAO'] ?? '').toString().trim(),
        codDisc: (j['CODDISC'] ?? '').toString(),
        idPerlet: int.tryParse('${j['IDPERLET']}') ?? 0,
      );
  Map<String, dynamic> toJson() =>
      {'NOME': nome, 'DESCRICAO': status, 'CODDISC': codDisc, 'IDPERLET': idPerlet};
}
```

```dart
// periodo_letivo.dart
class PeriodoLetivo {
  final int idPerlet;
  final String nome; // ex "2026.1"
  const PeriodoLetivo({required this.idPerlet, required this.nome});
}
```

- [ ] **Step 7: Rodar e ver passar**

Run: `flutter test test/data/models_test.dart`
Expected: All tests passed.

- [ ] **Step 8: Commit**

```bash
git add lib/data/models test/data/models_test.dart
git commit -m "feat(data): modelos Nota/Falta/Aula/Disciplina/Periodo com TDD sobre JSON real"
```

### Task 2.2: RmApiDataSource

**Files:**
- Create: `lib/data/datasources/rm_api_ds.dart`

- [ ] **Step 1: Implementar**

```dart
import 'package:dio/dio.dart';
import '../../core/constants/endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/session_exception.dart';
import '../models/nota_disciplina.dart';
import '../models/falta_disciplina.dart';
import '../models/disciplina.dart';
import '../models/aula_horario.dart';

class RmApiDataSource {
  final DioClient _client;
  RmApiDataSource(this._client);
  Dio get _dio => _client.dio;

  List _dataList(Response r, [String? sub]) {
    final d = (r.data is Map) ? r.data['data'] : null;
    if (d is List) return d;
    if (d is Map && sub != null && d[sub] is List) return d[sub] as List;
    return const [];
  }

  Future<List<NotaDisciplina>> notas() async {
    final r = await _dio.get(Endpoints.notaEtapa);
    if (r.statusCode != 200) throw ApiException('Notas', statusCode: r.statusCode);
    return _dataList(r, 'Notas')
        .map((e) => NotaDisciplina.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FaltaDisciplina>> faltas() async {
    final r = await _dio.get(Endpoints.faltaEtapa);
    if (r.statusCode != 200) throw ApiException('Faltas', statusCode: r.statusCode);
    return _dataList(r, 'FaltasEtapa')
        .map((e) => FaltaDisciplina.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Disciplina>> disciplinas() async {
    final r = await _dio.get(Endpoints.disciplinas);
    if (r.statusCode != 200) throw ApiException('Disciplinas', statusCode: r.statusCode);
    return _dataList(r)
        .map((e) => Disciplina.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AulaHorario>> horario() async {
    final r = await _dio.get(Endpoints.quadroHorario);
    if (r.statusCode != 200) throw ApiException('Horário', statusCode: r.statusCode);
    return _dataList(r, 'SHorarioAluno')
        .map((e) => AulaHorario.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
```

- [ ] **Step 2: Analisar**

Run: `flutter analyze lib/data/datasources/rm_api_ds.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/data/datasources/rm_api_ds.dart
git commit -m "feat(data): RmApiDataSource (notas/faltas/disciplinas/horário)"
```

### Task 2.3: AcademicRepository com cache stale-while-revalidate

**Files:**
- Create: `lib/data/repositories/academic_repository.dart`
- Test: `test/data/academic_repository_test.dart`

- [ ] **Step 1: Teste de cache (datasource fake)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faltas_scraper_flutter/data/repositories/academic_repository.dart';
import 'package:faltas_scraper_flutter/data/models/nota_disciplina.dart';

class _FakeApi implements AcademicApi {
  int notasCalls = 0;
  @override
  Future<List<NotaDisciplina>> notas() async {
    notasCalls++;
    return [NotaDisciplina(disciplina: 'X', situacao: 'Y', idTurmaDisc: 1, p1: 7)];
  }
  @override
  noSuchMethod(Invocation i) => Future.value(const []);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cachedNotas devolve cache imediato e revalida em background', () async {
    final api = _FakeApi();
    final repo = AcademicRepository(api);
    // primeira chamada: sem cache → busca rede
    final first = await repo.notas(idPerlet: 34);
    expect(first.first.disciplina, 'X');
    expect(api.notasCalls, 1);
    // segunda: deve servir cache (sem nova chamada síncrona obrigatória)
    final cached = await repo.cachedNotas(idPerlet: 34);
    expect(cached!.first.disciplina, 'X');
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/data/academic_repository_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar**

`AcademicApi` é uma interface fina sobre `RmApiDataSource` para permitir fakes em teste.

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/storage_keys.dart';
import '../models/nota_disciplina.dart';
import '../models/falta_disciplina.dart';
import '../models/disciplina.dart';
import '../models/aula_horario.dart';

abstract class AcademicApi {
  Future<List<NotaDisciplina>> notas();
  Future<List<FaltaDisciplina>> faltas();
  Future<List<Disciplina>> disciplinas();
  Future<List<AulaHorario>> horario();
}

class AcademicRepository {
  final AcademicApi _api;
  AcademicRepository(this._api);

  Future<void> _cache(String key, List<Map<String, dynamic>> json) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(json));
  }

  Future<List<Map<String, dynamic>>?> _readCache(String key) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(key);
    if (s == null) return null;
    return (jsonDecode(s) as List).cast<Map<String, dynamic>>();
  }

  Future<List<NotaDisciplina>?> cachedNotas({required int idPerlet}) async {
    final c = await _readCache('${StorageKeys.cacheNotasPrefix}$idPerlet');
    return c?.map(NotaDisciplina.fromJson).toList();
  }

  Future<List<NotaDisciplina>> notas({required int idPerlet}) async {
    final data = await _api.notas();
    await _cache('${StorageKeys.cacheNotasPrefix}$idPerlet',
        data.map((e) => e.toJson()).toList());
    return data;
  }

  Future<List<FaltaDisciplina>?> cachedFaltas({required int idPerlet}) async {
    final c = await _readCache('${StorageKeys.cacheFaltasPrefix}$idPerlet');
    return c?.map(FaltaDisciplina.fromJson).toList();
  }

  Future<List<FaltaDisciplina>> faltas({required int idPerlet}) async {
    final data = await _api.faltas();
    await _cache('${StorageKeys.cacheFaltasPrefix}$idPerlet',
        data.map((e) => e.toJson()).toList());
    return data;
  }

  Future<List<AulaHorario>?> cachedHorario({required int idPerlet}) async {
    final c = await _readCache('${StorageKeys.cacheHorarioPrefix}$idPerlet');
    return c?.map(AulaHorario.fromJson).toList();
  }

  Future<List<AulaHorario>> horario({required int idPerlet}) async {
    final data = await _api.horario();
    await _cache('${StorageKeys.cacheHorarioPrefix}$idPerlet',
        data.map((e) => e.toJson()).toList());
    return data;
  }

  Future<List<Disciplina>> disciplinas() => _api.disciplinas();
}
```

- [ ] **Step 4: Tornar RmApiDataSource um AcademicApi**

Modify `lib/data/datasources/rm_api_ds.dart`: trocar a assinatura da classe para `class RmApiDataSource implements AcademicApi` e adicionar o import:

```dart
import '../repositories/academic_repository.dart';
```

- [ ] **Step 5: Rodar e ver passar**

Run: `flutter test test/data/academic_repository_test.dart`
Expected: All tests passed.

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/academic_repository.dart lib/data/datasources/rm_api_ds.dart test/data/academic_repository_test.dart
git commit -m "feat(data): AcademicRepository com cache (stale-while-revalidate)"
```

---

## FASE 3 — Tema e providers de apresentação

### Task 3.1: AppTheme (dark M3)

**Files:**
- Create: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Implementar**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: AppColors.bg,
      primary: AppColors.accent,
      secondary: AppColors.accent,
      error: AppColors.error,
      onSurface: AppColors.text,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, color: AppColors.text2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.text),
        bodySmall: TextStyle(color: AppColors.text2),
      ),
    );
  }
}
```

- [ ] **Step 2: Analisar**

Run: `flutter analyze lib/core/theme/app_theme.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme/app_theme.dart
git commit -m "feat(core): AppTheme dark Material 3"
```

### Task 3.2: AuthProvider

**Files:**
- Create: `lib/presentation/providers/auth_provider.dart`

- [ ] **Step 1: Implementar**

```dart
import 'package:flutter/foundation.dart';
import '../../data/models/credenciais.dart';
import '../../data/models/contexto_aluno.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

class AuthProvider with ChangeNotifier {
  final AuthRepository _repo;
  AuthProvider(this._repo);

  AuthStatus _status = AuthStatus.unknown;
  bool _loading = false;
  String? _error;
  ContextoAluno? _contexto;

  AuthStatus get status => _status;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _status == AuthStatus.loggedIn;
  ContextoAluno? get contexto => _contexto;

  Future<void> restore() async {
    if (await _repo.hasStoredSession()) {
      _status = AuthStatus.loggedIn;
      _contexto = await _repo.getSelectedContexto();
    } else {
      _status = AuthStatus.loggedOut;
    }
    notifyListeners();
  }

  Future<bool> login(String cpf, String senha) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.login(Credenciais(cpf: cpf.trim(), senha: senha));
      _contexto = await _repo.getSelectedContexto();
      _status = AuthStatus.loggedIn;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Não foi possível entrar. Verifique CPF e senha.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Lista contextos/períodos disponíveis (para o bottom sheet).
  Future<List<ContextoAluno>> fetchContextos() => _repo.buscarContextos();

  /// Troca o período/contexto e persiste. Retorna o novo contexto.
  Future<ContextoAluno> trocarContexto(ContextoAluno ctx) async {
    await _repo.selecionarContexto(ctx);
    _contexto = ctx;
    notifyListeners();
    return ctx;
  }

  Future<void> logout() async {
    await _repo.logout();
    _contexto = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/providers/auth_provider.dart
git commit -m "feat(presentation): AuthProvider (restore/login/logout)"
```

### Task 3.3: AcademicProvider

**Files:**
- Create: `lib/presentation/providers/academic_provider.dart`

- [ ] **Step 1: Implementar**

```dart
import 'package:flutter/foundation.dart';
import '../../data/models/nota_disciplina.dart';
import '../../data/models/falta_disciplina.dart';
import '../../data/models/aula_horario.dart';
import '../../data/models/disciplina.dart';
import '../../data/models/contexto_aluno.dart';
import '../../data/repositories/academic_repository.dart';

class AcademicProvider with ChangeNotifier {
  final AcademicRepository _repo;
  AcademicProvider(this._repo);

  ContextoAluno? contexto;
  List<NotaDisciplina> notas = [];
  List<FaltaDisciplina> faltas = [];
  List<AulaHorario> horario = [];
  List<Disciplina> disciplinas = [];
  bool loading = false;
  String? error;

  int get _idPerlet => contexto?.idPerlet ?? 0;

  void setContexto(ContextoAluno c) {
    contexto = c;
    notifyListeners();
  }

  /// Média geral = média das médias exibidas existentes.
  double? get mediaGeral {
    final ms = notas.map((n) => n.mediaExibida).whereType<double>().toList();
    if (ms.isEmpty) return null;
    return ms.reduce((a, b) => a + b) / ms.length;
  }

  int get totalFaltas => faltas.fold(0, (s, f) => s + f.faltas);

  List<FaltaDisciplina> get faltasEmRisco =>
      faltas.where((f) => f.nivel != NivelFalta.tranquilo).toList();

  Future<void> loadFromCache() async {
    notas = await _repo.cachedNotas(idPerlet: _idPerlet) ?? notas;
    faltas = await _repo.cachedFaltas(idPerlet: _idPerlet) ?? faltas;
    horario = await _repo.cachedHorario(idPerlet: _idPerlet) ?? horario;
    notifyListeners();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.notas(idPerlet: _idPerlet),
        _repo.faltas(idPerlet: _idPerlet),
        _repo.horario(idPerlet: _idPerlet),
      ]);
      notas = results[0] as List<NotaDisciplina>;
      faltas = results[1] as List<FaltaDisciplina>;
      horario = results[2] as List<AulaHorario>;
    } catch (e) {
      error = 'Falha ao atualizar dados.';
    }
    loading = false;
    notifyListeners();
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/providers/academic_provider.dart
git commit -m "feat(presentation): AcademicProvider (estado + agregações + cache)"
```

---

## FASE 4 — Widgets reutilizáveis

### Task 4.1: Widgets base (chips, cards, progress, skeleton, empty)

**Files:**
- Create: `lib/presentation/widgets/status_chip.dart`
- Create: `lib/presentation/widgets/stat_card.dart`
- Create: `lib/presentation/widgets/ring_gauge.dart`
- Create: `lib/presentation/widgets/skeleton.dart`
- Create: `lib/presentation/widgets/empty_state.dart`

- [ ] **Step 1: status_chip.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const StatusChip(this.text, {super.key, this.color = AppColors.accent});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );
}
```

- [ ] **Step 2: stat_card.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  const StatCard(
      {super.key,
      required this.value,
      required this.label,
      this.valueColor = AppColors.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: valueColor)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.text2)),
          ],
        ),
      );
}
```

- [ ] **Step 3: ring_gauge.dart** (anel da média via fl_chart)

```dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RingGauge extends StatelessWidget {
  final double? value; // 0..10
  final String caption;
  const RingGauge({super.key, required this.value, this.caption = 'MÉDIA'});

  @override
  Widget build(BuildContext context) {
    final v = value ?? 0;
    final pct = (v / 10).clamp(0.0, 1.0);
    final color = v >= 7
        ? AppColors.success
        : v >= 5
            ? AppColors.warning
            : AppColors.error;
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(alignment: Alignment.center, children: [
        PieChart(PieChartData(
          startDegreeOffset: -90,
          sectionsSpace: 0,
          centerSpaceRadius: 42,
          sections: [
            PieChartSectionData(
                value: pct, color: color, radius: 12, showTitle: false),
            PieChartSectionData(
                value: 1 - pct,
                color: AppColors.border,
                radius: 12,
                showTitle: false),
          ],
        )),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text(value == null ? '—' : v.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text)),
          Text(caption,
              style: const TextStyle(fontSize: 9, color: AppColors.text2)),
        ]),
      ]),
    );
  }
}
```

- [ ] **Step 4: skeleton.dart**

```dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: AppColors.card,
        highlightColor: AppColors.card2,
        child: Column(
          children: List.generate(
            count,
            (_) => Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      );
}
```

- [ ] **Step 5: empty_state.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState(
      {super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.text2),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: AppColors.text, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.text2, fontSize: 12)),
            ],
          ],
        ),
      );
}
```

- [ ] **Step 6: Analisar + commit**

Run: `flutter analyze lib/presentation/widgets`
Expected: No issues found.

```bash
git add lib/presentation/widgets
git commit -m "feat(widgets): StatusChip, StatCard, RingGauge, Skeleton, EmptyState"
```

### Task 4.2: NotaCard (widget test) e FaltaCard (widget test)

**Files:**
- Create: `lib/presentation/widgets/nota_card.dart`
- Create: `lib/presentation/widgets/falta_card.dart`
- Test: `test/widgets/cards_test.dart`

- [ ] **Step 1: Teste de widget**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:faltas_scraper_flutter/data/models/nota_disciplina.dart';
import 'package:faltas_scraper_flutter/data/models/falta_disciplina.dart';
import 'package:faltas_scraper_flutter/presentation/widgets/nota_card.dart';
import 'package:faltas_scraper_flutter/presentation/widgets/falta_card.dart';

void main() {
  testWidgets('NotaCard mostra disciplina e P1', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotaCard(
          nota: NotaDisciplina(
              disciplina: 'Inglês VII',
              situacao: 'Aprovado por Média',
              idTurmaDisc: 1,
              p1: 8.5,
              mediaFinal: 9.5),
        ),
      ),
    ));
    expect(find.text('Inglês VII'), findsOneWidget);
    expect(find.text('8,5'), findsOneWidget);
  });

  testWidgets('NotaCard sem notas mostra empty', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NotaCard(
          nota: NotaDisciplina(
              disciplina: 'Estágio', situacao: 'Período em Curso', idTurmaDisc: 1),
        ),
      ),
    ));
    expect(find.textContaining('Sem notas'), findsOneWidget);
  });

  testWidgets('FaltaCard crítico mostra limite atingido', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FaltaCard(
          falta: FaltaDisciplina(disciplina: 'Redes', faltas: 8, cargaHoraria: 32),
        ),
      ),
    ));
    expect(find.text('Redes'), findsOneWidget);
    expect(find.textContaining('limite'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar e ver falhar**

Run: `flutter test test/widgets/cards_test.dart`
Expected: FAIL (NotaCard/FaltaCard indefinidos).

- [ ] **Step 3: Implementar nota_card.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/nota_parser.dart';
import '../../data/models/nota_disciplina.dart';
import 'status_chip.dart';

class NotaCard extends StatelessWidget {
  final NotaDisciplina nota;
  const NotaCard({super.key, required this.nota});

  String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(1).replaceAll('.', ',');

  Color _cor(Faixa f) {
    switch (f) {
      case Faixa.boa:
        return AppColors.success;
      case Faixa.atencao:
        return AppColors.warning;
      case Faixa.risco:
        return AppColors.error;
      case Faixa.neutra:
        return AppColors.accent;
    }
  }

  Widget _chip(String label, double? v, {bool destaque = false}) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: destaque
                ? AppColors.success.withValues(alpha: 0.10)
                : AppColors.card2,
            borderRadius: BorderRadius.circular(9),
            border: destaque
                ? Border.all(color: AppColors.success.withValues(alpha: 0.25))
                : null,
          ),
          child: Column(children: [
            Text(label,
                style: const TextStyle(fontSize: 8, color: AppColors.text2)),
            const SizedBox(height: 3),
            Text(_fmt(v),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: destaque
                        ? AppColors.success
                        : (NotaParser.faixaCor(v) == Faixa.risco && v != null
                            ? AppColors.error
                            : AppColors.text))),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nota.disciplina,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(nota.situacao,
                    style: const TextStyle(fontSize: 10, color: AppColors.text2)),
              ]),
            ),
            StatusChip(_fmt(nota.mediaExibida), color: _cor(nota.faixaMedia)),
          ]),
          if (nota.semNotas)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: Text('Sem notas lançadas ainda',
                    style: TextStyle(color: AppColors.text2, fontSize: 11)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Row(children: [
                _chip('P1', nota.p1),
                _chip('P2', nota.p2),
                _chip('P3', nota.p3),
                _chip('Final', nota.mediaExibida, destaque: true),
              ]),
            ),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 4: Implementar falta_card.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/falta_disciplina.dart';
import 'status_chip.dart';

class FaltaCard extends StatelessWidget {
  final FaltaDisciplina falta;
  const FaltaCard({super.key, required this.falta});

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final Color borda;
    final Color fundo;
    switch (falta.nivel) {
      case NivelFalta.critico:
        cor = AppColors.error;
        borda = AppColors.error.withValues(alpha: 0.45);
        fundo = AppColors.error.withValues(alpha: 0.07);
        break;
      case NivelFalta.atencao:
        cor = AppColors.warning;
        borda = AppColors.warning.withValues(alpha: 0.40);
        fundo = AppColors.warning.withValues(alpha: 0.06);
        break;
      case NivelFalta.tranquilo:
        cor = AppColors.success;
        borda = AppColors.border;
        fundo = AppColors.card;
        break;
    }
    final pct = falta.percentualLimite;
    final meta = falta.nivel == NivelFalta.critico
        ? '${falta.faltas} de ${falta.maxFaltas} faltas · limite atingido'
        : '${falta.faltas} de ${falta.maxFaltas} faltas · faltam ${falta.faltasRestantes}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borda),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(falta.disciplina,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          StatusChip('${pct.round()}%', color: cor),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(cor),
          ),
        ),
        const SizedBox(height: 7),
        Text(meta, style: const TextStyle(color: AppColors.text2, fontSize: 11)),
      ]),
    );
  }
}
```

- [ ] **Step 5: Rodar e ver passar**

Run: `flutter test test/widgets/cards_test.dart`
Expected: All tests passed.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/widgets/nota_card.dart lib/presentation/widgets/falta_card.dart test/widgets/cards_test.dart
git commit -m "feat(widgets): NotaCard e FaltaCard com widget tests"
```

### Task 4.3: AulaTile e PeriodSheet

**Files:**
- Create: `lib/presentation/widgets/aula_tile.dart`
- Create: `lib/presentation/widgets/period_sheet.dart`

- [ ] **Step 1: aula_tile.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/aula_horario.dart';

class AulaTile extends StatelessWidget {
  final AulaHorario aula;
  const AulaTile({super.key, required this.aula});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(aula.horaInicial,
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.bold)),
            Text(aula.horaFinal,
                style: const TextStyle(color: AppColors.text2, fontSize: 11)),
          ]),
          const SizedBox(width: 14),
          Container(width: 3, height: 36, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(aula.nome,
                  style: const TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.w600)),
              Text(aula.local ?? 'Sala não informada',
                  style: const TextStyle(color: AppColors.text2, fontSize: 11)),
            ]),
          ),
        ]),
      );
}
```

- [ ] **Step 2: period_sheet.dart**

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/contexto_aluno.dart';

/// Bottom sheet de seleção de período/contexto. Devolve o contexto escolhido.
Future<ContextoAluno?> showPeriodSheet(
    BuildContext context, List<ContextoAluno> contextos, ContextoAluno? atual) {
  return showModalBottomSheet<ContextoAluno>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Selecione o período',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        ...contextos.map((c) {
          final sel = c.idContextoAluno == atual?.idContextoAluno;
          return ListTile(
            title: Text(c.nomeCurso,
                style: const TextStyle(color: AppColors.text)),
            subtitle: Text('${c.nomePeriodo} · ${c.nomeTurno}',
                style: const TextStyle(color: AppColors.text2)),
            trailing: sel
                ? const Icon(Icons.check_circle, color: AppColors.accent)
                : null,
            onTap: () => Navigator.pop(ctx, c),
          );
        }),
        const SizedBox(height: 8),
      ]),
    ),
  );
}
```

- [ ] **Step 3: Analisar + commit**

Run: `flutter analyze lib/presentation/widgets/aula_tile.dart lib/presentation/widgets/period_sheet.dart`
Expected: No issues found.

```bash
git add lib/presentation/widgets/aula_tile.dart lib/presentation/widgets/period_sheet.dart
git commit -m "feat(widgets): AulaTile e PeriodSheet (bottom sheet de período)"
```

---

## FASE 5 — Telas

### Task 5.1: LoginScreen

**Files:**
- Create: `lib/presentation/screens/login_screen.dart`

- [ ] **Step 1: Implementar**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _cpf = TextEditingController();
  final _senha = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _cpf.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_cpf.text, _senha.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(auth.error ?? 'Erro ao entrar'),
      ));
    }
    // Navegação é reativa via router (redirect por isLoggedIn).
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.school, size: 64, color: AppColors.accent),
                const SizedBox(height: 8),
                const Text('Faltas iCEV',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _cpf,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                      labelText: 'CPF', prefixIcon: Icon(Icons.person)),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o CPF' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senha,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe a senha' : null,
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Mesma senha do TOTVS',
                      style: TextStyle(color: AppColors.text2, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('ENTRAR'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/login_screen.dart
git commit -m "feat(screens): LoginScreen dark"
```

### Task 5.2: DashboardScreen

**Files:**
- Create: `lib/presentation/screens/dashboard_screen.dart`

- [ ] **Step 1: Implementar (layout B aprovado: anel + métricas + próximas aulas + risco)**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/aula_horario.dart';
import '../providers/academic_provider.dart';
import '../widgets/ring_gauge.dart';
import '../widgets/skeleton.dart';
import '../widgets/aula_tile.dart';
import '../widgets/falta_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    final hoje = DateTime.now().weekday % 7 + 1; // weekday 1=Seg → RM 1=Dom..7=Sáb
    final aulasHoje =
        p.horario.where((a) => a.diaSemana == hoje).toList()
          ..sort((a, b) => a.horaInicial.compareTo(b.horaInicial));
    return RefreshIndicator(
      onRefresh: p.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (p.loading && p.notas.isEmpty)
            const SkeletonList(count: 4)
          else ...[
            _hero(p),
            const SizedBox(height: 12),
            _secao('Próximas aulas · hoje'),
            if (aulasHoje.isEmpty)
              const _Vazio('Sem aulas hoje 🎉')
            else
              ...aulasHoje.map((a) => AulaTile(aula: a)),
            const SizedBox(height: 12),
            if (p.faltasEmRisco.isNotEmpty) ...[
              _secao('Risco de reprovação por falta'),
              ...p.faltasEmRisco.map((f) => FaltaCard(falta: f)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _hero(AcademicProvider p) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          RingGauge(value: p.mediaGeral),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _metric('${p.totalFaltas}', 'Faltas'),
            _metric('${p.notas.length}', 'Disciplinas'),
            _metric(p.faltasEmRisco.isEmpty ? 'Em dia' : 'Atenção', 'Situação',
                cor: p.faltasEmRisco.isEmpty
                    ? AppColors.success
                    : AppColors.warning),
          ]),
        ]),
      );

  Widget _metric(String v, String k, {Color cor = AppColors.text}) =>
      Column(children: [
        Text(v,
            style: TextStyle(
                color: cor, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(k, style: const TextStyle(color: AppColors.text2, fontSize: 10)),
      ]);

  Widget _secao(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: AppColors.text2,
                fontSize: 11,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600)),
      );
}

class _Vazio extends StatelessWidget {
  final String t;
  const _Vazio(this.t);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(t,
            style: const TextStyle(color: AppColors.text2)),
      );
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/presentation/screens/dashboard_screen.dart
git commit -m "feat(screens): DashboardScreen (anel + métricas + aulas + risco)"
```

### Task 5.3: NotasScreen, FaltasScreen, HorarioScreen

**Files:**
- Create: `lib/presentation/screens/notas_screen.dart`
- Create: `lib/presentation/screens/faltas_screen.dart`
- Create: `lib/presentation/screens/horario_screen.dart`

- [ ] **Step 1: notas_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/academic_provider.dart';
import '../widgets/nota_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/empty_state.dart';

class NotasScreen extends StatelessWidget {
  const NotasScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    return RefreshIndicator(
      onRefresh: p.refresh,
      child: (p.loading && p.notas.isEmpty)
          ? ListView(padding: const EdgeInsets.all(16),
              children: const [SkeletonList()])
          : p.notas.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  EmptyState(
                      icon: Icons.grade_outlined,
                      title: 'Nenhuma nota encontrada',
                      subtitle: 'Puxe para atualizar')
                ])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: p.notas.map((n) => NotaCard(nota: n)).toList(),
                ),
    );
  }
}
```

- [ ] **Step 2: faltas_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/academic_provider.dart';
import '../widgets/falta_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/empty_state.dart';

class FaltasScreen extends StatelessWidget {
  const FaltasScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    return RefreshIndicator(
      onRefresh: p.refresh,
      child: (p.loading && p.faltas.isEmpty)
          ? ListView(padding: const EdgeInsets.all(16),
              children: const [SkeletonList()])
          : p.faltas.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'Nenhuma falta registrada',
                      subtitle: 'Tudo certo por aqui')
                ])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: p.faltas.map((f) => FaltaCard(falta: f)).toList(),
                ),
    );
  }
}
```

- [ ] **Step 3: horario_screen.dart (toggle Hoje/Semana)**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/aula_horario.dart';
import '../providers/academic_provider.dart';
import '../widgets/aula_tile.dart';
import '../widgets/empty_state.dart';

class HorarioScreen extends StatefulWidget {
  const HorarioScreen({super.key});
  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  bool _hoje = true;
  static const _dias = ['', 'Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta',
      'Sexta', 'Sábado'];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    final hojeRm = DateTime.now().weekday % 7 + 1;
    final aulas = [...p.horario]
      ..sort((a, b) {
        final d = a.diaSemana.compareTo(b.diaSemana);
        return d != 0 ? d : a.horaInicial.compareTo(b.horaInicial);
      });
    final filtradas =
        _hoje ? aulas.where((a) => a.diaSemana == hojeRm).toList() : aulas;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Hoje')),
            ButtonSegment(value: false, label: Text('Semana')),
          ],
          selected: {_hoje},
          onSelectionChanged: (s) => setState(() => _hoje = s.first),
        ),
      ),
      Expanded(
        child: filtradas.isEmpty
            ? const EmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'Sem aulas',
                subtitle: 'Nada agendado para este filtro')
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _build(filtradas),
              ),
      ),
    ]);
  }

  List<Widget> _build(List<AulaHorario> aulas) {
    final out = <Widget>[];
    int? diaAtual;
    for (final a in aulas) {
      if (!_hoje && a.diaSemana != diaAtual) {
        diaAtual = a.diaSemana;
        out.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(_dias[a.diaSemana].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.text2,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ));
      }
      out.add(AulaTile(aula: a));
    }
    return out;
  }
}
```

- [ ] **Step 4: Analisar + commit**

Run: `flutter analyze lib/presentation/screens`
Expected: No issues found.

```bash
git add lib/presentation/screens/notas_screen.dart lib/presentation/screens/faltas_screen.dart lib/presentation/screens/horario_screen.dart
git commit -m "feat(screens): Notas, Faltas e Horário"
```

### Task 5.4: SettingsScreen e ShellScreen (NavigationBar + período no app bar)

**Files:**
- Create: `lib/presentation/screens/settings_screen.dart`
- Create: `lib/presentation/screens/shell_screen.dart`

- [ ] **Step 1: settings_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(children: [
        const ListTile(
          leading: Icon(Icons.dark_mode, color: AppColors.accent),
          title: Text('Tema', style: TextStyle(color: AppColors.text)),
          subtitle: Text('Escuro', style: TextStyle(color: AppColors.text2)),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text('Sair', style: TextStyle(color: AppColors.error)),
          onTap: () => context.read<AuthProvider>().logout(),
        ),
        const AboutListTile(
          icon: Icon(Icons.info_outline, color: AppColors.text2),
          applicationName: 'Faltas iCEV',
          applicationVersion: '2.0.0',
          child: Text('Sobre', style: TextStyle(color: AppColors.text)),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 2: shell_screen.dart**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/academic_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/period_sheet.dart';
import 'dashboard_screen.dart';
import 'notas_screen.dart';
import 'faltas_screen.dart';
import 'horario_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _idx = 0;
  static const _titulos = ['Início', 'Notas', 'Faltas', 'Horário'];
  final _telas = const [
    DashboardScreen(),
    NotasScreen(),
    FaltasScreen(),
    HorarioScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final academic = context.read<AcademicProvider>();
      final auth = context.read<AuthProvider>();
      // Entrega o contexto/período persistido ao provider acadêmico.
      if (auth.contexto != null) academic.setContexto(auth.contexto!);
      await academic.loadFromCache();
      await academic.refresh();
    });
  }

  Future<void> _abrirPeriodo() async {
    final auth = context.read<AuthProvider>();
    final academic = context.read<AcademicProvider>();
    final contextos = await auth.fetchContextos();
    if (!mounted || contextos.isEmpty) return;
    final escolhido = await showPeriodSheet(context, contextos, auth.contexto);
    if (escolhido == null) return;
    await auth.trocarContexto(escolhido);
    academic.setContexto(escolhido);
    await academic.loadFromCache();
    await academic.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_idx]),
        actions: [
          if (p.contexto != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: ActionChip(
                  onPressed: _abrirPeriodo,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                  side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.25)),
                  label: Text('${p.contexto!.nomePeriodo} ▾',
                      style: const TextStyle(
                          color: AppColors.accent, fontSize: 12)),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _telas[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Notas'),
          NavigationDestination(
              icon: Icon(Icons.trending_down_outlined), label: 'Faltas'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), label: 'Horário'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Analisar + commit**

Run: `flutter analyze lib/presentation/screens/settings_screen.dart lib/presentation/screens/shell_screen.dart`
Expected: No issues found.

```bash
git add lib/presentation/screens/settings_screen.dart lib/presentation/screens/shell_screen.dart
git commit -m "feat(screens): SettingsScreen e ShellScreen com NavigationBar"
```

---

## FASE 6 — Composição, roteamento e limpeza

### Task 6.1: app.dart (router + providers + bootstrap)

**Files:**
- Create: `lib/app.dart`

- [ ] **Step 1: Implementar**

`AcademicProvider.setContexto` é alimentado após login a partir do primeiro contexto buscado. Para simplicidade nesta entrega, o `AuthRepository.login` já seleciona o primeiro contexto; o `ShellScreen` carrega os dados. O `idPerlet` vem do contexto persistido (carregado no bootstrap).

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/academic_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/academic_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/shell_screen.dart';

class App extends StatelessWidget {
  final AuthRepository authRepo;
  final AcademicRepository academicRepo;
  const App({super.key, required this.authRepo, required this.academicRepo});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => AuthProvider(authRepo)..restore()),
        ChangeNotifierProvider(create: (_) => AcademicProvider(academicRepo)),
      ],
      child: Builder(builder: (context) {
        final auth = context.watch<AuthProvider>();
        final router = GoRouter(
          refreshListenable: auth,
          redirect: (ctx, state) {
            if (auth.status == AuthStatus.unknown) return null;
            final loggingIn = state.matchedLocation == '/login';
            if (!auth.isLoggedIn) return loggingIn ? null : '/login';
            if (loggingIn) return '/';
            return null;
          },
          routes: [
            GoRoute(path: '/', builder: (_, __) => const ShellScreen()),
            GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
          ],
        );
        return MaterialApp.router(
          title: 'Faltas iCEV',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          routerConfig: router,
        );
      }),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/app.dart
git commit -m "feat: App com router reativo e providers"
```

### Task 6.2: main.dart (bootstrap de dependências)

**Files:**
- Modify: `lib/main.dart` (substituir conteúdo)

- [ ] **Step 1: Substituir main.dart**

O `AuthRepository.refreshSession` é ligado ao interceptor aqui (depois de criados os repos).

```dart
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/secure_storage_ds.dart';
import 'data/datasources/rm_api_ds.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/academic_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = await DioClient.create();
  final storage = SecureStorageDataSource();
  final authRepo = AuthRepository(client, storage);

  // Liga o interceptor de sessão: ao expirar, re-loga e reexecuta.
  client.attachAuth(authRepo.refreshSession);

  final academicRepo = AcademicRepository(RmApiDataSource(client));

  runApp(App(authRepo: authRepo, academicRepo: academicRepo));
}
```

- [ ] **Step 2: Rodar app no emulador**

Run: `flutter run -d emulator-5554`
Expected: compila, abre na tela de Login dark; após login vê o Dashboard.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat: bootstrap de dependências e wiring do interceptor"
```

### Task 6.3: Remover código legado

**Files:**
- Delete: `lib/routes.dart`, `lib/providers/`, `lib/screens/` (antigas), `lib/services/`, `lib/models/` (antigas, exceto o que foi migrado para `lib/data/models`)

- [ ] **Step 1: Remover arquivos antigos**

```bash
git rm lib/routes.dart
git rm -r lib/providers lib/screens lib/services
git rm lib/models/falta_model.dart lib/models/horario_model.dart lib/models/login_model.dart lib/models/notification_settings_model.dart lib/models/contexto_aluno.dart
```

- [ ] **Step 2: Garantir que nada importa os antigos**

Run: `flutter analyze`
Expected: No issues found. (Se aparecer import quebrado, corrigir o import para o novo caminho em `lib/data/...`.)

- [ ] **Step 3: Remover device_preview e android_alarm_manager_plus do pubspec**

No `pubspec.yaml`, remover as linhas `device_preview:`, `android_alarm_manager_plus:`, `timezone:` (fora de escopo nesta entrega). Rodar `flutter pub get`.

- [ ] **Step 4: Rodar testes e análise**

Run: `flutter test`
Expected: All tests passed.
Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove código legado e dependências fora de escopo"
```

### Task 6.4: Verificação final no app real

- [ ] **Step 1: Rodar no emulador e validar fluxos**

Run: `flutter run -d emulator-5554`
Validar manualmente:
1. Login com credenciais reais → Dashboard com anel da média.
2. Abas Notas/Faltas/Horário carregam dados reais.
3. Pull-to-refresh atualiza.
4. Fechar e reabrir o app **não** pede login de novo (sessão restaurada).
5. Trocar período via chip no app bar recarrega os dados.

- [ ] **Step 2: Screenshot de cada aba para conferência visual**

Usar `adb exec-out screencap` em cada aba e revisar contraste/hierarquia contra a paleta.

- [ ] **Step 3: Commit final (se houve ajustes)**

```bash
git add -A
git commit -m "fix: ajustes finais pós-verificação manual"
```

---

## Notas de risco / pendências conhecidas
- **`FaltaEtapa`**: o shape exato (chaves de total de faltas/percentual/carga) não veio no PDF. O `FaltaDisciplina.fromJson` é tolerante (várias chaves) e deriva `maxFaltas` por regra de 3 quando a carga não vem. Ajustar as chaves quando houver amostra real do `FaltaEtapa`.
- **`DIASEMANA`**: assumida convenção RM 1=Domingo…7=Sábado (amostra "2" às 18:30 = Segunda). Confirmar com mais amostras.
- **Seleção de período via bottom sheet**: implementada (Task 5.4 `_abrirPeriodo` → `showPeriodSheet` → `trocarContexto` + reload). Observação: o RM pode expor os períodos como múltiplos itens de `buscarContextos` (cada contexto traz `nomePeriodo`/`idPerlet`). Se em teste só vier um contexto, validar se o RM exige outro endpoint de períodos; nesse caso adicionar um `buscarPeriodos` ao `AuthRepository`.
- **AGP/Kotlin**: manter como está; atualizar fora desta entrega.
```
