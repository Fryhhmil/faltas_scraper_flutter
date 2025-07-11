import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/falta_model.dart';
import '../models/horario_model.dart';
import '../services/api_factory.dart';
import '../services/api_interface.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

class DataProvider with ChangeNotifier {
  final ApiFactory _apiFactory = ApiFactory();
  final StorageService _storageService = StorageService();
  final AuthProvider _authProvider;
  
  List<FaltaModel> _faltas = [];
  HorarioAlunoModel? _horario;
  bool _isLoading = false;
  String? _error;
  
  List<FaltaModel> get faltas => _faltas;
  HorarioAlunoModel? get horario => _horario;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  DataProvider(this._authProvider) {
    _loadData();
  }
  
  // Obter o serviço de API atual
  ApiInterface get apiService => _apiFactory.getApi();
  
  Future<void> _loadData() async {
    _faltas = await _storageService.getFaltas();
    _horario = await _storageService.getHorario();
    notifyListeners();
  }
  
  Future<void> refreshData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {      
      final cookie = await _authProvider.getCookie();
      if (cookie == null) {
        _error = 'Não foi possível obter o cookie. Faça login novamente.';
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      await _fetchFaltas(cookie);
      await _fetchHorario(cookie);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _fetchFaltas(String cookie) async {
    try {
      final faltas = await apiService.buscarFaltas(cookie);
      
      // Log dos dados de faltas
      print('\n=== Dados de Faltas ===');
      for (var falta in faltas) {
        print('Matéria: ${falta.nomeMateria}');
        print('Faltas: ${falta.faltas}');
        print('Pode Faltar: ${falta.podeFaltar}');
        print('Percentual: ${falta.percentual}%');
        print('------------------------');
      }
      
      _faltas = faltas;
      await _storageService.saveFaltas(faltas);
    } catch (e) {
      _error = 'Erro ao buscar faltas: ${e.toString()}';
      throw e;
    }
  }
  
  Future<void> _fetchHorario(String cookie) async {
    try {
      final horario = await apiService.buscarHorario(cookie);
      
      // Log dos dados do horário
      print('\n=== Dados do Horário ===');
      print('Segunda-feira: ${horario.materiasSegunda.join(', ')}');
      print('Pode faltar Segunda: ${horario.podefaltarSegunda}');
      print('Terça-feira: ${horario.materiasTerca.join(', ')}');
      print('Pode faltar Terça: ${horario.podefaltarTerca}');
      print('Quarta-feira: ${horario.materiasQuarta.join(', ')}');
      print('Pode faltar Quarta: ${horario.podefaltarQuarta}');
      print('Quinta-feira: ${horario.materiasQuinta.join(', ')}');
      print('Pode faltar Quinta: ${horario.podefaltarQuinta}');
      print('Sexta-feira: ${horario.materiasSexta.join(', ')}');
      print('Pode faltar Sexta: ${horario.podefaltarSexta}');
      
      _horario = horario;
      await _storageService.saveHorario(horario);
    } catch (e) {
      _error = 'Erro ao buscar horário: ${e.toString()}';
      throw e;
    }
  }
  
  // Calcula o percentual de faltas para uma matéria específica
  double getPercentualFaltas(String materia) {
    final falta = _faltas.firstWhere(
      (f) => f.nomeMateria == materia,
      orElse: () => FaltaModel(
        nomeMateria: materia,
        faltas: 0,
        podeFaltar: 0,
        percentual: 0.0,
      ),
    );
    
    return falta.percentual;
  }
  
  // Retorna o status visual baseado no percentual de faltas
  Color getStatusColor(double percentual) {
    if (percentual <= 33) return Colors.green;
    if (percentual <= 66) return Colors.orange;
    return Colors.red;
  }
  
  // Retorna todas as matérias únicas do horário
  List<String> getMaterias() {
    final todasMaterias = [
      ...(_horario?.materiasSegunda ?? []).cast<String>(),
      ...(_horario?.materiasTerca ?? []).cast<String>(),
      ...(_horario?.materiasQuarta ?? []).cast<String>(),
      ...(_horario?.materiasQuinta ?? []).cast<String>(),
      ...(_horario?.materiasSexta ?? []).cast<String>(),
    ];
    return todasMaterias.toSet().toList();
  }
  
  String getDiaAtual() {
    final hoje = DateTime.now().weekday;
    switch (hoje) {
      case 1:
        return 'Segunda-feira';
      case 2:
        return 'Terça-feira';
      case 3:
        return 'Quarta-feira';
      case 4:
        return 'Quinta-feira';
      case 5:
        return 'Sexta-feira';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Indefinido';
    }
  }
  
  String getMateriasHoje() {
    if (_horario == null) return 'Indefinido';
    
    final hoje = DateTime.now().weekday;
    return _horario!.getMateriasDoDia(hoje);
  }
  
  List<Map<String, dynamic>> getFaltasRestantesHoje() {
    if (_horario == null || _faltas.isEmpty) return [];
    
    final hoje = DateTime.now().weekday;
    final materiasHoje = _horario!.getMateriasDoDia(hoje);
    
    if (materiasHoje == 'Nenhuma matéria hoje') return [];
    
    // Lista para armazenar as faltas restantes de cada matéria
    final List<Map<String, dynamic>> faltasRestantes = [];
    
    // Divide a string em uma lista de matérias
    final materiasLista = materiasHoje.split(', ');
    
    // Para cada matéria do dia, encontrar suas faltas
    for (String materia in materiasLista) {
      final falta = _faltas.firstWhere(
        (f) => f.nomeMateria == materia,
        orElse: () => FaltaModel(
          nomeMateria: materia,
          faltas: 0,
          podeFaltar: 0,
          percentual: 0.0,
        ),
      );
      
      // Calcular faltas restantes
      final faltasRestantesNum = falta.podeFaltar - falta.faltas;
      
      faltasRestantes.add({
        'materia': materia,
        'faltasRestantes': faltasRestantesNum,
        'percentual': falta.percentual,
        'podeFaltar': falta.podeFaltar,
      });
    }
    
    return faltasRestantes;
  }
  
  // Retorna quantas faltas o usuário pode ter hoje
  int getPodeFaltarHoje() {
    if (_horario == null) return 0;
    
    final hoje = DateTime.now().weekday;
    
    // Sábado (6) e Domingo (7) não têm aulas
    if (hoje > 5) return 0;
    
    return _horario!.getFaltasRestantes(hoje);
  }
}
