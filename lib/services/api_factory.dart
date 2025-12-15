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

  // Instância única da API (mantém estado como cookies)
  ApiInterface? _apiInstance;

  // Getter para a flag de mock
  bool get useMock => _useMock;

  // Setter para a flag de mock
  set useMock(bool value) {
    if (_useMock != value) {
      _useMock = value;
      // invalidar instância para trocar implementação
      _apiInstance = null;
    }
  }

  // Retorna a implementação apropriada da API
  ApiInterface getApi() {
    if (_apiInstance != null) return _apiInstance!;
    if (_useMock) {
      _apiInstance = MockApiService();
    } else {
      _apiInstance = ApiService();
    }
    return _apiInstance!;
  }
}
