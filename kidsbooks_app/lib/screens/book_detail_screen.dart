import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../services/cart_provider.dart';
import '../services/firestore_service.dart';
import '../services/subscription_provider.dart';

final _mnt = NumberFormat.currency(symbol: '₮', decimalDigits: 0);

class BookDetailScreen extends ConsumerStatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});
  final String bookId;

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  BookFormat _format = BookFormat.paper;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final bookAsync = ref.watch(bookProvider(widget.bookId));

    return Scaffold(
      appBar: AppBar(),
      body: bookAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (book) {
          final selected =
              _format == BookFormat.paper ? book.paper : book.ebook;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: book.coverUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: book.coverUrls.first,
                          width: 190, height: 240, fit: BoxFit.cover)
                      : Container(
                          width: 190, height: 240, color: KBColors.age35,
                          child: const Icon(Icons.menu_book_rounded, size: 72)),
                ),
              ),
              const SizedBox(height: 14),
              Text(book.title.resolve(locale),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900)),
              Text(
                  '${book.authors.join(', ')} · ★ ${book.ratingAvg.toStringAsFixed(1)} (${book.ratingCount})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: KBColors.muted)),
              const SizedBox(height: 14),
              Row(children: [
                if (book.paper != null)
                  Expanded(
                      child: _FormatCard(
                    label: loc.formatPaper,
                    icon: Icons.menu_book_rounded,
                    price: _mnt.format(book.paper!.priceMnt),
                    selected: _format == BookFormat.paper,
                    onTap: () => setState(() => _format = BookFormat.paper),
                  )),
                if (book.paper != null && book.ebook != null)
                  const SizedBox(width: 10),
                if (book.ebook != null)
                  Expanded(
                      child: _FormatCard(
                    label: loc.formatEbook,
                    icon: Icons.tablet_android_rounded,
                    price: _mnt.format(book.ebook!.priceMnt),
                    selected: _format == BookFormat.ebook,
                    onTap: () => setState(() => _format = BookFormat.ebook),
                  )),
              ]),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(book.description.resolve(locale)),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: selected == null
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).add(book, _format);
                        context.push('/cart');
                      },
                child: Text(
                    '${loc.addToCart} — ${_mnt.format(selected?.priceMnt ?? 0)}'),
              ),
              // Active members read any e-book without buying it.
              if (book.ebook != null &&
                  ref.watch(hasActiveMembershipProvider)) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: Text(loc.readWithMembership),
                  onPressed: () => context.push('/read/${book.id}'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.label,
    required this.icon,
    required this.price,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: selected ? KBColors.coral : Colors.transparent, width: 3),
        ),
        child: Column(children: [
          Icon(icon, color: KBColors.ink),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(price,
              style: const TextStyle(
                  color: KBColors.coral, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}
