import 'package:flutter/foundation.dart';
import '../models/login_model.dart';
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
      
      final cookie = await apiService.login(loginData);
      final cookieModel = CookieModel(
        cookie: cookie,
        dataCriacao: DateTime.now(),
      );
      
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
  
  Future<void> logout() async {
    await _storageService.removeCookie();
    _isLoggedIn = false;
    notifyListeners();
  }
  
  // Obter o serviço de API atual
  ApiInterface get apiService => _apiFactory.getApi();

  Future<String?> getCookie() async {
    final cookie = await _storageService.getCookie();
    if (cookie != null && cookie.isValid()) {
      return cookie.cookie;
    }
    
    // Se o cookie não for válido, tenta fazer login novamente
    final login = await _storageService.getLogin();
    if (login != null) {
      try {
        final newCookie = await apiService.login(login);
        final cookieModel = CookieModel(
          cookie: newCookie,
          dataCriacao: DateTime.now(),
        );
        
        await _storageService.saveCookie(cookieModel);
        return newCookie;
      } catch (e) {
        _error = e.toString();
        _isLoggedIn = false;
        notifyListeners();
        return null;
      }
    }
    
    return null;
  }
}
