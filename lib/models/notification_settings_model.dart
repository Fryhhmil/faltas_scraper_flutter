class NotificationSettingsModel {
  final int atualizacaoHora;
  final int atualizacaoMinuto;
  final int lembreteHora;
  final int lembreteMinuto;
  final bool notificacoesAtivas;

  NotificationSettingsModel({
    required this.atualizacaoHora,
    required this.atualizacaoMinuto,
    required this.lembreteHora,
    required this.lembreteMinuto,
    required this.notificacoesAtivas,
  });

  // Valores padrão
  factory NotificationSettingsModel.defaultSettings() {
    return NotificationSettingsModel(
      atualizacaoHora: 22,
      atualizacaoMinuto: 30,
      lembreteHora: 13,
      lembreteMinuto: 0,
      notificacoesAtivas: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'atualizacaoHora': atualizacaoHora,
      'atualizacaoMinuto': atualizacaoMinuto,
      'lembreteHora': lembreteHora,
      'lembreteMinuto': lembreteMinuto,
      'notificacoesAtivas': notificacoesAtivas,
    };
  }

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      atualizacaoHora: json['atualizacaoHora'] as int? ?? 22,
      atualizacaoMinuto: json['atualizacaoMinuto'] as int? ?? 30,
      lembreteHora: json['lembreteHora'] as int? ?? 13,
      lembreteMinuto: json['lembreteMinuto'] as int? ?? 0,
      notificacoesAtivas: json['notificacoesAtivas'] as bool? ?? true,
    );
  }

  NotificationSettingsModel copyWith({
    int? atualizacaoHora,
    int? atualizacaoMinuto,
    int? lembreteHora,
    int? lembreteMinuto,
    bool? notificacoesAtivas,
  }) {
    return NotificationSettingsModel(
      atualizacaoHora: atualizacaoHora ?? this.atualizacaoHora,
      atualizacaoMinuto: atualizacaoMinuto ?? this.atualizacaoMinuto,
      lembreteHora: lembreteHora ?? this.lembreteHora,
      lembreteMinuto: lembreteMinuto ?? this.lembreteMinuto,
      notificacoesAtivas: notificacoesAtivas ?? this.notificacoesAtivas,
    );
  }

  String formatAtualizacao() {
    return '${atualizacaoHora.toString().padLeft(2, '0')}:${atualizacaoMinuto.toString().padLeft(2, '0')}';
  }

  String formatLembrete() {
    return '${lembreteHora.toString().padLeft(2, '0')}:${lembreteMinuto.toString().padLeft(2, '0')}';
  }
}
