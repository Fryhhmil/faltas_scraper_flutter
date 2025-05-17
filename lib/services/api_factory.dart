import 'api_interface.dart';
import 'api_service.dart';
import 'mock_api_service.dart';

/// Factory para criar instâncias de serviços de API
class ApiFactory {
  // Singleton
  static final ApiFactory _instance = ApiFactory._internal();
  factory ApiFactory() => _instance;
  ApiFactory._internal();

  // Flag para usar API mockada
  bool _useMock = false;

  // Getter para a flag de mock
  bool get useMock => _useMock;

  // Setter para a flag de mock
  set useMock(bool value) {
    _useMock = value;
  }

  // Retorna a implementação apropriada da API
  ApiInterface getApi() {
    if (_useMock) {
      return MockApiService();
    } else {
      return ApiService();
    }
  }
}
