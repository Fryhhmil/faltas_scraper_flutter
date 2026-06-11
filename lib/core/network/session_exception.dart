/// Lançada quando a sessão está inválida e não foi possível recuperar.
class SessionExpiredException implements Exception {
  final String message;
  const SessionExpiredException([this.message = 'Sessão expirada']);
  @override
  String toString() => 'SessionExpiredException: $message';
}

/// Erro genérico de rede/API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}
