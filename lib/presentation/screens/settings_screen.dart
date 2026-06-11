import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(children: [
        const ListTile(
          leading: Icon(Icons.dark_mode, color: AppColors.accent),
          title: Text('Tema', style: TextStyle(color: AppColors.text)),
          subtitle: Text('Escuro', style: TextStyle(color: AppColors.text2)),
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text('Sair', style: TextStyle(color: AppColors.error)),
          onTap: () => context.read<AuthProvider>().logout(),
        ),
        const AboutListTile(
          icon: Icon(Icons.info_outline, color: AppColors.text2),
          applicationName: 'Faltas iCEV',
          applicationVersion: '2.0.0',
          child: Text('Sobre', style: TextStyle(color: AppColors.text)),
        ),
      ]),
    );
  }
}
