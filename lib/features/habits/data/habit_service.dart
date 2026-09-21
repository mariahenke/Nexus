import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/habit_model.dart';

class HabitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Salva o hábito no Firestore associado ao ID do usuário atual
  Future<void> addHabit(HabitModel habit) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    await _db.collection('habits').add(habit.toMap(user.uid));
  }

  // Stream para ler os hábitos do usuário logado em tempo real
  Stream<List<HabitModel>> getHabitsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _db
        .collection('habits')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HabitModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}