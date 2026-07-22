import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../services/firestore_service.dart';
import '../services/qpay_service.dart';

final _mnt = NumberFormat.currency(symbol: '₮', decimalDigits: 0);

/// QPay payment screen. Listens to the order doc in realtime: when the QPay
/// callback (server-side) flips status to `paid`, this screen auto-navigates
/// to order tracking. A manual "Check payment" button is the fallback.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final orderAsync = ref.watch(orderProvider(orderId));

    ref.listen(orderProvider(orderId), (prev, next) {
      final order = next.value;
      if (order != null && order.status != OrderStatus.pendingPayment) {
        context.go('/orders');
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(loc.payment)),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (order) => ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  Text('QPay — ${_mnt.format(order.total)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  if (order.qpay.qrText != null)
                    QrImageView(data: order.qpay.qrText!, size: 210),
                  const SizedBox(height: 8),
                  Text(loc.scanQr, textAlign: TextAlign.center),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            // Bank app deeplinks (same-device payment).
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final link in order.qpay.deeplinks)
                  ActionChip(
                    avatar: const Icon(Icons.account_balance_rounded, size: 16),
                    label: Text(Uri.parse(link).scheme),
                    onPressed: () =>
                        launchUrl(Uri.parse(link),
                            mode: LaunchMode.externalApplication),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final paid = await ref
                    .read(qpayServiceProvider)
                    .checkPayment(orderId);
                if (!paid && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.notPaidYet)));
                }
              },
              child: Text(loc.checkPayment),
            ),
            const SizedBox(height: 8),
            Center(
                child: Text(loc.autoConfirmNote,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}
