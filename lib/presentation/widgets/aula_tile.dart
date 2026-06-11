import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/aula_horario.dart';

class AulaTile extends StatelessWidget {
  final AulaHorario aula;
  const AulaTile({super.key, required this.aula});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(aula.horaInicial,
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.bold)),
            Text(aula.horaFinal,
                style: const TextStyle(color: AppColors.text2, fontSize: 11)),
          ]),
          const SizedBox(width: 14),
          Container(width: 3, height: 36, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(aula.nome,
                  style: const TextStyle(
                      color: AppColors.text, fontWeight: FontWeight.w600)),
              Text(aula.local ?? 'Sala não informada',
                  style: const TextStyle(color: AppColors.text2, fontSize: 11)),
            ]),
          ),
        ]),
      );
}
