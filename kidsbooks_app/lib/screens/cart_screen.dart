import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/cart_provider.dart';
import '../services/qpay_service.dart';

final _mnt = NumberFormat.currency(symbol: '₮', decimalDigits: 0);

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _placing = false;

  Future<void> _checkout() async {
    final loc = AppLocalizations.of(context)!;
    final items = ref.read(cartProvider);
    final hasPhysical = ref.read(cartHasPhysicalProvider);

    // In a full build the address is picked on a dedicated screen; the
    // default address is used here for brevity.
    setState(() => _placing = true);
    try {
      final result = await ref.read(qpayServiceProvider).createOrder(
        items: [
          for (final i in items)
            {
              'bookId': i.book.id,
              'format': i.format.name,
              'qty': i.qty,
            }
        ],
        address: hasPhysical ? {'useDefault': true} : null,
      );
      ref.read(cartProvider.notifier).clear();
      if (mounted) context.push('/checkout/${result.orderId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.errorGeneric}: $e')));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final items = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final hasPhysical = ref.watch(cartHasPhysicalProvider);
    // Display-only estimate; the authoritative fee is computed server-side.
    final deliveryFee = hasPhysical ? 5000 : 0;

    return Scaffold(
      appBar: AppBar(title: Text(loc.cart)),
      body: items.isEmpty
          ? Center(child: Text(loc.cartEmpty))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                for (final item in items)
                  Card(
                    child: ListTile(
                      title: Text(
                          item.book.title.resolve(
                              Localizations.localeOf(context).languageCode),
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(
                          '${item.format.name} · ${_mnt.format(item.unitPrice)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .setQty(item, item.qty - 1)),
                          Text('${item.qty}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900)),
                          IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .setQty(item, item.qty + 1)),
                        ],
                      ),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _line(loc.subtotal, _mnt.format(subtotal)),
                      if (hasPhysical)
                        _line(loc.deliveryFee, _mnt.format(deliveryFee)),
                      const Divider(),
                      _line(loc.total, _mnt.format(subtotal + deliveryFee),
                          bold: true),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _placing ? null : _checkout,
                  child: _placing
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(loc.checkout),
                ),
              ],
            ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
        fontSize: bold ? 17 : 14,
        color: bold ? KBColors.coral : KBColors.ink);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: style)],
      ),
    );
  }
}
