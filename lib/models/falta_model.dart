class FaltaModel {
  final String nomeMateria;
  final int faltas;
  final int podeFaltar;
  final double percentual;

  FaltaModel({
    required this.nomeMateria,
    required this.faltas,
    required this.podeFaltar,
    required this.percentual,
  });

  factory FaltaModel.fromJson(Map<String, dynamic> json) {
    return FaltaModel(
      nomeMateria: json['nomeMateria'] as String? ?? 'Matéria não identificada',
      faltas: json['faltas'] as int? ?? 0,
      podeFaltar: json['podeFaltar'] as int? ?? 0,
      percentual: (json['percentual'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomeMateria': nomeMateria,
      'faltas': faltas,
      'podeFaltar': podeFaltar,
      'percentual': percentual,
    };
  }
}
