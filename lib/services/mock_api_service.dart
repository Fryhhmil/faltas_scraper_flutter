import 'dart:async';
import '../models/login_model.dart';
import '../models/falta_model.dart';
import '../models/horario_model.dart';
import 'api_interface.dart';
import 'mock_data.dart';

/// Implementação mock do serviço de API para testes
class MockApiService implements ApiInterface {
  // Simula um atraso de rede
  final Duration _delay = const Duration(milliseconds: 800);

  @override
  Future<String> login(LoginModel loginData) async {
    // Simula um atraso de rede
    await Future.delayed(_delay);
    
    // Verifica se o login é válido
    if (MockData.isValidLogin(loginData)) {
      return MockData.mockCookie;
    } else {
      throw Exception('Credenciais inválidas');
    }
  }

  @override
  Future<List<FaltaModel>> buscarFaltas(String cookie) async {
    // Simula um atraso de rede
    await Future.delayed(_delay);
    
    // Verifica se o cookie é válido
    if (cookie == MockData.mockCookie) {
      return MockData.mockFaltas;
    } else {
      throw Exception('Cookie inválido');
    }
  }

  @override
  Future<HorarioAlunoModel> buscarHorario(String cookie) async {
    // Simula um atraso de rede
    await Future.delayed(_delay);
    
    // Verifica se o cookie é válido
    if (cookie == MockData.mockCookie) {
      return MockData.mockHorario;
    } else {
      throw Exception('Cookie inválido');
    }
  }
}
