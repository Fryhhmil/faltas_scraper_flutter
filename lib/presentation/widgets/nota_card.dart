import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/nota_parser.dart';
import '../../data/models/nota_disciplina.dart';
import 'status_chip.dart';

class NotaCard extends StatelessWidget {
  final NotaDisciplina nota;
  const NotaCard({super.key, required this.nota});

  String _fmt(double? v) => v == null ? '—' : v.toStringAsFixed(1).replaceAll('.', ',');

  Color _cor(Faixa f) {
    switch (f) {
      case Faixa.boa:
        return AppColors.success;
      case Faixa.atencao:
        return AppColors.warning;
      case Faixa.risco:
        return AppColors.error;
      case Faixa.neutra:
        return AppColors.accent;
    }
  }

  Widget _chip(String label, double? v, {bool destaque = false}) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: destaque
                ? AppColors.success.withValues(alpha: 0.10)
                : AppColors.card2,
            borderRadius: BorderRadius.circular(9),
            border: destaque
                ? Border.all(color: AppColors.success.withValues(alpha: 0.25))
                : null,
          ),
          child: Column(children: [
            Text(label,
                style: const TextStyle(fontSize: 8, color: AppColors.text2)),
            const SizedBox(height: 3),
            Text(_fmt(v),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: destaque
                        ? AppColors.success
                        : (NotaParser.faixaCor(v) == Faixa.risco && v != null
                            ? AppColors.error
                            : AppColors.text))),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nota.disciplina,
                    style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(nota.situacao,
                    style: const TextStyle(fontSize: 10, color: AppColors.text2)),
              ]),
            ),
            StatusChip(_fmt(nota.mediaExibida), color: _cor(nota.faixaMedia)),
          ]),
          if (nota.semNotas)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Center(
                child: Text('Sem notas lançadas ainda',
                    style: TextStyle(color: AppColors.text2, fontSize: 11)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Row(children: [
                _chip('P1', nota.p1),
                _chip('P2', nota.p2),
                _chip('P3', nota.p3),
                _chip('Final', nota.mediaExibida, destaque: true),
              ]),
            ),
        ]),
      ),
    );
  }
}
