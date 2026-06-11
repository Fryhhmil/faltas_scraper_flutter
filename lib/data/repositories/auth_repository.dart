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
