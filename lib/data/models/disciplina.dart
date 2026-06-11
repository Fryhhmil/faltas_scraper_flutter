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
