// ACESSO AO FIREBASE (banco de dados).
// Estrutura no Firestore:
//   users/{uid}/habits/{id}              -> os hábitos
//   users/{uid}/logs/{habitId_data}      -> um registro por hábito por dia
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models.dart';

class Repo {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static CollectionReference<Map<String, dynamic>> get _habits =>
      _db.collection('users').doc(_uid).collection('habits');
  static CollectionReference<Map<String, dynamic>> get _logs =>
      _db.collection('users').doc(_uid).collection('logs');

  // Streams = dados em tempo real (a tela atualiza sozinha).
  static Stream<List<Habit>> habits() => _habits.snapshots().map(
        (s) => s.docs.map(Habit.fromDoc).toList()..sort((a, b) => (a.time ?? '99:99').compareTo(b.time ?? '99:99')),
      );

  static Stream<List<HabitLog>> logs() =>
      _logs.snapshots().map((s) => s.docs.map((d) => HabitLog.fromMap(d.data())).toList());

  static Future<void> addHabit(Habit h) => _habits.add(h.toMap());

  // Atualiza um hábito existente (sem mexer na data de criação).
  static Future<void> updateHabit(String id, Habit h) {
    final dados = h.toMap()..remove('createdAt');
    return _habits.doc(id).update(dados);
  }

  static Future<void> deleteHabit(String id) => _habits.doc(id).delete();

  // O id do documento é "habito_data": registrar de novo no mesmo dia sobrescreve.
  static Future<void> saveLog(HabitLog l) => _logs.doc('${l.habitId}_${l.date}').set(l.toMap());

  static Future<void> deleteLog(String habitId, String date) =>
      _logs.doc('${habitId}_$date').delete();

  static Future<void> clearLogs() async {
    final docs = (await _logs.get()).docs;
    final batch = _db.batch();
    for (final d in docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  // DADOS DE EXEMPLO: cria hábitos (se não houver) e 35 dias de histórico.
  static Future<void> seed() async {
    var habits = (await _habits.get()).docs.map(Habit.fromDoc).toList();
    if (habits.isEmpty) {
      final demo = [
        Habit(name: 'Meditação', time: '06:00', days: [1, 2, 3, 4, 5, 6, 7], minutes: 15, category: 'Saúde', priority: 'Alta',
            planB: ['Respirar por 2 minutos', 'Alongamento em casa']),
        Habit(name: 'Exercício Físico', time: '07:00', days: [1, 3, 5], minutes: 45, category: 'Saúde', priority: 'Média',
            planB: ['Caminhada de 10 minutos', 'Alongamento em casa']),
        Habit(name: 'Estudar inglês', time: '19:00', days: [1, 2, 3, 4, 5], minutes: 30, category: 'Estudos', priority: 'Alta',
            planB: ['Ler uma notícia em inglês', 'Ouvir um podcast']),
        Habit(name: 'Leitura', time: '21:30', days: [1, 2, 3, 4, 5, 6, 7], minutes: 20, category: 'Lazer', priority: 'Média',
            planB: ['Ler 5 páginas', 'Ouvir um audiobook']),
      ];
      for (final h in demo) {
        await addHabit(h);
      }
      habits = (await _habits.get()).docs.map(Habit.fromDoc).toList();
    }

    final rnd = Random(7);
    // Motivos com pesos (mais "Falta de tempo" e "Cansaço").
    const pesos = {
      'Falta de tempo': 35, 'Cansaço': 25, 'Falta de motivação': 20, 'Imprevisto': 15, 'Outro motivo': 5,
    };
    String sorteiaMotivo() {
      var r = rnd.nextInt(100);
      for (final e in pesos.entries) {
        if (r < e.value) return e.key;
        r -= e.value;
      }
      return 'Outro motivo';
    }

    final batch = _db.batch();
    final hoje = DateTime.now();
    for (var i = 1; i <= 35; i++) {
      final dia = DateTime(hoje.year, hoje.month, hoje.day).subtract(Duration(days: i));
      for (final h in habits) {
        if (!h.days.contains(dia.weekday)) continue; // só nos dias programados
        // Chance de falhar: base 12%, sextas +20%, hábitos de lazer +8%.
        var p = 0.12;
        if (dia.weekday == DateTime.friday) p += 0.20;
        if (h.category == 'Lazer') p += 0.08;
        final key = dateKey(dia);
        HabitLog log;
        if (rnd.nextDouble() >= p || h.planB.isEmpty) {
          log = HabitLog(habitId: h.id, date: key, status: 'done');
        } else if (rnd.nextDouble() < 0.55) {
          log = HabitLog(habitId: h.id, date: key, status: 'planb',
              reason: sorteiaMotivo(), planB: h.planB[rnd.nextInt(h.planB.length)]);
        } else {
          log = HabitLog(habitId: h.id, date: key, status: 'missed', reason: sorteiaMotivo());
        }
        batch.set(_logs.doc('${h.id}_$key'), log.toMap());
      }
    }
    await batch.commit();
  }
}

// Widget que entrega "hábitos" e "registros" prontos para as telas.
// As streams são criadas uma vez só (initState) para não ficar recarregando.
class DataBuilder extends StatefulWidget {
  final Widget Function(BuildContext, List<Habit>, List<HabitLog>) builder;
  const DataBuilder({super.key, required this.builder});

  @override
  State<DataBuilder> createState() => _DataBuilderState();
}

class _DataBuilderState extends State<DataBuilder> {
  late final Stream<List<Habit>> _habits = Repo.habits();
  late final Stream<List<HabitLog>> _logs = Repo.logs();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Habit>>(
      stream: _habits,
      builder: (context, hs) => StreamBuilder<List<HabitLog>>(
        stream: _logs,
        builder: (context, ls) {
          final erro = hs.error ?? ls.error;
          if (erro != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erro ao ler o banco:\n$erro', textAlign: TextAlign.center),
              ),
            );
          }
          if (!hs.hasData || !ls.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return widget.builder(context, hs.data!, ls.data!);
        },
      ),
    );
  }
}
