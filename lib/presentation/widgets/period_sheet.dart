import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/contexto_aluno.dart';

/// Bottom sheet de seleção de período/contexto. Devolve o contexto escolhido.
Future<ContextoAluno?> showPeriodSheet(
    BuildContext context, List<ContextoAluno> contextos, ContextoAluno? atual) {
  return showModalBottomSheet<ContextoAluno>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Selecione o período',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        ...contextos.map((c) {
          final sel = c.idContextoAluno == atual?.idContextoAluno;
          return ListTile(
            title: Text(c.nomeCurso,
                style: const TextStyle(color: AppColors.text)),
            subtitle: Text('${c.nomePeriodo} · ${c.nomeTurno}',
                style: const TextStyle(color: AppColors.text2)),
            trailing: sel
                ? const Icon(Icons.check_circle, color: AppColors.accent)
                : null,
            onTap: () => Navigator.pop(ctx, c),
          );
        }),
        const SizedBox(height: 8),
      ]),
    ),
  );
}
