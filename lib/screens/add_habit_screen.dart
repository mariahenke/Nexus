// TELA "NOVO HÁBITO" / "EDITAR HÁBITO".
// Se receber um hábito (habit), abre em modo edição com os campos preenchidos.
// Nenhuma opção vem marcada: o usuário escolhe tudo.
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models.dart';
import '../repository.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habit; // se vier preenchido, estamos EDITANDO
  const AddHabitScreen({super.key, this.habit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nome = TextEditingController();
  final _planB1 = TextEditingController();
  final _planB2 = TextEditingController();
  TimeOfDay? _hora; // opcional
  final Set<int> _dias = {}; // 1 = Seg ... 7 = Dom (começa vazio)
  int? _minutos; // opcional
  String? _categoria;
  String? _prioridade;
  bool _salvando = false;

  bool get _editando => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    if (h != null) {
      _nome.text = h.name;
      _planB1.text = h.planB.isNotEmpty ? h.planB[0] : '';
      _planB2.text = h.planB.length > 1 ? h.planB[1] : '';
      if (h.time != null) {
        final p = h.time!.split(':');
        _hora = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
      _dias.addAll(h.days);
      _minutos = h.minutes;
      _categoria = h.category;
      _prioridade = h.priority;
    }
  }

  Future<void> _escolherHora() async {
    final t = await showTimePicker(
        context: context, initialTime: _hora ?? const TimeOfDay(hour: 8, minute: 0));
    if (t != null) setState(() => _hora = t);
  }

  Future<void> _salvar() async {
    final planB = [_planB1.text.trim(), _planB2.text.trim()].where((e) => e.isNotEmpty).toList();
    if (_nome.text.trim().isEmpty) return _aviso('Dê um nome ao hábito.');
    if (_dias.isEmpty) return _aviso('Escolha pelo menos um dia da semana.');
    if (_categoria == null) return _aviso('Escolha a categoria.');
    if (_prioridade == null) return _aviso('Escolha a prioridade.');
    if (planB.isEmpty) {
      return _aviso('Informe pelo menos uma atividade de compensação (Plano B).');
    }

    String? horario;
    if (_hora != null) {
      final hh = _hora!.hour.toString().padLeft(2, '0');
      final mm = _hora!.minute.toString().padLeft(2, '0');
      horario = '$hh:$mm';
    }
    final habito = Habit(
      name: _nome.text.trim(),
      time: horario,
      days: (_dias.toList()..sort()),
      minutes: _minutos,
      category: _categoria!,
      priority: _prioridade!,
      planB: planB,
    );

    setState(() => _salvando = true);
    final mensagens = ScaffoldMessenger.of(context);
    final navegador = Navigator.of(context);
    try {
      if (_editando) {
        await Repo.updateHabit(widget.habit!.id, habito);
      } else {
        await Repo.addHabit(habito);
      }
      navegador.pop();
      mensagens.showSnackBar(SnackBar(content: Text('Hábito salvo para: ${habito.diasTexto}')));
    } catch (e) {
      _aviso('Erro ao salvar: $e');
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _aviso(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // Linha de chips. Tocar de novo no chip marcado desmarca.
  Widget _chips<T>(List<T> opcoes, T? atual, void Function(T?) aoEscolher, String Function(T) rotulo) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opcoes
          .map((o) => ChoiceChip(
                label: Text(rotulo(o)),
                selected: o == atual,
                onSelected: (_) => setState(() => aoEscolher(o == atual ? null : o)),
              ))
          .toList(),
    );
  }

  Widget _rotulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, color: C.muted)),
      );

  @override
  Widget build(BuildContext context) {
    final botaoSalvar = FilledButton(
      onPressed: _salvando ? null : _salvar,
      child: Text(_editando ? 'Salvar alterações' : 'Salvar'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar hábito' : 'Novo hábito'),
        backgroundColor: C.bg,
        actions: [Padding(padding: const EdgeInsets.only(right: 12), child: botaoSalvar)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _rotulo('NOME DO HÁBITO *'),
                  TextField(
                      controller: _nome,
                      decoration: const InputDecoration(hintText: 'Ex.: Estudar inglês')),
                  const SizedBox(height: 18),
                  _rotulo('DIAS DA SEMANA *'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (i) {
                      final dia = i + 1;
                      return FilterChip(
                        label: Text(diasCurto[i]),
                        selected: _dias.contains(dia),
                        onSelected: (marcado) => setState(() {
                          marcado ? _dias.add(dia) : _dias.remove(dia);
                        }),
                      );
                    }),
                  ),
                  Row(children: [
                    TextButton(
                      onPressed: () => setState(() => _dias
                        ..clear()
                        ..addAll([1, 2, 3, 4, 5, 6, 7])),
                      child: const Text('Todos os dias'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _dias
                        ..clear()
                        ..addAll([1, 2, 3, 4, 5])),
                      child: const Text('Dias úteis'),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _rotulo('HORÁRIO (OPCIONAL)'),
                  Row(children: [
                    OutlinedButton.icon(
                      onPressed: _escolherHora,
                      icon: const Icon(Icons.schedule),
                      label: Text(_hora == null ? 'Definir horário' : _hora!.format(context)),
                    ),
                    if (_hora != null)
                      IconButton(
                        tooltip: 'Remover horário',
                        onPressed: () => setState(() => _hora = null),
                        icon: const Icon(Icons.close, color: C.muted),
                      ),
                  ]),
                  const SizedBox(height: 18),
                  _rotulo('DURAÇÃO (OPCIONAL)'),
                  _chips<int>([5, 15, 30, 45, 60], _minutos, (v) => _minutos = v, (v) => '$v min'),
                ]),
              ),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _rotulo('CATEGORIA *'),
                  _chips<String>(categorias, _categoria, (v) => _categoria = v, (v) => v),
                  const SizedBox(height: 18),
                  _rotulo('PRIORIDADE *'),
                  _chips<String>(prioridades, _prioridade, (v) => _prioridade = v, (v) => v),
                ]),
              ),
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionTitle('Atividades de compensação (Plano B) *',
                      subtitle: 'O que fazer quando não der para cumprir o hábito completo.'),
                  TextField(
                      controller: _planB1,
                      decoration: const InputDecoration(hintText: 'Ex.: Ler uma notícia em inglês')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _planB2,
                      decoration: const InputDecoration(hintText: 'Ex.: Ouvir um podcast')),
                ]),
              ),
              // Botão de salvar também no fim da página
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _salvando ? null : _salvar,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_editando ? 'Salvar alterações' : 'Salvar hábito',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
