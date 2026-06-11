/// URLs e paths do Portal RM.
class Endpoints {
  static const rmBase = 'https://grupoeducacional127611.rm.cloudtotvs.com.br';

  static const login =
      '$rmBase/Corpore.Net//Source/EDU-EDUCACIONAL/Public/EduPortalAlunoLogin.aspx?AutoLoginType=ExternalLogin';
  static const autoLogin = '$rmBase/FrameHTML/RM/API/user/AutoLoginPortal'; // ?key=
  static const contexto = '$rmBase/FrameHTML/RM/API/TOTVSEducacional/Contexto';
  static const contextoSelecao =
      '$rmBase/FrameHTML/RM/API/TOTVSEducacional/Contexto/Selecao';
  static const notaEtapa = '$rmBase/FrameHTML/RM/API/TOTVSEducacional/NotaEtapa';
  static const faltaEtapa = '$rmBase/FrameHTML/RM/API/TOTVSEducacional/FaltaEtapa';
  static const disciplinas =
      '$rmBase/FrameHTML/RM/API/TOTVSEducacional/DisciplinasAlunoPeriodoLetivo?mostraApenasDiscEmCurso=false';
  static const quadroHorario =
      '$rmBase/FrameHTML/RM/API/TOTVSEducacional/QuadroHorarioAluno';

  /// Marca de página de login (sessão expirada devolve HTML de login).
  static const loginPageMarker = 'EduPortalAlunoLogin.aspx';
}
