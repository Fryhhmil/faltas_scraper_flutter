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
      nomeMateria: json['nomeMateria'] as String,
      faltas: json['faltas'] as int,
      podeFaltar: json['podeFaltar'] as int,
      percentual: json['percentual'] as double,
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
