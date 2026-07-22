import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../services/firestore_service.dart';
import '../widgets/book_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _term = '';
  String? _ageBand;
  String? _bookLanguage;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final results = ref.watch(searchProvider(
        SearchQuery(term: _term, ageBand: _ageBand, bookLanguage: _bookLanguage)));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: loc.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none),
              ),
              onSubmitted: (v) => setState(() => _term = v.trim()),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final band in ['0-2', '3-5', '6-8', '9-12'])
                FilterChip(
                  label: Text(band),
                  selected: _ageBand == band,
                  onSelected: (sel) =>
                      setState(() => _ageBand = sel ? band : null),
                ),
            ]),
            const SizedBox(height: 6),
            Wrap(spacing: 8, children: [
              for (final code in supportedLanguageCodes)
                FilterChip(
                  label: Text(code.toUpperCase()),
                  selected: _bookLanguage == code,
                  onSelected: (sel) =>
                      setState(() => _bookLanguage = sel ? code : null),
                ),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: results.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (books) => books.isEmpty
                    ? Center(child: Text(loc.noResults))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.55),
                        itemCount: books.length,
                        itemBuilder: (_, i) => BookCard(book: books[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
