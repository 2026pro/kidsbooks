import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/locale_provider.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/book_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/kids_profiles_screen.dart';
import 'screens/language_screen.dart';
import 'screens/membership_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/search_screen.dart';
import 'screens/shell_scaffold.dart';

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/search', builder: (c, s) => const SearchScreen()),
        GoRoute(path: '/orders', builder: (c, s) => const OrderTrackingScreen()),
        GoRoute(path: '/kids', builder: (c, s) => const KidsProfilesScreen()),
      ],
    ),
    GoRoute(
      path: '/book/:id',
      builder: (c, s) => BookDetailScreen(bookId: s.pathParameters['id']!),
    ),
    GoRoute(path: '/cart', builder: (c, s) => const CartScreen()),
    GoRoute(
      path: '/checkout/:orderId',
      builder: (c, s) => CheckoutScreen(orderId: s.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/read/:bookId',
      builder: (c, s) => ReaderScreen(bookId: s.pathParameters['bookId']!),
    ),
    GoRoute(path: '/language', builder: (c, s) => const LanguageScreen()),
    GoRoute(path: '/membership', builder: (c, s) => const MembershipScreen()),
  ],
);

class KidsBooksApp extends ConsumerWidget {
  const KidsBooksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'KidsBooks',
      debugShowCheckedModeBanner: false,
      theme: buildKidsBooksTheme(),
      routerConfig: _router,
      locale: locale,
      supportedLocales: const [
        Locale('mn'),
        Locale('en'),
        Locale('fr'),
        Locale('es'),
        Locale('ko'),
        Locale('zh'),
        Locale('ru'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
