import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/mock_data.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../models/notification_settings_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  
  NotificationSettingsModel? _settings;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settings = await _storageService.getNotificationSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }
  
  Future<void> _saveSettings() async {
    if (_settings != null) {
      await _storageService.saveNotificationSettings(_settings!);
      await _notificationService.reconfigurarNotificacoes();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações salvas com sucesso!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _selectTime(BuildContext context, bool isAtualizacao) async {
    if (_settings == null) return;
    
    final TimeOfDay initialTime = isAtualizacao
        ? TimeOfDay(hour: _settings!.atualizacaoHora, minute: _settings!.atualizacaoMinuto)
        : TimeOfDay(hour: _settings!.lembreteHora, minute: _settings!.lembreteMinuto);
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isAtualizacao) {
          _settings = _settings!.copyWith(
            atualizacaoHora: picked.hour,
            atualizacaoMinuto: picked.minute,
          );
        } else {
          _settings = _settings!.copyWith(
            lembreteHora: picked.hour,
            lembreteMinuto: picked.minute,
          );
        }
      });
      await _saveSettings();
    }
  }
  
  // Mostra o diálogo de confirmação de logout
  void _showLogoutConfirmationDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmação'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Fecha o diálogo
                authProvider.logout(); // Realiza o logout
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Modo de API',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Usar API Mockada'),
              subtitle: const Text(
                'Ativa dados de teste para desenvolvimento',
              ),
              value: authProvider.useMockApi,
              onChanged: (value) {
                authProvider.toggleMockApi(value);
              },
            ),
            const Divider(),
            if (authProvider.useMockApi) ...[
              const Text(
                'Dados de Login para Teste',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CPF: ${MockData.validLogin.cpf}'),
                      const SizedBox(height: 4),
                      Text('Senha: ${MockData.validLogin.senha}'),
                    ],
                  ),
                ),
              ),
            ],
            const Divider(),
            const Text(
              'Notificações',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SwitchListTile(
                      title: const Text('Notificações Ativas'),
                      subtitle: const Text('Ativar ou desativar todas as notificações'),
                      value: _settings?.notificacoesAtivas ?? true,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings?.copyWith(notificacoesAtivas: value);
                        });
                        _saveSettings();
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.update),
                      title: const Text('Atualização diária de faltas'),
                      subtitle: Text('Todos os dias às ${_settings?.formatAtualizacao() ?? "22:30"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _settings?.notificacoesAtivas ?? false
                            ? () => _selectTime(context, true)
                            : null,
                      ),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications_active),
                      title: const Text('Lembrete de faltas disponíveis'),
                      subtitle: Text('Todos os dias às ${_settings?.formatLembrete() ?? "13:00"}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _settings?.notificacoesAtivas ?? false
                            ? () => _selectTime(context, false)
                            : null,
                      ),
                      dense: true,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.notifications),
                      label: const Text('Testar Notificações'),
                      onPressed: _settings?.notificacoesAtivas ?? false
                          ? () {
                              NotificationService().mostrarNotificacaoTeste();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notificação de teste enviada!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                    ),
                  ]),
            const SizedBox(height: 32),
            const Divider(thickness: 1.5),
            const SizedBox(height: 16),
            // Botão de logout com fundo vermelho
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Sair da Conta',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showLogoutConfirmationDialog(context, authProvider),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
