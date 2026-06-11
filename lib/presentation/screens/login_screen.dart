import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _cpf = TextEditingController();
  final _senha = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _cpf.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_cpf.text, _senha.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(auth.error ?? 'Erro ao entrar'),
      ));
    }
    // Navegação é reativa via router (redirect por isLoggedIn).
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.school, size: 64, color: AppColors.accent),
                const SizedBox(height: 8),
                const Text('Faltas iCEV',
                    style: TextStyle(
                        color: AppColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _cpf,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                      labelText: 'CPF', prefixIcon: Icon(Icons.person)),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o CPF' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senha,
                  obscureText: _obscure,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe a senha' : null,
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Mesma senha do TOTVS',
                      style: TextStyle(color: AppColors.text2, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: loading ? null : _submit,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('ENTRAR'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
