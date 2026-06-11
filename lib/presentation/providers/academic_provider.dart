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
