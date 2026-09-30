import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../data/auth_repository.dart';
import '../../models/expense_category.dart';
import '../../widgets/confirm_dialog.dart';
import '../expenses/expense_actions.dart';
import '../expenses/expenses_controller.dart';
import '../expenses/screens/expenses_view.dart';
import '../insights/insights_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _destinations = [
    (icon: Icons.receipt_long_outlined, selected: Icons.receipt_long_rounded, label: 'Expenses'),
    (icon: Icons.insights_outlined, selected: Icons.insights_rounded, label: 'Insights'),
  ];

  int _index = 0;

  void _showCategory(ExpenseCategory category) {
    context.read<ExpensesController>().setCategory(category);
    setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final body = _index == 0
        ? const ExpensesView()
        : InsightsView(onCategorySelected: _showCategory);

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_index].label),
        actions: const [_ThemeToggle(), _AccountMenu(), SizedBox(width: 8)],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (index) => setState(() => _index = index),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in _destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (index) => setState(() => _index = index),
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: d.label,
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openExpenseForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add expense'),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: isDark ? 'Light mode' : 'Dark mode',
      onPressed: () => context.read<ThemeController>().toggle(Theme.of(context).brightness),
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  Future<void> _signOut(BuildContext context) async {
    final auth = context.read<AuthRepository>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You can sign back in any time to see your expenses.',
      confirmLabel: 'Sign out',
    );
    if (confirmed) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.read<AuthRepository>().currentUser?.email ?? '';
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<void>(
      tooltip: 'Account',
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(email, style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () => _signOut(context),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded),
            title: Text('Sign out'),
          ),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: scheme.primaryContainer,
        child: Text(
          email.isEmpty ? '?' : email[0].toUpperCase(),
          style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
