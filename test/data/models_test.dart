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

  test('FaltaDisciplina deriva carga via regra de 3 quando cargaHoraria=0', () {
    // 5 faltas = 25% → carga derivada = 5/(0.25) = 20 → max = 20*0.25 = 5
    final f = FaltaDisciplina(
      disciplina: 'X',
      faltas: 5,
      percentualApi: 25,
    );
    expect(f.maxFaltas, 5);
    expect(f.percentualLimite, 100);
    expect(f.nivel, NivelFalta.critico);
  });

  test('FaltaDisciplina descarta carga derivada absurda (guarda de plausibilidade)', () {
    // 1 falta = 0.01% → carga derivada = 1/(0.0001) = 10000 → guardado para 0
    final f = FaltaDisciplina(
      disciplina: 'X',
      faltas: 1,
      percentualApi: 0.01,
    );
    expect(f.maxFaltas, 0);
    expect(f.percentualLimite, 0);
  });
}
