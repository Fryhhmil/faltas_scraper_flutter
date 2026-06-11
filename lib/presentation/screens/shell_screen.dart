import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/academic_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/period_sheet.dart';
import 'dashboard_screen.dart';
import 'notas_screen.dart';
import 'faltas_screen.dart';
import 'horario_screen.dart';
import 'settings_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _idx = 0;
  static const _titulos = ['Início', 'Notas', 'Faltas', 'Horário'];
  final _telas = const [
    DashboardScreen(),
    NotasScreen(),
    FaltasScreen(),
    HorarioScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final academic = context.read<AcademicProvider>();
      final auth = context.read<AuthProvider>();
      // Entrega o contexto/período persistido ao provider acadêmico.
      if (auth.contexto != null) academic.setContexto(auth.contexto!);
      await academic.loadFromCache();
      await academic.refresh();
    });
  }

  Future<void> _abrirPeriodo() async {
    final auth = context.read<AuthProvider>();
    final academic = context.read<AcademicProvider>();
    final contextos = await auth.fetchContextos();
    if (!mounted || contextos.isEmpty) return;
    final escolhido = await showPeriodSheet(context, contextos, auth.contexto);
    if (escolhido == null) return;
    await auth.trocarContexto(escolhido);
    academic.setContexto(escolhido);
    await academic.loadFromCache();
    await academic.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_idx]),
        actions: [
          if (p.contexto != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: ActionChip(
                  onPressed: _abrirPeriodo,
                  backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                  side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.25)),
                  label: Text('${p.contexto!.nomePeriodo} ▾',
                      style: const TextStyle(
                          color: AppColors.accent, fontSize: 12)),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _telas[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Notas'),
          NavigationDestination(
              icon: Icon(Icons.trending_down_outlined), label: 'Faltas'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), label: 'Horário'),
        ],
      ),
    );
  }
}
