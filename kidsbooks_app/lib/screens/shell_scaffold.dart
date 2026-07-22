import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.child});
  final Widget child;

  static const _tabs = ['/home', '/search', '/orders', '/kids'];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere(location.startsWith).clamp(0, 3);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_rounded), label: loc.navHome),
          NavigationDestination(
              icon: const Icon(Icons.search_rounded), label: loc.navSearch),
          NavigationDestination(
              icon: const Icon(Icons.receipt_long_rounded),
              label: loc.navOrders),
          NavigationDestination(
              icon: const Icon(Icons.family_restroom_rounded),
              label: loc.navProfile),
        ],
      ),
    );
  }
}
