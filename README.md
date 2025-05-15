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

## Executando o Aplicativo

1. Certifique-se de ter o Flutter instalado em seu sistema
2. Clone este repositório
3. Instale as dependências:
   ```
   flutter pub get
   ```
4. Execute o aplicativo:
   ```
   flutter run
   ```
