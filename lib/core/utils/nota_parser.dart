enum Faixa { boa, atencao, risco, neutra }

/// Interpreta valores de nota vindos da API RM (strings com vírgula,
/// possivelmente embrulhadas em HTML como `<font color=red>4,00</font>`).
class NotaParser {
  static final _tag = RegExp(r'<[^>]*>');

  static String textoLimpo(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll(_tag, '').trim();
  }

  static double? parseValor(String? raw) {
    final limpo = textoLimpo(raw);
    if (limpo.isEmpty) return null;
    final normalizado = limpo.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalizado);
  }

  static Faixa faixaCor(double? valor) {
    if (valor == null) return Faixa.neutra;
    if (valor >= 7) return Faixa.boa;
    if (valor >= 5) return Faixa.atencao;
    return Faixa.risco;
  }
}
