class HorarioAlunoModel {
  final int podefaltarSegunda;
  final int podefaltarTerca;
  final int podefaltarQuarta;
  final int podefaltarQuinta;
  final int podefaltarSexta;
  final List<String> materiasSegunda;
  final List<String> materiasTerca;
  final List<String> materiasQuarta;
  final List<String> materiasQuinta;
  final List<String> materiasSexta;

  HorarioAlunoModel({
    required this.podefaltarSegunda,
    required this.podefaltarTerca,
    required this.podefaltarQuarta,
    required this.podefaltarQuinta,
    required this.podefaltarSexta,
    required this.materiasSegunda,
    required this.materiasTerca,
    required this.materiasQuarta,
    required this.materiasQuinta,
    required this.materiasSexta,
  });

  factory HorarioAlunoModel.fromJson(Map<String, dynamic> json) {
    return HorarioAlunoModel(
      podefaltarSegunda: json['podefaltarSegunda'] as int,
      podefaltarTerca: json['podefaltarTerca'] as int,
      podefaltarQuarta: json['podefaltarQuarta'] as int,
      podefaltarQuinta: json['podefaltarQuinta'] as int,
      podefaltarSexta: json['podefaltarSexta'] as int,
      materiasSegunda: List<String>.from(json['materiasSegunda'] ?? []),
      materiasTerca: List<String>.from(json['materiasTerca'] ?? []),
      materiasQuarta: List<String>.from(json['materiasQuarta'] ?? []),
      materiasQuinta: List<String>.from(json['materiasQuinta'] ?? []),
      materiasSexta: List<String>.from(json['materiasSexta'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'podefaltarSegunda': podefaltarSegunda,
      'podefaltarTerca': podefaltarTerca,
      'podefaltarQuarta': podefaltarQuarta,
      'podefaltarQuinta': podefaltarQuinta,
      'podefaltarSexta': podefaltarSexta,
      'materiasSegunda': materiasSegunda,
      'materiasTerca': materiasTerca,
      'materiasQuarta': materiasQuarta,
      'materiasQuinta': materiasQuinta,
      'materiasSexta': materiasSexta,
    };
  }

  String getMateriasDoDia(int diaSemana) {
    switch (diaSemana) {
      case 1:
        return materiasSegunda.join(', ');
      case 2:
        return materiasTerca.join(', ');
      case 3:
        return materiasQuarta.join(', ');
      case 4:
        return materiasQuinta.join(', ');
      case 5:
        return materiasSexta.join(', ');
      default:
        return 'Nenhuma matéria hoje';
    }
  }

  dynamic getFaltasRestantes(int diaSemana) {
    switch (diaSemana) {
      case 1:
        return podefaltarSegunda;
      case 2:
        return podefaltarTerca;
      case 3:
        return podefaltarQuarta;
      case 4:
        return podefaltarQuinta;
      case 5:
        return podefaltarSexta;
      default:
        return 'Indefinido';
    }
  }
}
