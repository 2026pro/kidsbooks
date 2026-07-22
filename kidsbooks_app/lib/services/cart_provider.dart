import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';

class CartItem {
  final Book book;
  final BookFormat format;
  final int qty;
  const CartItem({required this.book, required this.format, this.qty = 1});

  int get unitPrice =>
      format == BookFormat.paper ? book.paper!.priceMnt : book.ebook!.priceMnt;
  int get lineTotal => unitPrice * qty;

  CartItem copyWith({int? qty}) =>
      CartItem(book: book, format: format, qty: qty ?? this.qty);
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  void add(Book book, BookFormat format) {
    final idx = state
        .indexWhere((i) => i.book.id == book.id && i.format == format);
    if (idx >= 0) {
      // Digital books: max qty 1.
      if (format == BookFormat.ebook) return;
      state = [
        for (var i = 0; i < state.length; i++)
          i == idx ? state[i].copyWith(qty: state[i].qty + 1) : state[i]
      ];
    } else {
      state = [...state, CartItem(book: book, format: format)];
    }
  }

  void setQty(CartItem item, int qty) {
    if (qty <= 0) {
      state = state.where((i) => i != item).toList();
    } else {
      state = [for (final i in state) i == item ? i.copyWith(qty: qty) : i];
    }
  }

  void clear() => state = const [];
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) => CartNotifier());

final cartSubtotalProvider = Provider<int>((ref) =>
    ref.watch(cartProvider).fold(0, (sum, i) => sum + i.lineTotal));

final cartHasPhysicalProvider = Provider<bool>((ref) =>
    ref.watch(cartProvider).any((i) => i.format == BookFormat.paper));
