// TELA DE LOGIN (só entrar). O cadastro agora é outra tela (signup_screen.dart).
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'signup_screen.dart';

// Traduz os códigos de erro do Firebase (usada também no cadastro).
String traduzErroAuth(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'E-mail ou senha incorretos.';
    case 'email-already-in-use':
      return 'Este e-mail já está cadastrado.';
    case 'invalid-email':
      return 'E-mail inválido.';
    case 'weak-password':
      return 'A senha precisa ter pelo menos 6 caracteres.';
    default:
      return 'Erro: $code';
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  bool _ocultar = true;
  String? _erro;

  Future<void> _entrar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email.text.trim(), password: _senha.text);
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = traduzErroAuth(e.code));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LogoNexus(size: 110),
                  const SizedBox(height: 20),
                  const Text('Nexus', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Gerencie seus hábitos. Entenda seus padrões.',
                      style: TextStyle(color: C.muted)),
                  const SizedBox(height: 32),
                  const Text('Entrar na sua conta',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        hintText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _senha,
                    obscureText: _ocultar,
                    onSubmitted: (_) => _entrar(),
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_ocultar ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _ocultar = !_ocultar),
                      ),
                    ),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(_erro!, style: const TextStyle(color: C.missed)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _carregando ? null : _entrar,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _carregando
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Entrar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 28),
                  const Row(children: [
                    Expanded(child: Divider(color: C.line)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Novo por aqui?', style: TextStyle(color: C.muted)),
                    ),
                    Expanded(child: Divider(color: C.line)),
                  ]),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Criar uma conta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
