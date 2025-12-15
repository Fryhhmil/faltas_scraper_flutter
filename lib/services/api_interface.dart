import '../models/login_model.dart';
import '../models/falta_model.dart';
import '../models/horario_model.dart';
import '../models/contexto_aluno.dart';

/// Interface para serviços de API
abstract class ApiInterface {
  /// Compatibilidade: método histórico que retorna cookie (mantido)
  Future<String> login(LoginModel loginData);

  /// Novo fluxo dividido
  Future<void> autenticar(LoginModel loginData);
  Future<List<ContextoAluno>> buscarContextos();
  Future<String> selecionarContexto(ContextoAluno ctx);

  Future<List<FaltaModel>> buscarFaltas(String cookie);
  Future<HorarioAlunoModel> buscarHorario(String cookie);
}
