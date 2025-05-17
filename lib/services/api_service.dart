import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_model.dart';
import '../models/falta_model.dart';
import '../models/horario_model.dart';
import 'api_interface.dart';

class ApiService implements ApiInterface {
  static const String baseUrl = 'http://totvsscrap.ddns.net:8080'; // Substitua pela URL do seu backend

  @override
  Future<String> login(LoginModel loginData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(loginData.toJson()),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Falha no login: ${response.statusCode}');
    }
  }

  @override
  Future<List<FaltaModel>> buscarFaltas(String cookie) async {
    final response = await http.post(
      Uri.parse('$baseUrl/buscar-faltas'),
      headers: {'Content-Type': 'application/json'},
      body: cookie,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FaltaModel.fromJson(json)).toList();
    } else if (response.statusCode == 406) {
      throw Exception('Cookie inválido');
    } else {
      throw Exception('Falha ao buscar faltas: ${response.statusCode}');
    }
  }

  @override
  Future<HorarioAlunoModel> buscarHorario(String cookie) async {
    final response = await http.post(
      Uri.parse('$baseUrl/buscar-horario'),
      headers: {'Content-Type': 'application/json'},
      body: cookie,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return HorarioAlunoModel.fromJson(data);
    } else if (response.statusCode == 406) {
      throw Exception('Cookie inválido');
    } else {
      throw Exception('Falha ao buscar horário: ${response.statusCode}');
    }
  }
}
