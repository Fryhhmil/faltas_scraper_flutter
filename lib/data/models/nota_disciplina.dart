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
