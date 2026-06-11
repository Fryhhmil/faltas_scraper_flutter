enum NivelFalta { tranquilo, atencao, critico }

class FaltaDisciplina {
  final String disciplina;
  final int faltas;          // faltas em horas/aulas
  final int cargaHoraria;    // 0 se desconhecida
  final double? percentualApi; // PERCENTUAL vindo da API, se houver

  FaltaDisciplina({
    required this.disciplina,
    required this.faltas,
    this.cargaHoraria = 0,
    this.percentualApi,
  });

  /// Máximo de faltas permitido = 25% da carga.
  int get maxFaltas {
    if (cargaHoraria > 0) return (cargaHoraria * 0.25).floor();
    // Deriva via regra de 3 a partir do percentual informado pela API.
    if (percentualApi != null && percentualApi! > 0 && faltas > 0) {
      final carga = (faltas / (percentualApi! / 100));
      return (carga * 0.25).floor();
    }
    return 0;
  }

  /// % do limite legal (25%) já consumido. 100% = atingiu o limite.
  double get percentualLimite {
    final max = maxFaltas;
    if (max <= 0) return 0;
    return (faltas / max * 100).clamp(0, 999).toDouble();
  }

  int get faltasRestantes => (maxFaltas - faltas).clamp(0, 9999);

  NivelFalta get nivel {
    final p = percentualLimite;
    if (p >= 100) return NivelFalta.critico;
    if (p >= 70) return NivelFalta.atencao;
    return NivelFalta.tranquilo;
  }

  factory FaltaDisciplina.fromJson(Map<String, dynamic> j) {
    int asInt(dynamic v) {
      if (v is int) return v;
      final m = RegExp(r'-?\d+').stringMatch('${v ?? ''}');
      return m != null ? int.tryParse(m) ?? 0 : 0;
    }
    double? asDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('${v ?? ''}'.replaceAll(',', '.'));
    return FaltaDisciplina(
      disciplina: (j['Disciplina'] ?? j['DISCIPLINA'] ?? 'Disciplina')
          .toString().trim(),
      faltas: asInt(j['3 - TOTAL FALTAS'] ?? j['TOTAL FALTAS'] ?? j['FALTAS']),
      cargaHoraria: asInt(j['CARGAHORARIA'] ?? j['CARGA']),
      percentualApi: asDouble(j['PERCENTUAL']),
    );
  }

  Map<String, dynamic> toJson() => {
        'DISCIPLINA': disciplina, '3 - TOTAL FALTAS': faltas,
        'CARGAHORARIA': cargaHoraria, 'PERCENTUAL': percentualApi,
      };
}
