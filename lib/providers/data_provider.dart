import 'package:flutter/foundation.dart';
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
      _horario = horario;
      await _storageService.saveHorario(horario);
    } catch (e) {
      _error = 'Erro ao buscar horário: ${e.toString()}';
      throw e;
    }
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
  
  Map<String, int> getFaltasRestantesHoje() {
    if (_horario == null) return {};
    
    final hoje = DateTime.now().weekday;
    final materiasDoDia = _horario!.getMateriasDoDia(hoje);
    final materias = materiasDoDia.split(',').map((m) => m.trim()).toList();
    
    // Calcular faltas restantes por matéria
    final faltasRestantesPorMateria = <String, int>{};
    final materiasSemFaltas = <String>[];
    
    for (final falta in _faltas) {
      if (materias.contains(falta.nomeMateria)) {
        // Subtrair o número de faltas permitidas do total de faltas
        final faltasRestantes = falta.podeFaltar - falta.faltas;
        if (faltasRestantes > 0) {
          faltasRestantesPorMateria[falta.nomeMateria] = faltasRestantes;
        } else {
          materiasSemFaltas.add(falta.nomeMateria);
        }
      }
    }
    
    // Adicionar matérias sem faltas restantes com valor 0
    for (final materia in materiasSemFaltas) {
      faltasRestantesPorMateria[materia] = 0;
    }
    
    return faltasRestantesPorMateria;
  }
}
