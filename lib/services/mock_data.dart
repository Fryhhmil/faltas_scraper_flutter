import '../models/falta_model.dart';
import '../models/horario_model.dart';
import '../models/login_model.dart';

class MockData {
  // Dados mockados para login
  static final LoginModel validLogin = LoginModel(
    cpf: '12345678900',
    senha: '123',
  );

  // Cookie mockado
  static const String mockCookie = 'mock-cookie-value-12345';

  // Dados mockados
  static final List<FaltaModel> mockFaltas = [
    FaltaModel(
      nomeMateria: 'Ciência de Dados',
      faltas: 1, 
      podeFaltar: 4,
      percentual: double.parse(((2 / 36) * 100).toStringAsFixed(1)),
    ),
    FaltaModel(
      nomeMateria: 'Desenvolvimento Mobile',
      faltas: 4, 
      podeFaltar: 8, 
      percentual: double.parse(((8 / 72) * 100).toStringAsFixed(1)),
    ),
    FaltaModel(
      nomeMateria: 'Análise e Projeto de Algoritmos',
      faltas: 6, 
      podeFaltar: 8, 
      percentual: double.parse(((12 / 72) * 100).toStringAsFixed(1)),
    ),
    FaltaModel(
      nomeMateria: 'Redes',
      faltas: 8, 
      podeFaltar: 8, 
      percentual: double.parse(((18 / 72) * 100).toStringAsFixed(1)),
    ),
    FaltaModel(
      nomeMateria: 'Inglês',
      faltas: 0, 
      podeFaltar: 4, 
      percentual: double.parse(((0 / 36) * 100).toStringAsFixed(1)),
    ),
    FaltaModel(
      nomeMateria: 'Testes',
      faltas: 3, 
      podeFaltar: 4, 
      percentual: double.parse(((8 / 36) * 100).toStringAsFixed(1)),
    ),
  ];

  // Horário mockado
  static final HorarioAlunoModel mockHorario = HorarioAlunoModel(
    podefaltarSegunda: 3, // Ciência de Dados (1 aula) + Desenvolvimento Mobile (2 aulas)
    podefaltarTerca: 4, // Análise e Projeto de Algoritmos (2 aulas) + Inglês (1 aula) + Testes (1 aula)
    podefaltarQuarta: 2, // Desenvolvimento Mobile (2 aulas)
    podefaltarQuinta: 4, // Redes (2 aulas) + Análise e Projeto de Algoritmos (2 aulas)
    podefaltarSexta: 3, // Ciência de Dados (1 aula) + Redes (2 aulas)
    materiasSegunda: ['Ciência de Dados', 'Desenvolvimento Mobile'],
    materiasTerca: ['Análise e Projeto de Algoritmos', 'Inglês', 'Testes'],
    materiasQuarta: ['Desenvolvimento Mobile'],
    materiasQuinta: ['Redes', 'Análise e Projeto de Algoritmos'],
    materiasSexta: ['Ciência de Dados', 'Redes'],
  );

  static bool isValidLogin(LoginModel login) {
    return login.cpf == validLogin.cpf && login.senha == validLogin.senha;
  }
}
