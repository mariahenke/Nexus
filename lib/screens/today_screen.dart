// TELA "HOJE": lista os hábitos do dia, permite concluir ou usar o Plano B.
// Fluxo do Plano B: escolher MOTIVO -> escolher ATIVIDADE -> confirmar.
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models.dart';
import '../repository.dart';
import 'add_habit_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int _filtro = 0;
  static const _filtros = ['Todos', 'Pendentes', 'Concluídos', 'Compensados'];

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  void _editar(Habit h) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => AddHabitScreen(habit: h)));

  Future<void> _concluir(Habit h, String hoje) async {
    await Repo.saveLog(HabitLog(habitId: h.id, date: hoje, status: 'done'));
    _msg('Hábito concluído!');
  }

  Future<void> _planB(Habit h, String hoje) async {
    final r = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => PlanBSheet(habit: h, date: hoje),
    );
    if (r != null) _msg(r);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DataBuilder(builder: (context, habits, logs) {
        final hoje = dateKey(DateTime.now());
        // Só os hábitos programados para o dia da semana de hoje
        final diaSemana = DateTime.now().weekday;
        final habitosHoje = habits.where((h) => h.days.contains(diaSemana)).toList();
        // Mapa: id do hábito -> registro de hoje
        final doDia = {for (final l in logs.where((l) => l.date == hoje)) l.habitId: l};
        final feitos = doDia.values.where((l) => l.status == 'done').length;
        final comp = doDia.values.where((l) => l.status == 'planb').length;
        final progresso = habitosHoje.isEmpty ? 0.0 : (feitos + comp) / habitosHoje.length;

        final lista = habitosHoje.where((h) {
          final s = doDia[h.id]?.status;
          switch (_filtro) {
            case 1:
              return s == null;
            case 2:
              return s == 'done';
            case 3:
              return s == 'planb';
            default:
              return true;
          }
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ScreenHeader('Hoje'),
            // ---- Progresso do dia ----
            Panel(
              child: Row(children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: Stack(alignment: Alignment.center, children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progresso,
                        strokeWidth: 7,
                        backgroundColor: C.card2,
                        color: C.accent,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text('${feitos + comp}/${habitosHoje.length}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('PROGRESSO DE HOJE',
                        style: TextStyle(color: C.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      habitosHoje.isEmpty
                          ? (habits.isEmpty ? 'Crie seu primeiro hábito' : 'Nada programado para hoje')
                          : (feitos + comp == 0 ? 'Nenhuma atividade ainda' : 'Você está indo bem!'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text('$feitos concluída(s) · $comp compensada(s)',
                        style: const TextStyle(color: C.muted, fontSize: 13)),
                  ]),
                ),
              ]),
            ),
            // ---- Botão Nova tarefa ----
            FilledButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AddHabitScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Novo hábito'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const SizedBox(height: 14),
            // ---- Filtros ----
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _filtros.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filtros[i]),
                      selected: _filtro == i,
                      onSelected: (_) => setState(() => _filtro = i),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (lista.isEmpty)
              Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  habits.isEmpty
                      ? 'Nenhum hábito ainda.\nToque em "Novo hábito" ou gere dados de exemplo no Perfil.'
                      : (habitosHoje.isEmpty
                          ? 'Nenhum hábito programado para hoje.'
                          : 'Nada por aqui neste filtro.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: C.muted),
                ),
              ),
            for (final h in lista) _cartao(h, doDia[h.id], hoje),
          ],
        );
      }),
    );
  }

  // Cartão de um hábito
  Widget _cartao(Habit h, HabitLog? log, String hoje) {
    final cor = catColor(h.category);
    final (statusTxt, statusCor) = switch (log?.status) {
      'done' => ('Concluído', C.done),
      'planb' => ('Compensado', C.planb),
      'missed' => ('Perdido', C.missed),
      _ => ('Pendente', C.muted),
    };

    return Opacity(
      opacity: log == null ? 1 : 0.7,
      child: Panel(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 6),
        child: Column(children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _editar(h),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(catIcon(h.category), color: cor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(h.name,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        decoration: log?.status == 'done' ? TextDecoration.lineThrough : null)),
                const SizedBox(height: 2),
                Text(
                    [if (h.time != null) h.time!, if (h.minutes != null) '${h.minutes} min', h.category].join(' · '),
                    style: const TextStyle(color: C.muted, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(spacing: 6, children: [
                  Tag(h.priority, prioColor(h.priority)),
                  Tag(statusTxt, statusCor),
                ]),
                if (log?.planB != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Plano B: ${log!.planB}',
                        style: const TextStyle(color: C.planb, fontSize: 13)),
                  ),
              ]),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: C.muted),
              onSelected: (v) async {
                if (v == 'edit') _editar(h);
                if (v == 'undo') await Repo.deleteLog(h.id, hoje);
                if (v == 'del') await Repo.deleteHabit(h.id);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar hábito')),
                if (log != null) const PopupMenuItem(value: 'undo', child: Text('Desfazer registro')),
                const PopupMenuItem(value: 'del', child: Text('Excluir hábito')),
              ],
            ),
          ])),
          if (log == null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: C.line),
            Row(children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _concluir(h, hoje),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Concluir'),
                ),
              ),
              Container(width: 1, height: 28, color: C.line),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _planB(h, hoje),
                  icon: const Icon(Icons.subdirectory_arrow_right, size: 18),
                  label: const Text('Plano B'),
                  style: TextButton.styleFrom(foregroundColor: C.muted),
                ),
              ),
            ]),
          ] else
            const SizedBox(height: 12),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Janela que sobe de baixo: passo 1 = motivo, passo 2 = alternativa
// ---------------------------------------------------------------
class PlanBSheet extends StatefulWidget {
  final Habit habit;
  final String date;
  const PlanBSheet({super.key, required this.habit, required this.date});

  @override
  State<PlanBSheet> createState() => _PlanBSheetState();
}

class _PlanBSheetState extends State<PlanBSheet> {
  String? _motivo; // null = ainda no passo 1
  int? _escolha; // índice da alternativa; o último índice = "não fiz nada"
  bool _salvando = false;

  Future<void> _confirmar() async {
    final planB = widget.habit.planB;
    final nenhuma = _escolha == planB.length;
    setState(() => _salvando = true);
    await Repo.saveLog(HabitLog(
      habitId: widget.habit.id,
      date: widget.date,
      status: nenhuma ? 'missed' : 'planb',
      reason: _motivo,
      planB: nenhuma ? null : planB[_escolha!],
    ));
    if (mounted) {
      Navigator.pop(context, nenhuma ? 'Registrado como perdido.' : 'Plano B: ${planB[_escolha!]}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SingleChildScrollView(
          child: _motivo == null ? _passoMotivo() : _passoAlternativa(),
        ),
      ),
    );
  }

  Widget _passoMotivo() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('O que aconteceu?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const Text('Sem julgamentos. Isso nos ajuda a entender seus padrões.',
          style: TextStyle(color: C.muted)),
      const SizedBox(height: 14),
      for (final m in motivos)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            tileColor: C.card2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(m),
            trailing: const Icon(Icons.chevron_right, color: C.muted),
            onTap: () => setState(() => _motivo = m),
          ),
        ),
    ]);
  }

  Widget _passoAlternativa() {
    final opcoes = [...widget.habit.planB, 'Não consegui fazer nada'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextButton(
          onPressed: () => setState(() => _motivo = null), child: const Text('← Voltar')),
      const Text('Escolha uma alternativa',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const Text('Uma atividade menor ainda mantém você conectado ao objetivo.',
          style: TextStyle(color: C.muted)),
      const SizedBox(height: 14),
      for (var i = 0; i < opcoes.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            tileColor: C.card2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: _escolha == i ? C.accent : Colors.transparent, width: 2),
            ),
            title: Text(opcoes[i]),
            trailing: Icon(
              _escolha == i ? Icons.radio_button_checked : Icons.radio_button_off,
              color: _escolha == i ? C.accent : C.muted,
            ),
            onTap: () => setState(() => _escolha = i),
          ),
        ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: (_escolha == null || _salvando) ? null : _confirmar,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Confirmar'),
        ),
      ),
    ]);
  }
}
