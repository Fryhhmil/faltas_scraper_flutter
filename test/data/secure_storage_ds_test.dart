import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:faltas_scraper_flutter/data/datasources/secure_storage_ds.dart';
import 'package:faltas_scraper_flutter/data/models/credenciais.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SecureStorageDataSource ds;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    ds = SecureStorageDataSource();
  });

  test('salva e lê credenciais', () async {
    await ds.saveCredenciais(const Credenciais(cpf: '123', senha: 'abc'));
    final c = await ds.getCredenciais();
    expect(c!.cpf, '123');
    expect(c.senha, 'abc');
  });

  test('sem credenciais retorna null', () async {
    expect(await ds.getCredenciais(), isNull);
  });

  test('clear remove credenciais', () async {
    await ds.saveCredenciais(const Credenciais(cpf: '1', senha: '2'));
    await ds.clearCredenciais();
    expect(await ds.getCredenciais(), isNull);
  });
}
