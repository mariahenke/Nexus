// TELA "ANÁLISE": calendário + gráficos feitos a partir dos registros (logs).
// Os gráficos usam só widgets básicos do Flutter (sem biblioteca externa).
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models.dart';
import '../repository.dart';
import 'habits_list_screen.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  // Cores usadas na rosca de motivos
  static const _coresMotivos = [
    C.accent, C.planb, Color(0xFF3B82F6), Color(0xFF22D3EE), C.missed, Color(0xFFFBBF24), C.muted,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DataBuilder(builder: (context, habits, logs) {
        if (logs.isEmpty) {
          return ListView(padding: const EdgeInsets.all(20), children: const [
            ScreenHeader('Análise'),
            Panel(
              child: Text(
                'Ainda não há registros.\nConclua hábitos na aba Início ou gere dados de exemplo no Perfil.',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.muted),
              ),
            ),
          ]);
        }

        // ---------- CÁLCULOS ----------
        final feitas = logs.where((l) => l.status == 'done').length;
        final comp = logs.where((l) => l.status == 'planb').length;
        final constancia = ((feitas + comp) * 100 / logs.length).round();
        final falhas = logs.where((l) => l.status != 'done').toList();

        // Motivos: motivo -> quantidade
        final motivosCont = <String, int>{};
        for (final l in falhas) {
          final m = l.reason ?? 'Outro motivo';
          motivosCont[m] = (motivosCont[m] ?? 0) + 1;
        }
        final motivosOrd = motivosCont.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        // Falhas por dia da semana (0 = segunda ... 6 = domingo)
        final porDia = List<int>.filled(7, 0);
        for (final l in falhas) {
          porDia[l.day.weekday - 1]++;
        }

        // Planos B usados
        final planBCont = <String, int>{};
        for (final l in logs.where((l) => l.planB != null)) {
          planBCont[l.planB!] = (planBCont[l.planB!] ?? 0) + 1;
        }
        final planBOrd = planBCont.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader('Análise'),
            _Calendario(habits: habits, logs: logs),
            // ---- Cartões de resumo ----
            Row(children: [
              _resumo('$constancia%', 'Constância', Icons.trending_up, C.accent),
              const SizedBox(width: 12),
              _resumo('${habits.length}', 'Hábitos ativos', Icons.bolt, C.planb,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HabitsListScreen()))),
            ]),
            Row(children: [
              _resumo('$feitas', 'Concluídas', Icons.check_circle_outline, C.done),
              const SizedBox(width: 12),
              _resumo('$comp', 'Compensações', Icons.subdirectory_arrow_right, C.missed),
            ]),
            // ---- Motivos de desvio ----
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Motivos de desvio', subtitle: 'Por que os hábitos não foram concluídos'),
                if (motivosOrd.isEmpty)
                  const Text('Sem desvios registrados.', style: TextStyle(color: C.muted))
                else
                  Row(children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          valores: motivosOrd.map((e) => e.value.toDouble()).toList(),
                          cores: List.generate(
                              motivosOrd.length, (i) => _coresMotivos[i % _coresMotivos.length]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(children: [
                        for (var i = 0; i < min(5, motivosOrd.length); i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                      color: _coresMotivos[i % _coresMotivos.length],
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(motivosOrd[i].key,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis)),
                              Text('${(motivosOrd[i].value * 100 / falhas.length).round()}%',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            ]),
                          ),
                      ]),
                    ),
                  ]),
              ]),
            ),
            // ---- Dias com mais dificuldade ----
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Dias com mais dificuldade', subtitle: 'Número de desvios por dia da semana'),
                _barrasSemana(porDia),
              ]),
            ),
            // ---- Compensações utilizadas ----
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionTitle('Compensações utilizadas', subtitle: 'Planos B mais acionados'),
                if (planBOrd.isEmpty)
                  const Text('Nenhum Plano B usado ainda.', style: TextStyle(color: C.muted)),
                for (final e in planBOrd.take(5))
                  _barraHorizontal(e.key, e.value, planBOrd.first.value),
              ]),
            ),
            // ---- Hábitos que precisam de atenção ----
            _atencao(habits, logs),
          ],
        );
      }),
    );
  }

  // Cartão pequeno com número grande
  Widget _resumo(String valor, String rotulo, IconData icone, Color cor, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icone, color: cor, size: 20),
            ),
            if (onTap != null) const Icon(Icons.arrow_forward_ios, size: 14, color: C.muted),
          ]),
          const SizedBox(height: 12),
          Text(valor, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          Text(rotulo, style: const TextStyle(color: C.muted, fontSize: 13)),
        ]),
      ),
      ),
    );
  }

  // Gráfico de barras verticais (a maior fica em vermelho)
  Widget _barrasSemana(List<int> valores) {
    final maximo = max(1, valores.reduce(max));
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (i) {
          final destaque = valores[i] == maximo && maximo > 0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('${valores[i]}', style: const TextStyle(fontSize: 12, color: C.muted)),
                const SizedBox(height: 4),
                Container(
                  height: 110 * valores[i] / maximo,
                  decoration: BoxDecoration(
                    color: destaque ? C.missed : C.accent.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(diasCurto[i], style: const TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _barraHorizontal(String rotulo, int valor, int maximo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(rotulo, overflow: TextOverflow.ellipsis)),
          Text('$valor×', style: const TextStyle(color: C.muted)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: valor / maximo, minHeight: 8, backgroundColor: C.card2, color: C.planb),
        ),
      ]),
    );
  }

  // Lista dos hábitos com menor taxa de conclusão
  Widget _atencao(List<Habit> habits, List<HabitLog> logs) {
    final itens = <Widget>[];
    final calc = <(Habit, int, String)>[];
    for (final h in habits) {
      final ls = logs.where((l) => l.habitId == h.id).toList();
      if (ls.length < 3) continue;
      final taxa = (ls.where((l) => l.status == 'done').length * 100 / ls.length).round();
      final f = ls.where((l) => l.status != 'done');
      final motivo = maisComum(f.map((l) => l.reason ?? 'Outro motivo'));
      final dia = maisComum(f.map((l) => diasLongo[l.day.weekday - 1]));
      final detalhe = [
        if (dia != null) 'Maior dificuldade às $dia',
        if (motivo != null) 'principal motivo: ${motivo.toLowerCase()}',
      ].join(' · ');
      calc.add((h, taxa, detalhe));
    }
    calc.sort((a, b) => a.$2.compareTo(b.$2));
    for (final c in calc.take(3)) {
      final cor = c.$2 < 70 ? C.missed : const Color(0xFFFBBF24);
      itens.add(Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.card2, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(c.$1.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${c.$2}%', style: TextStyle(color: cor, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          Text(c.$3, style: const TextStyle(color: C.muted, fontSize: 12)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
                value: c.$2 / 100, minHeight: 6, backgroundColor: C.bg, color: cor),
          ),
        ]),
      ));
    }
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle('Hábitos que precisam de atenção', subtitle: 'Menor taxa de conclusão'),
        if (itens.isEmpty)
          const Text('Registre mais dias para ver esta análise.', style: TextStyle(color: C.muted)),
        ...itens,
      ]),
    );
  }
}

// ---------------------------------------------------------------
// Desenha a rosca (gráfico de pizza com buraco no meio)
// ---------------------------------------------------------------
class _DonutPainter extends CustomPainter {
  final List<double> valores;
  final List<Color> cores;
  _DonutPainter({required this.valores, required this.cores});

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 22.0;
    final rect = Rect.fromLTWH(espessura / 2, espessura / 2, size.width - espessura,
        size.height - espessura);
    final total = valores.fold<double>(0, (a, b) => a + b);
    final folga = valores.length > 1 ? 0.05 : 0.0;
    var inicio = -pi / 2;
    for (var i = 0; i < valores.length; i++) {
      final angulo = valores[i] / total * 2 * pi;
      final pincel = Paint()
        ..color = cores[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura;
      canvas.drawArc(rect, inicio, max(0.0, angulo - folga), false, pincel);
      inicio += angulo;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.valores != valores;
}

// ---------------------------------------------------------------
// Calendário mensal: cada dia tem um pontinho colorido
//   vermelho = teve hábito perdido, roxo = teve compensação, verde = tudo concluído
// ---------------------------------------------------------------
class _Calendario extends StatefulWidget {
  final List<Habit> habits;
  final List<HabitLog> logs;
  const _Calendario({required this.habits, required this.logs});

  @override
  State<_Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<_Calendario> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);

  void _mudarMes(int d) => setState(() => _mes = DateTime(_mes.year, _mes.month + d));

  void _abrirDia(String key, DateTime dia) {
    final doDia = widget.logs.where((l) => l.date == key).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}/${dia.year}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            if (doDia.isEmpty) const Text('Sem registros neste dia.', style: TextStyle(color: C.muted)),
            for (final l in doDia)
              Builder(builder: (_) {
                final nome = widget.habits.where((h) => h.id == l.habitId).map((h) => h.name).firstOrNull ?? 'Hábito removido';
                final (txt, cor) = switch (l.status) {
                  'done' => ('Concluído', C.done),
                  'planb' => ('Compensação: ${l.planB ?? ''}', C.planb),
                  _ => ('Não realizado${l.reason != null ? ' (${l.reason})' : ''}', C.missed),
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: C.card2, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Icon(Icons.circle, color: cor, size: 12),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(txt, style: TextStyle(color: cor, fontSize: 13)),
                      ]),
                    ),
                  ]),
                );
              }),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primeiro = DateTime(_mes.year, _mes.month, 1);
    final deslocamento = primeiro.weekday % 7; // semana começa no domingo
    final diasNoMes = DateUtils.getDaysInMonth(_mes.year, _mes.month);
    final linhas = ((deslocamento + diasNoMes) / 7).ceil();
    final hoje = DateTime.now();

    // Cor do pontinho de cada dia
    Color? corDoDia(String key) {
      final ls = widget.logs.where((l) => l.date == key).toList();
      if (ls.isEmpty) return null;
      if (ls.any((l) => l.status == 'missed')) return C.missed;
      if (ls.any((l) => l.status == 'planb')) return C.planb;
      return C.done;
    }

    return Panel(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${meses[_mes.month - 1]} ${_mes.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Row(children: [
            IconButton(onPressed: () => _mudarMes(-1), icon: const Icon(Icons.chevron_left)),
            IconButton(onPressed: () => _mudarMes(1), icon: const Icon(Icons.chevron_right)),
          ]),
        ]),
        Row(
          children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
              .map((d) => Expanded(
                  child: Center(
                      child: Text(d, style: const TextStyle(color: C.muted, fontSize: 12)))))
              .toList(),
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < linhas; r++)
          Row(
            children: List.generate(7, (c) {
              final n = r * 7 + c - deslocamento + 1;
              if (n < 1 || n > diasNoMes) return const Expanded(child: SizedBox(height: 46));
              final dia = DateTime(_mes.year, _mes.month, n);
              final key = dateKey(dia);
              final cor = corDoDia(key);
              final futuro = dia.isAfter(DateTime(hoje.year, hoje.month, hoje.day));
              final ehHoje = key == dateKey(hoje);
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: futuro ? null : () => _abrirDia(key, dia),
                  child: Container(
                    height: 46,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: ehHoje ? Border.all(color: C.accent) : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$n',
                          style: TextStyle(
                              color: futuro ? C.line : C.text, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: cor ?? Colors.transparent, shape: BoxShape.circle),
                      ),
                    ]),
                  ),
                ),
              );
            }),
          ),
        const SizedBox(height: 10),
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Legenda('Completo', C.done),
          SizedBox(width: 14),
          _Legenda('Compensado', C.planb),
          SizedBox(width: 14),
          _Legenda('Não realizado', C.missed),
        ]),
      ]),
    );
  }
}

class _Legenda extends StatelessWidget {
  final String texto;
  final Color cor;
  const _Legenda(this.texto, this.cor);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(Icons.circle, color: cor, size: 9),
      const SizedBox(width: 5),
      Text(texto, style: const TextStyle(color: C.muted, fontSize: 12)),
    ]);
  }
}
