import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/falta_disciplina.dart';
import 'status_chip.dart';

class FaltaCard extends StatelessWidget {
  final FaltaDisciplina falta;
  const FaltaCard({super.key, required this.falta});

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final Color borda;
    final Color fundo;
    switch (falta.nivel) {
      case NivelFalta.critico:
        cor = AppColors.error;
        borda = AppColors.error.withValues(alpha: 0.45);
        fundo = AppColors.error.withValues(alpha: 0.07);
        break;
      case NivelFalta.atencao:
        cor = AppColors.warning;
        borda = AppColors.warning.withValues(alpha: 0.40);
        fundo = AppColors.warning.withValues(alpha: 0.06);
        break;
      case NivelFalta.tranquilo:
        cor = AppColors.success;
        borda = AppColors.border;
        fundo = AppColors.card;
        break;
    }
    final pct = falta.percentualLimite;
    final meta = falta.nivel == NivelFalta.critico
        ? '${falta.faltas} de ${falta.maxFaltas} faltas · limite atingido'
        : '${falta.faltas} de ${falta.maxFaltas} faltas · faltam ${falta.faltasRestantes}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borda),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(falta.disciplina,
                style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
          StatusChip('${pct.round()}%', color: cor),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(cor),
          ),
        ),
        const SizedBox(height: 7),
        Text(meta, style: const TextStyle(color: AppColors.text2, fontSize: 11)),
      ]),
    );
  }
}
