// VISUAL DO APP: cores, tema e pequenos componentes reutilizáveis.
// Para mudar o visual inteiro, edite as cores da classe C.
import 'package:flutter/material.dart';

import '../models.dart';

class C {
  static const bg = Color(0xFF0B0B10); // fundo
  static const card = Color(0xFF16161F); // cartões
  static const card2 = Color(0xFF1F1F2B); // campos / cartões internos
  static const line = Color(0xFF2A2A38); // bordas
  static const text = Color(0xFFF4F4F8);
  static const muted = Color(0xFF8E8EA3);
  static const accent = Color(0xFF7C5CFF);
  static const done = Color(0xFF34D399); // concluído (verde)
  static const planb = Color(0xFFA78BFA); // compensado (roxo)
  static const missed = Color(0xFFFB7185); // perdido (coral)
}

ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(primary: C.accent, surface: C.card),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.card,
      indicatorColor: C.accent.withValues(alpha: 0.25),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.card2,
      hintStyle: const TextStyle(color: C.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

// Cartão padrão do app.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: padding,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: C.line),
      ),
      child: child,
    );
  }
}

// Etiqueta pequena colorida (ex.: "Alta", "Concluído").
class Tag extends StatelessWidget {
  final String text;
  final Color color;
  const Tag(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// Título grande de cada tela, com a data.
class ScreenHeader extends StatelessWidget {
  final String title;
  const ScreenHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(dataExtensa(DateTime.now()), style: const TextStyle(color: C.muted)),
        ],
      ),
    );
  }
}

// Título de seção dentro de um cartão.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(color: C.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

// Logo do app (assets/images/logo.png). Se o arquivo não for encontrado,
// mostra o quadradinho com a letra N no lugar.
class LogoNexus extends StatelessWidget {
  final double size;
  const LogoNexus({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Container(
          width: size * 0.7,
          height: size * 0.7,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: C.accent, borderRadius: BorderRadius.circular(20)),
          child: const Text('N', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
