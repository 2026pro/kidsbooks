import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/book.dart';

final _mnt = NumberFormat.currency(symbol: '₮', decimalDigits: 0);

Color ageBandColor(String band) => switch (band) {
      '0-2' => KBColors.age02,
      '3-5' => KBColors.age35,
      '6-8' => KBColors.age68,
      _ => KBColors.age912,
    };

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final price = book.paper?.priceMnt ?? book.ebook?.priceMnt ?? 0;
    return GestureDetector(
      onTap: () => context.push('/book/${book.id}'),
      child: SizedBox(
        width: 132,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: book.coverUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book.coverUrls.first,
                        width: 132,
                        height: 160,
                        fit: BoxFit.cover)
                    : Container(
                        width: 132,
                        height: 160,
                        color: KBColors.age35,
                        child: const Icon(Icons.menu_book_rounded, size: 44)),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: ageBandColor(book.ageBand),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(book.ageBand,
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(book.title.resolve(locale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Row(children: [
              const Icon(Icons.star_rounded,
                  size: 15, color: KBColors.sunshine),
              Text(' ${book.ratingAvg.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 12)),
            ]),
            Text(_mnt.format(price),
                style: const TextStyle(
                    color: KBColors.coral, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
