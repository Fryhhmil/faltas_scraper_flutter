import 'package:dio/dio.dart';
import '../../core/constants/endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/session_exception.dart';
import '../models/nota_disciplina.dart';
import '../models/falta_disciplina.dart';
import '../models/disciplina.dart';
import '../models/aula_horario.dart';
import '../repositories/academic_repository.dart';

class RmApiDataSource implements AcademicApi {
  final DioClient _client;
  RmApiDataSource(this._client);
  Dio get _dio => _client.dio;

  List _dataList(Response r, [String? sub]) {
    final d = (r.data is Map) ? r.data['data'] : null;
    if (d is List) return d;
    if (d is Map && sub != null && d[sub] is List) return d[sub] as List;
    return const [];
  }

  @override
  Future<List<NotaDisciplina>> notas() async {
    final r = await _dio.get(Endpoints.notaEtapa);
    if (r.statusCode != 200) throw ApiException('Notas', statusCode: r.statusCode);
    return _dataList(r, 'Notas')
        .map((e) => NotaDisciplina.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FaltaDisciplina>> faltas() async {
    final r = await _dio.get(Endpoints.faltaEtapa);
    if (r.statusCode != 200) throw ApiException('Faltas', statusCode: r.statusCode);
    return _dataList(r, 'FaltasEtapa')
        .map((e) => FaltaDisciplina.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Disciplina>> disciplinas() async {
    final r = await _dio.get(Endpoints.disciplinas);
    if (r.statusCode != 200) throw ApiException('Disciplinas', statusCode: r.statusCode);
    return _dataList(r)
        .map((e) => Disciplina.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AulaHorario>> horario() async {
    final r = await _dio.get(Endpoints.quadroHorario);
    if (r.statusCode != 200) throw ApiException('Horário', statusCode: r.statusCode);
    return _dataList(r, 'SHorarioAluno')
        .map((e) => AulaHorario.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
