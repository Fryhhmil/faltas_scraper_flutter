import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/academic_provider.dart';
import '../widgets/nota_card.dart';
import '../widgets/skeleton.dart';
import '../widgets/empty_state.dart';

class NotasScreen extends StatelessWidget {
  const NotasScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AcademicProvider>();
    return RefreshIndicator(
      onRefresh: p.refresh,
      child: (p.loading && p.notas.isEmpty)
          ? ListView(padding: const EdgeInsets.all(16),
              children: const [SkeletonList()])
          : p.notas.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  EmptyState(
                      icon: Icons.grade_outlined,
                      title: 'Nenhuma nota encontrada',
                      subtitle: 'Puxe para atualizar')
                ])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: p.notas.map((n) => NotaCard(nota: n)).toList(),
                ),
    );
  }
}
