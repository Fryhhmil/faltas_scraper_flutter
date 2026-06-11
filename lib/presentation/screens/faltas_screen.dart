import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/academic_provider.dart';
import '../widgets/falta_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/empty_state.dart';

class FaltasScreen extends StatelessWidget {
  const FaltasScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    return RefreshIndicator(
      onRefresh: p.refresh,
      child: (p.loading && p.faltas.isEmpty)
          ? ListView(padding: const EdgeInsets.all(16),
              children: const [SkeletonList()])
          : p.faltas.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  EmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'Nenhuma falta registrada',
                      subtitle: 'Tudo certo por aqui')
                ])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: p.faltas.map((f) => FaltaCard(falta: f)).toList(),
                ),
    );
  }
}
