import 'package:flutter/foundation.dart';
import '../models/login_model.dart';
import '../models/contexto_aluno.dart';
import '../services/api_factory.dart';
import '../services/api_interface.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiFactory _apiFactory = ApiFactory();
  final StorageService _storageService = StorageService();
  
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;
  
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get useMockApi => _apiFactory.useMock;
  
  AuthProvider() {
    _checkLoginStatus();
  }
  
  // Alterna entre API real e mockada
  void toggleMockApi(bool useMock) {
    if (_apiFactory.useMock != useMock) {
      _apiFactory.useMock = useMock;
      // Não reinicializamos o _apiService diretamente, apenas notificamos
      notifyListeners();
      // Atualizamos os dados se necessário
      _checkLoginStatus();
    }
  }
  
  Future<void> _checkLoginStatus() async {
    final cookie = await _storageService.getCookie();
    if (cookie != null && cookie.isValid()) {
      _isLoggedIn = true;
      notifyListeners();
    }
  }
  
  Future<bool> login(String cpf, String senha) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final loginData = LoginModel(cpf: cpf, senha: senha);
      await _storageService.saveLogin(loginData);

      // Apenas autentica (parcela inicial). Seleção de contexto é feita separadamente.
      await apiService.autenticar(loginData);

      _isLoggedIn = true; // permite navegar para a Home onde será escolhido o contexto
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await _storageService.removeCookie();
    await _storageService.removeSelectedContext();
    _isLoggedIn = false;
    notifyListeners();
  }
  
  // Obter o serviço de API atual
  ApiInterface get apiService => _apiFactory.getApi();

  Future<List<ContextoAluno>> fetchContextos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('[AuthProvider] fetchContextos() called');
      final list = await apiService.buscarContextos();
      print('[AuthProvider] fetchContextos() returned ${list.length} items');
      _isLoading = false;
      notifyListeners();
      return list;
    } catch (e) {
      print('[AuthProvider] fetchContextos() error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> selecionarContexto(ContextoAluno ctx) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

      try {
        final cookie = await apiService.selecionarContexto(ctx);
        // salva o contexto selecionado para pular a seleção futura
        await _storageService.saveSelectedContext(ctx);
        final cookieModel = CookieModel(cookie: cookie, dataCriacao: DateTime.now());
        await _storageService.saveCookie(cookieModel);

      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> getCookie() async {
    final cookie = await _storageService.getCookie();
    if (cookie != null && cookie.isValid()) {
      return cookie.cookie;
    }
    // Se o cookie não for válido, tenta usar contexto salvo + credenciais
    final savedContext = await _storageService.getSelectedContext();
    final login = await _storageService.getLogin();

    if (savedContext != null && login != null) {
      try {
        await apiService.autenticar(login);
        final newCookie = await apiService.selecionarContexto(savedContext);
        final cookieModel = CookieModel(cookie: newCookie, dataCriacao: DateTime.now());
        await _storageService.saveCookie(cookieModel);
        return newCookie;
      } catch (e) {
        _error = e.toString();
        _isLoggedIn = false;
        notifyListeners();
        return null;
      }
    }

    // Sem cookie salvo e sem contexto salvo, não tentar seleção automática
    return null;
  }
}
