import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../services/subscription_provider.dart';

final _mnt = NumberFormat.currency(symbol: '₮', decimalDigits: 0);

/// Annual membership: unlimited e-book reading while active.
/// Payment reuses the same QPay checkout screen as regular orders.
class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});
  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  bool _busy = false;
  static const _annualPrice = 99000; // display-only; server is authoritative

  Future<void> _subscribe() async {
    final loc = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('createSubscriptionOrder')
          .call();
      final orderId = (res.data as Map)['orderId'] as String;
      if (mounted) context.push('/checkout/$orderId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.errorGeneric}: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final sub = ref.watch(subscriptionProvider).value ?? const Subscription();
    final dateFmt = DateFormat.yMMMd(
        Localizations.localeOf(context).toLanguageTag());

    return Scaffold(
      appBar: AppBar(title: Text(loc.membership)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            color: KBColors.sunshine,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('👑', style: TextStyle(fontSize: 52)),
                Text(loc.membership,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(loc.membershipBenefit, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text('${loc.annualPlan} — ${_mnt.format(_annualPrice)}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          if (sub.isActive)
            Card(
              color: const Color(0xFFE6F9F1),
              child: ListTile(
                leading: const Icon(Icons.verified_rounded,
                    color: KBColors.teal),
                title: Text(loc.memberActive,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(
                    '${loc.memberUntil}: ${dateFmt.format(sub.expiresAt!)}'),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _busy ? null : _subscribe,
            child: _busy
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(sub.isActive ? loc.extendMembership : loc.subscribe),
          ),
          const SizedBox(height: 10),
          Text(loc.membershipRenewNote,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
