class ContextoAluno {
  final int codColigada;
  final int codFilial;
  final int codTipoCurso;
  final String idContextoAluno;
  final int idHabilitacaoFilial;
  final int idPerlet;
  final String ra;
  final String nomeCurso;
  final String nomePeriodo; // ex: "2026.1"
  final String nomeTurno;

  ContextoAluno({
    required this.codColigada,
    required this.codFilial,
    required this.codTipoCurso,
    required this.idContextoAluno,
    required this.idHabilitacaoFilial,
    required this.idPerlet,
    required this.ra,
    required this.nomeCurso,
    required this.nomePeriodo,
    required this.nomeTurno,
  });

  factory ContextoAluno.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    String asString(dynamic v) => v == null ? '' : v.toString();

    return ContextoAluno(
      codColigada: asInt(json['CODCOLIGADA']),
      codFilial: asInt(json['CODFILIAL']),
      codTipoCurso: asInt(json['CODTIPOCURSO']),
      idContextoAluno: asString(json['IDCONTEXTOALUNO']),
      idHabilitacaoFilial: asInt(json['IDHABILITACAOFILIAL']),
      idPerlet: asInt(json['IDPERLET']),
      ra: asString(json['RA']),
      nomeCurso: asString(json['NOMECURSO']),
      nomePeriodo: asString(json['CODPERLET']),
      nomeTurno: asString(json['NOMETURNO']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CODCOLIGADA': codColigada,
      'CODFILIAL': codFilial,
      'CODTIPOCURSO': codTipoCurso,
      'IDCONTEXTOALUNO': idContextoAluno,
      'IDHABILITACAOFILIAL': idHabilitacaoFilial,
      'IDPERLET': idPerlet,
      'RA': ra,
      'NOMECURSO': nomeCurso,
      'CODPERLET': nomePeriodo,
      'NOMETURNO': nomeTurno,
    };
  }
}
