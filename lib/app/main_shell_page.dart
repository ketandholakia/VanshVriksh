import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/settings/app_settings_provider.dart';

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key, required this.child});

  final Widget child;

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    if (location.startsWith('/people')) return 1;
    if (location.startsWith('/tree') || location.startsWith('/fan-tree')) {
      return 2;
    }
    if (location.startsWith('/backup')) return 3;
    if (location.startsWith('/settings')) return 4;

    return 0;
  }

  void _onItemTapped(
    BuildContext context,
    int index,
    AppLandingView landingView,
  ) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/people');
        break;
      case 2:
        context.go(landingView == AppLandingView.fan ? '/fan-tree' : '/tree');
        break;
      case 3:
        context.go('/backup');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final landingView =
        ref.watch(appLandingViewProvider).value ?? appLandingViewDefault;
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          if (context.canPop()) {
            context.pop();
            return;
          }

          SystemNavigator.pop();
        },
        child: child,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            height: 72,
            backgroundColor: Colors.transparent,
            indicatorColor: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.58),
            onDestinationSelected: (index) =>
                _onItemTapped(context, index, landingView),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt),
                label: 'People',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_tree_outlined),
                selectedIcon: Icon(Icons.account_tree),
                label: 'Tree',
              ),
              NavigationDestination(
                icon: Icon(Icons.backup_outlined),
                selectedIcon: Icon(Icons.backup),
                label: 'Backup',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
