class LoginModel {
  final String cpf;
  final String senha;

  LoginModel({
    required this.cpf,
    required this.senha,
  });

  Map<String, dynamic> toJson() {
    return {
      'cpf': cpf,
      'senha': senha,
    };
  }

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      cpf: json['cpf'] as String,
      senha: json['senha'] as String,
    );
  }
}

class CookieModel {
  final String cookie;
  final DateTime dataCriacao;

  CookieModel({
    required this.cookie,
    required this.dataCriacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'cookie': cookie,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory CookieModel.fromJson(Map<String, dynamic> json) {
    return CookieModel(
      cookie: json['cookie'] as String,
      dataCriacao: DateTime.parse(json['dataCriacao'] as String),
    );
  }

  bool isValid() {
    final agora = DateTime.now();
    final limite = dataCriacao.add(const Duration(minutes: 5));
    return agora.isBefore(limite);
  }
}
