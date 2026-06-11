import 'package:flutter/foundation.dart';
import '../../data/models/credenciais.dart';
import '../../data/models/contexto_aluno.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

class AuthProvider with ChangeNotifier {
  final AuthRepository _repo;
  AuthProvider(this._repo);

  AuthStatus _status = AuthStatus.unknown;
  bool _loading = false;
  String? _error;
  ContextoAluno? _contexto;

  AuthStatus get status => _status;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _status == AuthStatus.loggedIn;
  ContextoAluno? get contexto => _contexto;

  Future<void> restore() async {
    if (await _repo.hasStoredSession()) {
      _status = AuthStatus.loggedIn;
      _contexto = await _repo.getSelectedContexto();
    } else {
      _status = AuthStatus.loggedOut;
    }
    notifyListeners();
  }

  Future<bool> login(String cpf, String senha) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _repo.login(Credenciais(cpf: cpf.trim(), senha: senha));
      _contexto = await _repo.getSelectedContexto();
      _status = AuthStatus.loggedIn;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Não foi possível entrar. Verifique CPF e senha.';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Lista contextos/períodos disponíveis (para o bottom sheet).
  Future<List<ContextoAluno>> fetchContextos() => _repo.buscarContextos();

  /// Troca o período/contexto e persiste. Retorna o novo contexto.
  Future<ContextoAluno> trocarContexto(ContextoAluno ctx) async {
    await _repo.selecionarContexto(ctx);
    _contexto = ctx;
    notifyListeners();
    return ctx;
  }

  Future<void> logout() async {
    await _repo.logout();
    _contexto = null;
    _status = AuthStatus.loggedOut;
    notifyListeners();
  }
}
