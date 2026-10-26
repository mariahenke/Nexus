// PERFIL: mostra nome e e-mail, gera dados de exemplo e permite sair.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _ocupado = false;

  Future<void> _rodar(Future<void> Function() acao, String msg) async {
    setState(() => _ocupado = true);
    try {
      await acao();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ScreenHeader('Perfil'),
          // userChanges() avisa quando o nome é salvo logo após o cadastro
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snap) {
              final u = snap.data ?? FirebaseAuth.instance.currentUser;
              final email = u?.email ?? '';
              final nome = (u?.displayName ?? '').trim();
              final inicial = (nome.isNotEmpty ? nome : email);
              return Panel(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: C.accent,
                      child: Text(inicial.isEmpty ? '?' : inicial[0].toUpperCase(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (nome.isNotEmpty)
                          Text(nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        Text(email, style: const TextStyle(color: C.muted)),
                      ]),
                    ),
                  ],
                ),
              );
            },
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Demonstração',
                    subtitle: 'Cria 35 dias de histórico para ver os gráficos funcionando.'),
                FilledButton.icon(
                  onPressed: _ocupado ? null : () => _rodar(Repo.seed, 'Dados de exemplo criados!'),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Gerar dados de exemplo'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _ocupado ? null : () => _rodar(Repo.clearLogs, 'Registros apagados.'),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Apagar todos os registros'),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
