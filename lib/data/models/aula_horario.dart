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
