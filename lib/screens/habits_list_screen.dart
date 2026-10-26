// TELA "MEUS HÁBITOS": lista todos os hábitos com detalhes.
// Aberta ao tocar no cartão "Hábitos ativos" da tela Análise.
// Tocar num hábito abre a edição; a lixeira exclui.
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models.dart';
import '../repository.dart';
import 'add_habit_screen.dart';

class HabitsListScreen extends StatelessWidget {
  const HabitsListScreen({super.key});

  Future<void> _excluir(BuildContext context, Habit h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir hábito?'),
        content: Text('"${h.name}" será removido. O histórico já registrado continua nas estatísticas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir', style: TextStyle(color: C.missed))),
        ],
      ),
    );
    if (ok == true) await Repo.deleteHabit(h.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: C.bg, title: const Text('Meus hábitos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DataBuilder(builder: (context, habits, logs) {
            if (habits.isEmpty) {
              return const Center(
                child: Text('Nenhum hábito cadastrado.', style: TextStyle(color: C.muted)),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final h in habits) _cartao(context, h, logs),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _cartao(BuildContext context, Habit h, List<HabitLog> logs) {
    final cor = catColor(h.category);
    final ls = logs.where((l) => l.habitId == h.id).toList();
    final taxa = ls.isEmpty
        ? null
        : (ls.where((l) => l.status == 'done').length * 100 / ls.length).round();

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => AddHabitScreen(habit: h))),
      child: Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
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
                Text(h.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                Text(
                  [h.diasTexto, if (h.time != null) h.time!, if (h.minutes != null) '${h.minutes} min']
                      .join(' · '),
                  style: const TextStyle(color: C.muted, fontSize: 13),
                ),
              ]),
            ),
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined, color: C.muted),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => AddHabitScreen(habit: h))),
            ),
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline, color: C.muted),
              onPressed: () => _excluir(context, h),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 6, children: [
            Tag(h.category, cor),
            Tag('Prioridade ${h.priority.toLowerCase()}', prioColor(h.priority)),
          ]),
          const SizedBox(height: 12),
          const Text('Plano B',
              style: TextStyle(color: C.muted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          for (final p in h.planB)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('• $p', style: const TextStyle(color: C.planb)),
            ),
          const SizedBox(height: 12),
          Text(
            taxa == null ? 'Sem registros ainda' : 'Taxa de conclusão: $taxa%',
            style: const TextStyle(color: C.muted, fontSize: 13),
          ),
        ]),
      ),
    );
  }
}
