import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../widgets/book_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final featured = ref.watch(featuredBooksProvider);
    final fresh = ref.watch(newBooksProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.homeGreeting,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900)),
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.workspace_premium_rounded),
                  tooltip: loc.membership,
                  onPressed: () => context.push('/membership'),
                ),
                IconButton(
                  icon: const Icon(Icons.language_rounded),
                  onPressed: () => context.push('/language'),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.go('/search'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                const Icon(Icons.search_rounded, color: Colors.grey),
                const SizedBox(width: 8),
                Text(loc.searchHint,
                    style: const TextStyle(color: Colors.grey)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(loc.featuredBooks),
          _BookRow(featured),
          const SizedBox(height: 16),
          _SectionTitle(loc.newArrivals),
          _BookRow(fresh),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      );
}

class _BookRow extends StatelessWidget {
  const _BookRow(this.books);
  final AsyncValue books;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) => BookCard(book: list[i]),
        ),
      ),
    );
  }
}
