import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/habit_model.dart';
import '../../data/habit_service.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleController = TextEditingController();
  TimeOfDay? _selectedTime;
  String _selectedPeriod = 'Diário';
  bool _notificationsEnabled = true;
  String _selectedCategory = 'Saúde';
  String _selectedPriority = 'Sem';

  // Controle do Período (Semanal e Customizar)
  final List<int> _selectedDaysOfWeek = [1, 2, 3, 4, 5]; // 1 = Seg, 7 = Dom
  List<DateTime> _customDates = [];

  // Controladores para as Atividades de Compensação (Plano B)
  final List<TextEditingController> _planBControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  final List<String> _periods = ['Diário', 'Semanal', 'Customizar'];
  final List<String> _categories = ['Saúde', 'Estudos', 'Trabalho', 'Lazer'];
  final List<String> _priorities = ['Alta', 'Média', 'Baixa', 'Sem'];

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _planBControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlanBField() {
    setState(() {
      _planBControllers.add(TextEditingController());
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveHabit() async {
  if (_titleController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor, informe o nome do hábito.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  // Coleta as opções de Plano B preenchidas pelo usuário
  final List<PlanBOption> planBList = _planBControllers
      .where((c) => c.text.trim().isNotEmpty)
      .map((c) => PlanBOption(
            title: c.text.trim(),
            subtitle: 'Atividade de compensação',
          ))
      .toList();

  HabitPriority priority = HabitPriority.media;
  if (_selectedPriority == 'Alta') priority = HabitPriority.alta;
  if (_selectedPriority == 'Baixa') priority = HabitPriority.baixa;

  // Define um ícone de acordo com a categoria
  IconData categoryIcon = Icons.task_alt_rounded;
  Color iconBgColor = const Color(0xFFEEF2FF);

  switch (_selectedCategory) {
    case 'Saúde':
      categoryIcon = Icons.fitness_center_rounded;
      iconBgColor = const Color(0xFFDCFCE7);
      break;
    case 'Estudos':
      categoryIcon = Icons.menu_book_rounded;
      iconBgColor = const Color(0xFFE0F2FE);
      break;
    case 'Trabalho':
      categoryIcon = Icons.work_outline_rounded;
      iconBgColor = const Color(0xFFFEF3C7);
      break;
    case 'Lazer':
      categoryIcon = Icons.sports_esports_outlined;
      iconBgColor = const Color(0xFFFEE2E2);
      break;
  }

  final newHabit = HabitModel(
    id: '', // O Firestore gera a chave do documento
    title: _titleController.text.trim(),
    time: _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : '08:00',
    durationMinutes: 15,
    category: _selectedCategory,
    priority: priority,
    status: HabitStatus.pendente,
    icon: categoryIcon,
    iconBgColor: iconBgColor,
    planBOptions: planBList,
  );

  try {
    // 🟢 Chaves enviadas para o Firestore
    await HabitService().addHabit(newHabit);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hábito cadastrado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Fecha o modal/tela após guardar
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar no Firebase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4338CA)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Novo Hábito',
          style: TextStyle(
            color: Color(0xFF4338CA),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _saveHabit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                elevation: 0,
              ),
              child: const Text(
                'Salvar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Nome do Hábito',
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Ex: Meditar, Exercícios, Ler...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Horário',
              child: InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _selectedTime != null
                        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                        : '--:--',
                    style: TextStyle(
                      fontSize: 15,
                      color: _selectedTime != null ? AppTheme.textColor : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Período',
              child: Column(
                children: [
                  Row(
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPeriod = period),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Center(
                                child: Text(
                                  period,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textColor,
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  // Exibição condicional de acordo com a seleção de Período
                  if (_selectedPeriod == 'Semanal') ...[
                    const SizedBox(height: 16),
                    _buildWeeklyDaysPicker(),
                  ] else if (_selectedPeriod == 'Customizar') ...[
                    const SizedBox(height: 16),
                    _buildCustomDatePicker(context),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Atividades de Compensação',
              child: Column(
                children: [
                  ...List.generate(_planBControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _planBControllers[index],
                              decoration: InputDecoration(
                                hintText: 'Atividade ${index + 1}',
                                hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide:
                                      const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addPlanBField,
                      icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                      label: const Text(
                        'Adicionar mais uma',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: '',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notificações',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Categoria',
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                    label: const Text(
                      'Nova Categoria',
                      style: TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: const BorderSide(color: AppTheme.primaryColor, style: BorderStyle.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Prioridade',
              child: Row(
                children: _priorities.map((prio) {
                  final isSelected = _selectedPriority == prio;
                  final isSem = prio == 'Sem';

                  Color activeColor = AppTheme.primaryColor;
                  if (isSem && isSelected) activeColor = const Color(0xFF94A3B8);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPriority = prio),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? activeColor : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? activeColor : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isSem)
                                Icon(
                                  Icons.local_offer_outlined,
                                  size: 12,
                                  color: isSelected ? Colors.white : AppTheme.subtitleColor,
                                ),
                              if (!isSem) const SizedBox(width: 4),
                              Text(
                                prio,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppTheme.textColor,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets Auxiliares para Seleção de Dias da Semana e Calendário ---

  Widget _buildWeeklyDaysPicker() {
    final days = [
      {'label': 'S', 'value': 1},
      {'label': 'T', 'value': 2},
      {'label': 'Q', 'value': 3},
      {'label': 'Q', 'value': 4},
      {'label': 'S', 'value': 5},
      {'label': 'S', 'value': 6},
      {'label': 'D', 'value': 7},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final isSelected = _selectedDaysOfWeek.contains(day['value']);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                if (_selectedDaysOfWeek.length > 1) {
                  _selectedDaysOfWeek.remove(day['value']);
                }
              } else {
                _selectedDaysOfWeek.add(day['value'] as int);
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                day['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final DateTimeRange? pickedRange = await showDateRangePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryColor,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedRange != null) {
          setState(() {
            _customDates = List.generate(
              pickedRange.end.difference(pickedRange.start).inDays + 1,
              (index) => pickedRange.start.add(Duration(days: index)),
            );
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _customDates.isEmpty
                    ? 'Selecionar datas no calendário'
                    : '${_customDates.length} dias selecionados',
                style: TextStyle(
                  color: _customDates.isEmpty ? const Color(0xFF94A3B8) : AppTheme.textColor,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4338CA),
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}