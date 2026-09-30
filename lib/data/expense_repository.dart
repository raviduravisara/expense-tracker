import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

abstract interface class ExpenseRepository {
  Stream<List<Expense>> watchExpenses({required DateTime from, required DateTime to});

  Future<void> save(Expense expense);

  Future<void> delete(String id);
}

class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository({required this.userId, FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String userId;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection('users').doc(userId).collection('expenses');

  @override
  Stream<List<Expense>> watchExpenses({required DateTime from, required DateTime to}) {
    return _expenses
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('date', isLessThan: Timestamp.fromDate(to))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          final expenses = snapshot.docs.map((doc) => Expense.fromMap(doc.id, doc.data())).toList();
          expenses.sort((a, b) {
            final byDate = b.date.compareTo(a.date);
            return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
          });
          return expenses;
        });
  }

  @override
  Future<void> save(Expense expense) {
    final data = {...expense.toMap(), 'updatedAt': FieldValue.serverTimestamp()};
    if (expense.isNew) return _expenses.add(data);
    return _expenses.doc(expense.id).set(data);
  }

  @override
  Future<void> delete(String id) => _expenses.doc(id).delete();
}
