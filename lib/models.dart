// MODELOS DE DADOS (o que existe no app) + listas fixas + funções auxiliares.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/theme.dart';

// ---- Listas fixas ----
const motivos = [
  'Falta de tempo',
  'Cansaço',
  'Imprevisto',
  'Falta de motivação',
  'Esquecimento',
  'Problema de saúde',
  'Outro motivo',
];
const categorias = ['Saúde', 'Estudos', 'Trabalho', 'Lazer'];
const prioridades = ['Alta', 'Média', 'Baixa'];
const diasCurto = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const diasLongo = ['segundas', 'terças', 'quartas', 'quintas', 'sextas', 'sábados', 'domingos'];
const meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];

// ---- Funções auxiliares ----
// Transforma uma data em texto "2026-10-25" (usado como identificador do dia).
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String dataExtensa(DateTime d) {
  const nomes = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
  return '${nomes[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
}

IconData catIcon(String c) {
  switch (c) {
    case 'Estudos':
      return Icons.menu_book_outlined;
    case 'Trabalho':
      return Icons.work_outline;
    case 'Lazer':
      return Icons.sports_esports_outlined;
    default:
      return Icons.favorite_border;
  }
}

Color catColor(String c) {
  switch (c) {
    case 'Estudos':
      return const Color(0xFF60A5FA);
    case 'Trabalho':
      return const Color(0xFFFBBF24);
    case 'Lazer':
      return C.planb;
    default:
      return C.done;
  }
}

Color prioColor(String p) =>
    p == 'Alta' ? C.missed : (p == 'Média' ? const Color(0xFFFBBF24) : C.muted);

// Retorna o texto que mais se repete numa lista (ou null se vazia).
String? maisComum(Iterable<String> itens) {
  final cont = <String, int>{};
  for (final i in itens) {
    cont[i] = (cont[i] ?? 0) + 1;
  }
  if (cont.isEmpty) return null;
  return cont.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

// ---- HÁBITO ----
class Habit {
  final String id;
  final String name;
  final String? time; // "06:00" (opcional)
  final List<int> days; // dias da semana: 1 = Seg ... 7 = Dom
  final int? minutes; // opcional
  final String category;
  final String priority;
  final List<String> planB; // atividades de compensação

  Habit({
    this.id = '',
    required this.name,
    this.time,
    required this.days,
    this.minutes,
    required this.category,
    required this.priority,
    required this.planB,
  });

  factory Habit.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Habit(
      id: d.id,
      name: m['name'] ?? '',
      time: m['time'],
      days: m['days'] != null ? List<int>.from(m['days']) : [1, 2, 3, 4, 5, 6, 7],
      minutes: m['minutes'] as int?,
      category: m['category'] ?? 'Saúde',
      priority: m['priority'] ?? 'Média',
      planB: List<String>.from(m['planB'] ?? []),
    );
  }

  // Texto dos dias: "Todos os dias" ou "Seg, Qua, Sex"
  String get diasTexto => days.length == 7
      ? 'Todos os dias'
      : (List<int>.from(days)..sort()).map((d) => diasCurto[d - 1]).join(', ');

  Map<String, dynamic> toMap() => {
        'name': name,
        'time': time,
        'days': days,
        'minutes': minutes,
        'category': category,
        'priority': priority,
        'planB': planB,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// ---- REGISTRO DIÁRIO ----
// Uma linha por hábito por dia. status: 'done' | 'planb' | 'missed'
class HabitLog {
  final String habitId;
  final String date; // "2026-10-25"
  final String status;
  final String? reason; // motivo (quando não foi concluído)
  final String? planB; // atividade de compensação escolhida

  HabitLog({
    required this.habitId,
    required this.date,
    required this.status,
    this.reason,
    this.planB,
  });

  DateTime get day => DateTime.parse(date);

  factory HabitLog.fromMap(Map<String, dynamic> m) => HabitLog(
        habitId: m['habitId'] ?? '',
        date: m['date'] ?? '',
        status: m['status'] ?? 'done',
        reason: m['reason'],
        planB: m['planB'],
      );

  Map<String, dynamic> toMap() => {
        'habitId': habitId,
        'date': date,
        'status': status,
        'reason': reason,
        'planB': planB,
      };
}
