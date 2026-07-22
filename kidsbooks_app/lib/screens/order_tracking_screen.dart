import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/order.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return Center(child: Text(loc.signInPrompt));
    final orders = ref.watch(userOrdersProvider(uid));

    return SafeArea(
      child: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(child: Text(loc.noOrders))
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(loc.navOrders,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  for (final order in list) _OrderCard(order: order),
                ],
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final BookOrder order;

  static const _physicalFlow = [
    OrderStatus.paid,
    OrderStatus.packing,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    String label(OrderStatus s) => switch (s) {
          OrderStatus.paid => loc.statusPaid,
          OrderStatus.packing => loc.statusPacking,
          OrderStatus.shipped => loc.statusShipped,
          OrderStatus.delivered => loc.statusDelivered,
          OrderStatus.cancelled => loc.statusCancelled,
          _ => loc.statusPending,
        };

    final reachedIdx = _physicalFlow.indexOf(order.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('#${order.id.substring(0, 8).toUpperCase()} · ${label(order.status)}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (order.hasPhysical && reachedIdx >= 0)
              Row(children: [
                for (var i = 0; i < _physicalFlow.length; i++) ...[
                  CircleAvatar(
                    radius: 13,
                    backgroundColor:
                        i <= reachedIdx ? KBColors.teal : KBColors.cream,
                    child: Icon(
                        i <= reachedIdx
                            ? Icons.check_rounded
                            : Icons.circle_outlined,
                        size: 14,
                        color: i <= reachedIdx ? Colors.white : Colors.grey),
                  ),
                  if (i < _physicalFlow.length - 1)
                    Expanded(
                        child: Container(
                            height: 3,
                            color: i < reachedIdx
                                ? KBColors.teal
                                : KBColors.cream)),
                ],
              ]),
            const SizedBox(height: 10),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text('${item.titleSnapshot} ×${item.qty}')),
                    if (item.format == 'ebook' &&
                        order.status != OrderStatus.pendingPayment)
                      TextButton(
                        onPressed: () =>
                            context.push('/read/${item.bookId}'),
                        child: Text(loc.readNow),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
