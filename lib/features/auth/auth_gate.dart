import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/auth_repository.dart';
import '../../data/expense_repository.dart';
import '../../widgets/state_views.dart';
import '../expenses/expenses_controller.dart';
import '../home/home_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthRepository>();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      initialData: auth.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Scaffold(body: LoadingView());
        }

        final user = snapshot.data;
        if (user == null) return const SignInScreen();

        return MultiProvider(
          key: ValueKey(user.uid),
          providers: [
            Provider<ExpenseRepository>(
              create: (_) => FirestoreExpenseRepository(userId: user.uid),
            ),
            ChangeNotifierProvider(
              create: (context) => ExpensesController(context.read<ExpenseRepository>()),
            ),
          ],
          child: const HomeScreen(),
        );
      },
    );
  }
}
