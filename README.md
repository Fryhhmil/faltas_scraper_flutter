# Faltas Scraper Flutter

Aplicativo Flutter Faltas Scraper

## Sobre o Projeto

Este aplicativo permite aos estudantes visualizar suas faltas e informações sobre horários de aulas. O aplicativo inclui:

- Sistema de login
- Visualização de faltas por disciplina
- Informações sobre horários e disciplinas do dia
- Armazenamento local de dados

## Estrutura do Projeto

```
lib/
├── models/           # Modelos de dados
├── providers/        # Gerenciamento de estado
├── screens/          # Telas do aplicativo
├── services/         # Serviços (API, armazenamento)
├── widgets/          # Widgets reutilizáveis
├── routes.dart       # Configuração de rotas
└── main.dart         # Ponto de entrada do aplicativo
```

## Configuração

Antes de executar o aplicativo, certifique-se de atualizar a URL base da API no arquivo `lib/services/api_service.dart`.

## Pré-requisitos

- **Flutter** 3.38+ (canal stable) e Dart 3.10+ — confira com `flutter --version`
- **Android SDK** + um emulador (AVD) ou um aparelho Android físico com depuração USB

> **Importante:** o app é **Android-only**. Ele usa `dart:io` (`lib/services/api_service.dart`)
> e o plugin `android_alarm_manager_plus`, então **não roda na Web**. No **Windows desktop**
> só roda se o *Modo de Desenvolvedor* do Windows estiver ativado (necessário para symlinks).

## Executando o Aplicativo (Android)

1. Instale as dependências:
   ```bash
   flutter pub get
   ```
2. Suba um emulador Android (ou conecte um aparelho). Liste os disponíveis:
   ```bash
   flutter emulators
   flutter emulators --launch <id_do_emulador>
   ```
3. Confirme que o dispositivo está online:
   ```bash
   flutter devices
   ```
4. Rode o app:
   ```bash
   flutter run
   # ou, para um dispositivo específico:
   flutter run -d emulator-5554
   ```

### ⚠️ Emulador travando no boot (GPUs AMD / API > 35)

Em máquinas com **GPU AMD** (ex.: RX 9070 XT) e imagens de **API > 35**, o emulador pode
ficar preso em `device offline` (boot que nunca completa) no modo de GPU padrão (`auto`/`host`),
por instabilidade do ANGLE/Vulkan do convidado.

Solução: forçar o renderizador de GPU. Lance o emulador manualmente assim:

```bash
# Caminho típico do emulator.exe no Windows:
# %LOCALAPPDATA%\Android\Sdk\emulator\emulator.exe

# Rápido (aceleração via DirectX 11) — recomendado para GPUs AMD no Windows:
emulator -avd <nome_avd> -gpu angle_indirect -no-snapshot-load -no-boot-anim

# Fallback garantido (software, mais lento) — se o de cima ainda travar:
emulator -avd <nome_avd> -gpu swiftshader_indirect -no-snapshot-load -wipe-data
```

Depois que `flutter devices` mostrar o emulador como `device` (não `offline`),
rode `flutter run` normalmente.

## Buildando o Aplicativo

```bash
# APK de debug (para testes locais):
flutter build apk --debug

# APK de release (para distribuir):
flutter build apk --release

# App Bundle para a Play Store:
flutter build appbundle --release
```

Os artefatos ficam em `build/app/outputs/flutter-apk/` (APK) e
`build/app/outputs/bundle/release/` (AAB).

Para instalar um APK já buildado num dispositivo conectado:
```bash
flutter install
# ou via adb:
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## Testando após alterar o código

**Hot reload (fluxo do dia a dia):** com `flutter run` ativo num terminal, após editar o
código basta pressionar:
- **`r`** — *hot reload* (aplica a mudança mantendo o estado da tela)
- **`R`** — *hot restart* (reinicia o app do zero, perde o estado)
- **`q`** — encerra a sessão

**Verificação estática** (sem rodar o app — rápido, pegue erros antes):
```bash
flutter analyze          # lint + erros de análise
dart format .            # formata o código
```

**Testes automatizados:**
```bash
flutter test             # roda os testes em test/
```

**Validação manual completa** (quando mudar algo que afeta build/instalação):
```bash
flutter run -d emulator-5554   # build + instala + abre, e observe a tela
```

> Dica: para testar mudanças que não dependem da API real, há uma API *mockada*
> (`lib/services/mock_api_service.dart`) que pode ser ativada via `AuthProvider.toggleMockApi(true)`.
