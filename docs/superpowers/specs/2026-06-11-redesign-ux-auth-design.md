# Redesign UX + Re-arquitetura de Autenticação — Faltas iCEV

**Data:** 2026-06-11
**App:** `faltas_scraper_flutter` (consulta de Notas, Faltas, Horários, Disciplinas e Períodos no Portal Educacional TOTVS RM)

---

## 1. Objetivo

Transformar o app num produto com cara de Play Store: tema **dark premium**, navegação por abas, telas focadas em cards, e — prioridade #1 — **autenticação confiável** com reautenticação automática, eliminando o "logout involuntário".

Prioridades (nesta ordem): 1) confiabilidade do login · 2) experiência visual · 3) leitura de notas · 4) leitura de faltas · 5) performance · 6) manutenibilidade.

---

## 2. Problemas encontrados (análise do código atual)

### 2.1 Causa raiz do logout involuntário
- **Cookie "expira" em 5 min no cliente:** `CookieModel.isValid()` = `dataCriacao + 5 minutos`. Após isso o cookie salvo é descartado.
- **Cookies só vivem em memória:** `ApiService._cookieMap` é um `Map` em memória. Ao **reiniciar o app** ele zera. O cookie persistido (string concatenada em `CookieModel`) **nunca é reaplicado** às requisições — `buscarFaltas(cookie)` **ignora o parâmetro** e lê o `_cookieMap`. Logo, reabrir o app = sem sessão.
- **Sem detecção de expiração de sessão:** não há interceptação de 401/403/redirect-para-login para disparar re-login transparente. `ASP.NET_SessionId`/`.ASPXAUTH` expiram no servidor por inatividade e nada se recupera.
- **Re-login frágil:** existe um caminho parcial (`getCookie()` re-autentica com login+contexto salvos), mas refaz o login inteiro toda vez e depende de credenciais inseguras.

### 2.2 Segurança
- CPF e **senha** gravados em **texto plano** no SharedPreferences (`login_data`).
- `print()` despejando **cookies e credenciais** no console.

### 2.3 UX / código
- Home só mostra **uma tabela de faltas**; "card de hoje" e "progress bars" estão comentados (código morto).
- **Notas e Horário não existem** (horário aponta para backend antigo `totvsscrap.ddns.net`, desativado).
- Seleção de período = `AlertDialog` com `DropdownButton` cru.
- `device_preview` ligado fora de produção.
- Visual claro, corporativo, sem hierarquia.

---

## 3. Endpoints reais (do PDF "TOTVS RM - Endpoints Mapeados")

Base: `https://grupoeducacional127611.rm.cloudtotvs.com.br`

| Recurso | Método | Path |
|---|---|---|
| Login | POST | `/Corpore.Net/Source/EDU-EDUCACIONAL/Public/EduPortalAlunoLogin.aspx?AutoLoginType=ExternalLogin` (body `User`,`Pass`,`Alias=CorporeRM`) |
| Notas | GET | `/FrameHTML/RM/API/TOTVSEducacional/NotaEtapa` |
| Disciplinas | GET | `/FrameHTML/RM/API/TOTVSEducacional/DisciplinasAlunoPeriodoLetivo?mostraApenasDiscEmCurso=false` |
| Horário | GET | `/FrameHTML/RM/API/TOTVSEducacional/QuadroHorarioAluno` |
| Faltas | GET | `/FrameHTML/RM/API/TOTVSEducacional/FaltaEtapa` (já em uso) |
| Contexto | GET/POST | `/FrameHTML/RM/API/TOTVSEducacional/Contexto[/Selecao]` (mantém fluxo atual que funciona) |

**Cookies obrigatórios:** `ASP.NET_SessionId`, `RMAuthForm`, `.ASPXAUTH`, `CorporePrincipal`, `EduContextoAlunoResponsavelAPI`, `DefaultAlias`.

**Formatos relevantes:**
- `NotaEtapa` → `data.Notas[]`: `DISCIPLINA`, `SITUACAO`, `IDTURMADISC`, e `"1 - P1"`…`"6 - MÉDIA FINAL"` (strings `"8,50"` com vírgula, ou `null`; podem vir embrulhadas em `<font color=red>…</font>`).
- `DisciplinasAlunoPeriodoLetivo` → `data[]`: `NOME`, `DESCRICAO` (status), `CODDISC`, `IDPERLET`.
- `QuadroHorarioAluno` → `data.SHorarioAluno[]`: `DIASEMANA` (1=Dom…7=Sáb), `HORAINICIAL`, `HORAFINAL`, `NOME`, `SALA`/`PREDIO`/`BLOCO`, `URLAULAONLINE`.

---

## 4. Decisões (confirmadas)

| Tema | Decisão |
|---|---|
| Dados Notas/Horário | Parsers **reais** sobre os JSONs do PDF |
| Arquitetura | Camada **pragmática**: `core / data / presentation` + Repositories + interceptor (sem use-cases redundantes) |
| Stack HTTP | Migrar para **`dio` + `cookie_jar`** (interceptors nativos + persistência de cookie) |
| Storage sensível | **`flutter_secure_storage`** para credenciais e cookies |
| Navegação | **Bottom navigation**: Início · Notas · Faltas · Horário (Configurações no app bar) |
| Dashboard | Layout **B**: card-herói com **anel da média** + métricas (faltas, disciplinas, situação) + próximas aulas + risco de faltas |
| Notas | Card por disciplina; chips P1/P2/P3/Final; chip de média colorido por faixa; parsing de `<font>`; empty state |
| Faltas | Barra de progresso; card muda de cor (verde→amarelo→vermelho); **percentual calculado sobre o limite legal de 25%** |
| Período | Seletor moderno (bottom sheet) no app bar; troca recarrega tudo com cache |

---

## 5. Arquitetura alvo

```
lib/
├─ core/
│  ├─ theme/          # AppColors (paleta), AppTheme (dark M3), text styles
│  ├─ network/        # DioClient, AuthInterceptor, PersistCookieJar setup
│  ├─ utils/          # nota_parser (HTML <font>, vírgula→double), result/erros
│  └─ constants/      # endpoints, chaves de storage
├─ data/
│  ├─ models/         # NotaDisciplina, FaltaDisciplina, AulaHorario, Disciplina, PeriodoLetivo, ContextoAluno, Credenciais
│  ├─ datasources/    # RmApiDataSource (chamadas dio), SecureStorageDataSource
│  └─ repositories/   # AuthRepository, AcademicRepository
├─ presentation/
│  ├─ providers/      # AuthProvider, AcademicProvider, PeriodoProvider
│  ├─ screens/        # login, shell(bottom nav), dashboard, notas, faltas, horario, settings
│  └─ widgets/        # cards, chips, progress, skeletons, empty states, period_sheet
└─ main.dart
```

**Princípios:** cada Repository expõe interface clara; Providers só orquestram estado de UI; widgets reutilizáveis e pequenos; sem regra de negócio em telas.

---

## 6. Sistema de autenticação (núcleo da entrega)

### 6.1 CookieManager (sobre `cookie_jar`)
- `PersistCookieJar` apontando para diretório do app → cookies sobrevivem a restart.
- Persistência espelhada no `flutter_secure_storage` para os cookies sensíveis.
- API: `loadCookies()`, `saveFromResponse()`, `clear()`, `hasSession()`.

### 6.2 AuthRepository
- `login(cpf, senha)` → executa fluxo RM (POST login → AutoLoginPortal key → Contexto/Selecao), persiste cookies + credenciais (secure).
- `logout()` → limpa cookies + credenciais + contexto.
- `restoreSession()` → carrega cookies persistidos no boot; sem re-login se válidos.
- `refreshSession()` → re-executa login com credenciais salvas e atualiza cookies.
- `isLoggedIn` → existe sessão/credenciais.

### 6.3 AuthInterceptor (dio)
Fluxo de auto-recuperação:
1. Requisição falha por sessão inválida — **detecção**: HTTP 401/403, **ou** redirect 302 para `*Login.aspx`, **ou** corpo HTML de login em vez de JSON.
2. Interceptor pausa, chama `AuthRepository.refreshSession()` (com **lock**/single-flight para não disparar N logins em paralelo).
3. Atualiza cookies no jar.
4. **Reexecuta a requisição original** uma vez.
5. Se ainda falhar → propaga erro de "sessão expirada, faça login" (raro).
6. Usuário **nunca** precisa deslogar manualmente.

### 6.4 Remoções
- Apagar a regra dos 5 min (`CookieModel.isValid`), o `_cookieMap` em memória e os `print()` de credenciais.

---

## 7. Telas

- **Login:** dark, CPF + senha, validação, loading, mensagem de erro elegante; "lembrar" implícito (sessão persistida).
- **Shell:** `Scaffold` com `NavigationBar` (M3) e 4 abas; app bar com chip de **período** + ícone de configurações.
- **Dashboard (Início):** card-herói anel da média geral; métricas (total de faltas, nº disciplinas, situação); **próximas aulas de hoje**; **risco de reprovação por falta** (disciplinas no amarelo/vermelho). Skeleton + pull-to-refresh.
- **Notas:** lista de cards por disciplina; chips P1/P2/P3/Final; chip de média colorido (verde ≥7 / amarelo 5–6,9 / vermelho <5); empty state "sem notas lançadas"; parsing de `<font color>`.
- **Faltas:** card por disciplina com barra de progresso; **percentual = faltas / (25% da carga) × 100**; verde <70% do limite, amarelo 70–99%, vermelho ≥100%; texto "X de Y faltas · faltam Z".
- **Horário:** visão agenda; alternância **Hoje / Semana**; agrupado por dia da semana; mostra horário, disciplina, sala (quando houver).
- **Período letivo:** **bottom sheet** moderno listando períodos; ao trocar, recarrega Notas/Faltas/Horário com **cache** por período.
- **Configurações:** tema (dark fixo nesta entrega), logout, sobre.

---

## 8. Design system

- **Paleta:** bg `#0D1117` · card `#161B22` · card2 `#1C2128` · destaque `#58A6FF` · sucesso `#3FB950` · alerta `#D29922` · erro `#F85149` · texto `#F0F6FC` · texto2 `#8B949E`.
- Material 3, `ColorScheme.dark` derivado da paleta; cantos 14px; bordas sutis `#21262d`.
- Componentes: `StatCard`, `RingGauge`, `NotaCard`, `FaltaCard`, `AulaTile`, `StatusChip`, `ProgressBar`, `SkeletonLoader` (shimmer), `EmptyState`.
- Microanimações suaves (AnimatedSwitcher/implicit animations); pull-to-refresh; skeletons no primeiro load.

---

## 9. Performance & cache

- Cache local por período (SharedPreferences/secure) com timestamp; **stale-while-revalidate**: mostra cache na hora e atualiza em background.
- Carregar dados das abas sob demanda (lazy) + reaproveitar entre Dashboard e telas.
- Evitar chamadas repetidas: um `AcademicRepository` com cache em memória + persistido.

## 10. Dependências a adicionar
`dio`, `cookie_jar` + `dio_cookie_manager`, `flutter_secure_storage`, `fl_chart` (anel/gráficos), `shimmer` (skeleton), `html` ou parser próprio leve (decodificar `<font>`/entidades). Remover dependência efetiva de `android_alarm_manager_plus`/notificações desta entrega (código já comentado) — **fora de escopo**.

## 11. Fora de escopo (YAGNI nesta entrega)
- Notificações/alarmes de falta.
- iOS/web/desktop (foco Android).
- Tema claro (dark fixo).
- Atualização de AGP/Kotlin (apenas anotar).

## 12. Critérios de sucesso
1. Reabrir o app após horas **não** exige novo login; expiração de sessão se recupera sozinha (interceptor) sem o usuário deslogar.
2. Credenciais/cookies só em `flutter_secure_storage`; nenhum `print` de dado sensível.
3. Notas, Faltas, Horário e Dashboard funcionando com dados reais do RM, no tema dark aprovado.
4. Parser de notas lida com `<font color=red>4,00</font>`, vírgula decimal e `null`.
5. `flutter analyze` sem warnings; arquitetura em `core/data/presentation`.
```
