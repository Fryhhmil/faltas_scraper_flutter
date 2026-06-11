import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/academic_provider.dart';
import '../widgets/ring_gauge.dart';
import '../widgets/skeleton.dart';
import '../widgets/aula_tile.dart';
import '../widgets/falta_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    final hoje = DateTime.now().weekday % 7 + 1; // weekday 1=Seg → RM 1=Dom..7=Sáb
    final aulasHoje =
        p.horario.where((a) => a.diaSemana == hoje).toList()
          ..sort((a, b) => a.horaInicial.compareTo(b.horaInicial));
    return RefreshIndicator(
      onRefresh: p.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (p.loading && p.notas.isEmpty)
            const SkeletonList(count: 4)
          else ...[
            _hero(p),
            const SizedBox(height: 12),
            _secao('Próximas aulas · hoje'),
            if (aulasHoje.isEmpty)
              const _Vazio('Sem aulas hoje 🎉')
            else
              ...aulasHoje.map((a) => AulaTile(aula: a)),
            const SizedBox(height: 12),
            if (p.faltasEmRisco.isNotEmpty) ...[
              _secao('Risco de reprovação por falta'),
              ...p.faltasEmRisco.map((f) => FaltaCard(falta: f)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _hero(AcademicProvider p) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          RingGauge(value: p.mediaGeral),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _metric('${p.totalFaltas}', 'Faltas'),
            _metric('${p.notas.length}', 'Disciplinas'),
            _metric(p.faltasEmRisco.isEmpty ? 'Em dia' : 'Atenção', 'Situação',
                cor: p.faltasEmRisco.isEmpty
                    ? AppColors.success
                    : AppColors.warning),
          ]),
        ]),
      );

  Widget _metric(String v, String k, {Color cor = AppColors.text}) =>
      Column(children: [
        Text(v,
            style: TextStyle(
                color: cor, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(k, style: const TextStyle(color: AppColors.text2, fontSize: 10)),
      ]);

  Widget _secao(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: AppColors.text2,
                fontSize: 11,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600)),
      );
}

class _Vazio extends StatelessWidget {
  final String t;
  const _Vazio(this.t);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(t,
            style: const TextStyle(color: AppColors.text2)),
      );
}
