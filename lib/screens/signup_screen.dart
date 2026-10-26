// TELA DE CADASTRO: nome, e-mail e senha. Fica separada do login.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'login_screen.dart' show traduzErroAuth;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _carregando = false;
  bool _ocultar = true;
  String? _erro;

  Future<void> _criar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      setState(() => _erro = 'Informe seu nome.');
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: _email.text.trim(), password: _senha.text);
      await cred.user?.updateDisplayName(nome); // guarda o nome no perfil
      // Fecha a tela de cadastro: o AuthGate já troca para o app.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => _erro = traduzErroAuth(e.code));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: C.bg, title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LogoNexus(size: 80),
                  const SizedBox(height: 12),
                  const Text('Vamos começar',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Crie sua conta para acompanhar seus hábitos.',
                      style: TextStyle(color: C.muted)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nome,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        hintText: 'Seu nome', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
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
                    onSubmitted: (_) => _criar(),
                    decoration: InputDecoration(
                      hintText: 'Senha (mínimo 6 caracteres)',
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
                    onPressed: _carregando ? null : _criar,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _carregando
                        ? const SizedBox(
                            height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Criar conta',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Já tenho conta. Entrar'),
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
