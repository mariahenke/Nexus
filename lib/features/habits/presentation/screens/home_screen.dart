import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/habit_model.dart';
import 'add_habit_screen.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/habit_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFilterIndex = 0;
  int _selectedNavIndex = 0;

  final List<String> _filters = ['Todos', 'Pendentes', 'Concluídos', 'Compensados'];

  // Lista dinâmica de hábitos
  late List<HabitModel> _habits;

  @override
  void initState() {
    super.initState();
    _habits = []; // Lista vazia: só exibirá os hábitos adicionados pelo usuário
  }

  // Quantidade de hábitos concluídos ou compensados para o progresso
  int get _completedCount =>
      _habits.where((h) => h.status != HabitStatus.pendente).length;

  // Ação: Concluir Hábito
  void _completeHabit(HabitModel habit) {
    setState(() {
      final index = _habits.indexWhere((h) => h.id == habit.id);
      if (index != -1) {
        _habits[index] = HabitModel(
          id: habit.id,
          title: habit.title,
          time: habit.time,
          durationMinutes: habit.durationMinutes,
          category: habit.category,
          priority: habit.priority,
          status: HabitStatus.concluido,
          icon: habit.icon,
          iconBgColor: habit.iconBgColor,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text('Parabéns! Hábito "${habit.title}" concluído!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Ação: Abrir o Fluxo do Plano B
  void _showPlanBModal(HabitModel habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlanBReasonSheet(
        habit: habit,
        onReasonSelected: (reason) {
          Navigator.pop(context); // Fecha o 1º modal
          _showPlanBOptionsModal(habit, reason); // Abre o 2º modal
        },
      ),
    );
  }

  // Ação: Abrir o 2º Modal do Plano B (Escolher Alternativa)
  void _showPlanBOptionsModal(HabitModel habit, String reason) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlanBOptionsSheet(
        habit: habit,
        reason: reason,
        onConfirm: (optionTitle) {
          Navigator.pop(context);

          setState(() {
            final index = _habits.indexWhere((h) => h.id == habit.id);
            if (index != -1) {
              _habits[index] = HabitModel(
                id: habit.id,
                title: habit.title,
                time: habit.time,
                durationMinutes: habit.durationMinutes,
                category: habit.category,
                priority: habit.priority,
                status: HabitStatus.compensado,
                icon: habit.icon,
                iconBgColor: habit.iconBgColor,
              );
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plano B ativado: $optionTitle!'),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildProgressCard(),
              const SizedBox(height: 20),
              _buildNewTaskButton(),
              const SizedBox(height: 20),
              _buildFilterChips(),
              const SizedBox(height: 20),
              _buildHabitsList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
  return Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFF6366F1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            'N',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoje',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            Text(
              'Domingo, 20 De Set',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.subtitleColor,
              ),
            ),
          ],
        ),
      ),
      // 🟢 AVATAR 'M' TRANSFORMADO EM BOTÃO DE LOGOUT
      Tooltip(
        message: 'Clique para sair',
        child: InkWell(
          onTap: () async {
            await AuthService().signOut();
          },
          borderRadius: BorderRadius.circular(21),
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFF4F46E5),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildProgressCard() {
    final double progressValue = _habits.isEmpty ? 0.0 : _completedCount / _habits.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 70,
                  child: CircularProgressIndicator(
                    value: progressValue,
                    backgroundColor: const Color(0xFFF1F5F9),
                    color: AppTheme.primaryColor,
                    strokeWidth: 7,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_completedCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    Text(
                      'de ${_habits.length}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.subtitleColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROGRESSO HOJE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _completedCount == 0
                      ? 'Nenhuma atividade ainda'
                      : '$_completedCount de ${_habits.length} hábitos feitos!',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _completedCount == _habits.length
                      ? 'Excelente trabalho hoje! 🎉'
                      : 'Continue cuidando da sua rotina!',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewTaskButton() {
  return Container(
    width: double.infinity,
    height: 52,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
      ),
    ),
    child: ElevatedButton(
      onPressed: () async {
        final HabitModel? createdHabit = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddHabitScreen()),
        );

        if (createdHabit != null) {
          setState(() {
            _habits.add(createdHabit);
          });
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_rounded, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            'Nova Tarefa',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilterIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(colors: [AppTheme.gradientStart, AppTheme.gradientEnd])
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.subtitleColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHabitsList() {
  return StreamBuilder<List<HabitModel>>(
    stream: HabitService().getHabitsStream(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Erro: ${snapshot.error}'));
      }

      final habits = snapshot.data ?? [];

      if (habits.isEmpty) {
        return const Center(
          child: Text(
            'Nenhum hábito cadastrado ainda.',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      // 🟢 Se estiver dentro de um SingleChildScrollView na tela, use shrinkWrap e physics
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: habits.length,
        itemBuilder: (context, index) {
          return _buildHabitCard(habits[index]);
        },
      );
    },
  );
}

 Widget _buildHabitCard(HabitModel habit) {
  final isDone = habit.status != HabitStatus.pendente;
  final isAlta = habit.priority == HabitPriority.alta;

  String statusText = 'Pendente';
  if (habit.status == HabitStatus.concluido) statusText = 'Concluído';
  if (habit.status == HabitStatus.compensado) statusText = 'Compensado';

  // 🟢 Fallbacks seguros para evitar widgets com dimensão nula (0x0)
  final IconData safeIcon = habit.icon ?? Icons.task_alt_rounded;
  final Color safeBgColor = habit.iconBgColor ?? const Color(0xFFEEF2FF);

  return AnimatedOpacity(
    duration: const Duration(milliseconds: 300),
    opacity: isDone ? 0.5 : 1.0,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12), // Margem de separação entre cartões
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: safeBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(safeIcon, color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${habit.time ?? "08:00"} - ${habit.durationMinutes ?? 15} min - ${habit.category}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.subtitleColor),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAlta ? const Color(0xFFFEE2E2) : const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAlta ? 'Alta' : 'Média',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAlta ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: isDone ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDone ? const Color(0xFF10B981) : AppTheme.subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFFCBD5E1)),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (!isDone) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _completeHabit(habit),
                    icon: const Icon(Icons.check, size: 18, color: AppTheme.primaryColor),
                    label: const Text(
                      'Concluir',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                Container(width: 1, height: 24, color: const Color(0xFFF1F5F9)),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showPlanBModal(habit),
                    icon: const Icon(Icons.subdirectory_arrow_right_rounded,
                        size: 18, color: AppTheme.subtitleColor),
                    label: const Text(
                      'Plano B',
                      style: TextStyle(
                        color: AppTheme.subtitleColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Análise',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1º MODAL SHEET: O que aconteceu?
// ---------------------------------------------------------------------------
class _PlanBReasonSheet extends StatelessWidget {
  final HabitModel habit;
  final Function(String reason) onReasonSelected;

  const _PlanBReasonSheet({
    required this.habit,
    required this.onReasonSelected,
  });

  @override
  Widget build(BuildContext context) {
    final reasons = [
      {'title': 'Falta de tempo', 'icon': Icons.access_time_rounded},
      {'title': 'Cansaço', 'icon': Icons.nightlight_round_outlined},
      {'title': 'Imprevisto', 'icon': Icons.bolt_rounded},
      {'title': 'Falta de motivação', 'icon': Icons.favorite_border_rounded},
      {'title': 'Esquecimento', 'icon': Icons.notifications_none_rounded},
      {'title': 'Problema de saúde', 'icon': Icons.medical_services_outlined},
      {'title': 'Outro motivo', 'icon': Icons.edit_outlined},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'O que aconteceu?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sem julgamentos — isso nos ajuda a entender seus padrões.',
            style: TextStyle(fontSize: 13, color: AppTheme.subtitleColor),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: reasons.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = reasons[index];
                return InkWell(
                  onTap: () => onReasonSelected(item['title'] as String),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item['icon'] as IconData, size: 18, color: const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2º MODAL SHEET: Escolha uma alternativa
// ---------------------------------------------------------------------------
class _PlanBOptionsSheet extends StatefulWidget {
  final HabitModel habit;
  final String reason;
  final Function(String selectedOption) onConfirm;

  const _PlanBOptionsSheet({
    required this.habit,
    required this.reason,
    required this.onConfirm,
  });

  @override
  State<_PlanBOptionsSheet> createState() => _PlanBOptionsSheetState();
}

class _PlanBOptionsSheetState extends State<_PlanBOptionsSheet> {
  String? _selectedOption;

  // Título constante para a opção de adiar
  static const String _postponeOptionTitle = 'Adiar para amanhã';

  @override
  Widget build(BuildContext context) {
    // Unifica as opções personalizadas do hábito com a opção fixa de adiar
    final List<PlanBOption> allOptions = [
      ...widget.habit.planBOptions,
      PlanBOption(
        title: _postponeOptionTitle,
        subtitle: 'Reagendar esta execução para o dia seguinte',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escolha uma alternativa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4338CA),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Substituição para: ${widget.habit.title}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ...allOptions.map((option) {
            final isSelected = _selectedOption == option.title;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedOption = option.title;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4338CA)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? const Color(0xFF4338CA).withValues(alpha: 0.05)
                        : Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4338CA)
                                : const Color(0xFFCBD5E1),
                            width: isSelected ? 6 : 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: option.title == _postponeOptionTitle
                                    ? const Color(0xFFD97706) // Destaque sutil para adiar
                                    : Colors.black87,
                              ),
                            ),
                            if (option.subtitle.isNotEmpty)
                              Text(
                                option.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedOption == null
                  ? null
                  : () {
                      final selected = _selectedOption!;
                      // 1. Fecha o Modal Bottom Sheet primeiro
                      Navigator.of(context).pop();
                      
                      // 2. Executa a callback de confirmação enviada pela HomeScreen
                      widget.onConfirm(selected);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirmar e Concluir',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

