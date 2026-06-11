import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/aula_horario.dart';
import '../providers/academic_provider.dart';
import '../widgets/aula_tile.dart';
import '../widgets/empty_state.dart';

class HorarioScreen extends StatefulWidget {
  const HorarioScreen({super.key});
  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  bool _hoje = true;
  static const _dias = ['', 'Domingo', 'Segunda', 'Terça', 'Quarta', 'Quinta',
      'Sexta', 'Sábado'];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    final hojeRm = DateTime.now().weekday % 7 + 1;
    final aulas = [...p.horario]
      ..sort((a, b) {
        final d = a.diaSemana.compareTo(b.diaSemana);
        return d != 0 ? d : a.horaInicial.compareTo(b.horaInicial);
      });
    final filtradas =
        _hoje ? aulas.where((a) => a.diaSemana == hojeRm).toList() : aulas;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Hoje')),
            ButtonSegment(value: false, label: Text('Semana')),
          ],
          selected: {_hoje},
          onSelectionChanged: (s) => setState(() => _hoje = s.first),
        ),
      ),
      Expanded(
        child: filtradas.isEmpty
            ? const EmptyState(
                icon: Icons.calendar_today_outlined,
                title: 'Sem aulas',
                subtitle: 'Nada agendado para este filtro')
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _build(filtradas),
              ),
      ),
    ]);
  }

  List<Widget> _build(List<AulaHorario> aulas) {
    final out = <Widget>[];
    int? diaAtual;
    for (final a in aulas) {
      if (!_hoje && a.diaSemana != diaAtual) {
        diaAtual = a.diaSemana;
        out.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(_dias[a.diaSemana].toUpperCase(),
              style: const TextStyle(
                  color: AppColors.text2,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ));
      }
      out.add(AulaTile(aula: a));
    }
    return out;
  }
}
