import 'package:flutter_test/flutter_test.dart';
import 'package:faltas_scraper_flutter/core/utils/nota_parser.dart';

void main() {
  group('NotaParser.parseValor', () {
    test('vírgula decimal vira double', () {
      expect(NotaParser.parseValor('8,50'), 8.5);
    });
    test('remove <font color=red> e interpreta', () {
      expect(NotaParser.parseValor('<font color=red>4,00</font>'), 4.0);
    });
    test('null retorna null', () {
      expect(NotaParser.parseValor(null), isNull);
    });
    test('string vazia retorna null', () {
      expect(NotaParser.parseValor(''), isNull);
    });
    test('texto sem número retorna null', () {
      expect(NotaParser.parseValor('—'), isNull);
    });
  });

  group('NotaParser.textoLimpo', () {
    test('remove tags HTML mantendo texto', () {
      expect(NotaParser.textoLimpo('<font color=red>4,00</font>'), '4,00');
    });
  });

  group('NotaParser.faixaCor', () {
    test('>=7 é success', () {
      expect(NotaParser.faixaCor(7.0), Faixa.boa);
      expect(NotaParser.faixaCor(9.5), Faixa.boa);
    });
    test('5 a 6.9 é atencao', () {
      expect(NotaParser.faixaCor(6.9), Faixa.atencao);
      expect(NotaParser.faixaCor(5.0), Faixa.atencao);
    });
    test('<5 é risco', () {
      expect(NotaParser.faixaCor(4.99), Faixa.risco);
    });
    test('null é neutra', () {
      expect(NotaParser.faixaCor(null), Faixa.neutra);
    });
  });
}
