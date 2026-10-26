// "CASCA" DO APP: barra de navegação inferior com as 3 abas.
import 'package:flutter/material.dart';

import 'analysis_screen.dart';
import 'profile_screen.dart';
import 'today_screen.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Limita a largura no Chrome para parecer um celular.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: IndexedStack(
            index: _aba,
            children: const [TodayScreen(), AnalysisScreen(), ProfileScreen()],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _aba,
        onDestinationSelected: (i) => setState(() => _aba = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Análise'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
