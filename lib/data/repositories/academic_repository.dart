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

/// Busca da rede e atualiza o cache; em caso de falha de rede, devolve o
/// cache local se existir.
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
    try {
      final data = await _api.notas();
      await _cache('${StorageKeys.cacheNotasPrefix}$idPerlet',
          data.map((e) => e.toJson()).toList());
      return data;
    } catch (e) {
      final cached = await cachedNotas(idPerlet: idPerlet);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<FaltaDisciplina>?> cachedFaltas({required int idPerlet}) async {
    final c = await _readCache('${StorageKeys.cacheFaltasPrefix}$idPerlet');
    return c?.map(FaltaDisciplina.fromJson).toList();
  }

  Future<List<FaltaDisciplina>> faltas({required int idPerlet}) async {
    try {
      final data = await _api.faltas();
      await _cache('${StorageKeys.cacheFaltasPrefix}$idPerlet',
          data.map((e) => e.toJson()).toList());
      return data;
    } catch (e) {
      final cached = await cachedFaltas(idPerlet: idPerlet);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<AulaHorario>?> cachedHorario({required int idPerlet}) async {
    final c = await _readCache('${StorageKeys.cacheHorarioPrefix}$idPerlet');
    return c?.map(AulaHorario.fromJson).toList();
  }

  Future<List<AulaHorario>> horario({required int idPerlet}) async {
    try {
      final data = await _api.horario();
      await _cache('${StorageKeys.cacheHorarioPrefix}$idPerlet',
          data.map((e) => e.toJson()).toList());
      return data;
    } catch (e) {
      final cached = await cachedHorario(idPerlet: idPerlet);
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<List<Disciplina>> disciplinas() => _api.disciplinas();
}
