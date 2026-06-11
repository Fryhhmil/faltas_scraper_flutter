import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faltas_scraper_flutter/data/repositories/academic_repository.dart';
import 'package:faltas_scraper_flutter/data/models/nota_disciplina.dart';

class _FakeApi implements AcademicApi {
  int notasCalls = 0;
  bool failNotas = false;
  @override
  Future<List<NotaDisciplina>> notas() async {
    notasCalls++;
    if (failNotas) throw Exception('network error');
    return [NotaDisciplina(disciplina: 'X', situacao: 'Y', idTurmaDisc: 1, p1: 7)];
  }
  @override
  noSuchMethod(Invocation i) => Future.value(const []);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('notas busca rede e grava cache; cachedNotas lê o cache', () async {
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

  test('notas devolve cache local quando a rede falha', () async {
    final api = _FakeApi();
    final repo = AcademicRepository(api);
    // primeira chamada: sucesso, popula o cache
    final first = await repo.notas(idPerlet: 34);
    expect(first.first.disciplina, 'X');

    // segunda chamada: rede falha, deve cair para o cache em vez de lançar
    api.failNotas = true;
    final fallback = await repo.notas(idPerlet: 34);
    expect(fallback.first.disciplina, 'X');
  });
}
