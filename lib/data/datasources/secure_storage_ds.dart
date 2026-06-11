import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/credenciais.dart';
import '../../core/constants/storage_keys.dart';

class SecureStorageDataSource {
  final FlutterSecureStorage _s;
  SecureStorageDataSource([FlutterSecureStorage? storage])
      : _s = storage ?? const FlutterSecureStorage();

  Future<void> saveCredenciais(Credenciais c) async {
    await _s.write(key: StorageKeys.cpf, value: c.cpf);
    await _s.write(key: StorageKeys.senha, value: c.senha);
  }

  Future<Credenciais?> getCredenciais() async {
    final cpf = await _s.read(key: StorageKeys.cpf);
    final senha = await _s.read(key: StorageKeys.senha);
    if (cpf == null || senha == null) return null;
    return Credenciais(cpf: cpf, senha: senha);
  }

  Future<void> clearCredenciais() async {
    await _s.delete(key: StorageKeys.cpf);
    await _s.delete(key: StorageKeys.senha);
  }
}
