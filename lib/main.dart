import 'package:flutter/material.dart';
import 'app.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/secure_storage_ds.dart';
import 'data/datasources/rm_api_ds.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/academic_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = await DioClient.create();
  final storage = SecureStorageDataSource();
  final authRepo = AuthRepository(client, storage);

  // Liga o interceptor de sessão: ao expirar, re-loga e reexecuta.
  client.attachAuth(authRepo.refreshSession);

  final academicRepo = AcademicRepository(RmApiDataSource(client));

  runApp(App(authRepo: authRepo, academicRepo: academicRepo));
}
