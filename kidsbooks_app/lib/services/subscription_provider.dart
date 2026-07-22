import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';
import 'firestore_service.dart';

class Subscription {
  final String plan;
  final DateTime? expiresAt;
  const Subscription({this.plan = 'annual', this.expiresAt});

  bool get isActive =>
      expiresAt != null && expiresAt!.isAfter(DateTime.now());

  factory Subscription.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const Subscription();
    return Subscription(
      plan: m['plan'] ?? 'annual',
      expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Streams the signed-in user's membership state from users/{uid}.
final subscriptionProvider = StreamProvider<Subscription>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const Subscription());
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => Subscription.fromMap(
          s.data()?['subscription'] as Map<String, dynamic>?));
});

final hasActiveMembershipProvider = Provider<bool>(
    (ref) => ref.watch(subscriptionProvider).value?.isActive ?? false);
