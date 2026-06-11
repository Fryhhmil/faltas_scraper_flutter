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
