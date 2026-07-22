import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/kid_profile.dart';
import '../models/order.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final featuredBooksProvider = StreamProvider<List<Book>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('books')
      .where('isActive', isEqualTo: true)
      .where('isFeatured', isEqualTo: true)
      .limit(12)
      .snapshots()
      .map((s) => s.docs.map(Book.fromDoc).toList());
});

final newBooksProvider = StreamProvider<List<Book>>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('books')
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(12)
      .snapshots()
      .map((s) => s.docs.map(Book.fromDoc).toList());
});

final bookProvider = StreamProvider.family<Book, String>((ref, id) {
  return ref
      .watch(firestoreProvider)
      .collection('books')
      .doc(id)
      .snapshots()
      .map(Book.fromDoc);
});

/// Simple search: prefix match on a lowercased keywords array field.
/// For production-grade full-text search plug in Algolia/Typesense.
final searchProvider =
    FutureProvider.family<List<Book>, SearchQuery>((ref, q) async {
  Query<Map<String, dynamic>> query = ref
      .watch(firestoreProvider)
      .collection('books')
      .where('isActive', isEqualTo: true);
  if (q.ageBand != null) query = query.where('ageBand', isEqualTo: q.ageBand);
  if (q.bookLanguage != null) {
    query = query.where('bookLanguage', isEqualTo: q.bookLanguage);
  }
  if (q.term.isNotEmpty) {
    query = query.where('keywords', arrayContains: q.term.toLowerCase());
  }
  final snap = await query.limit(30).get();
  return snap.docs.map(Book.fromDoc).toList();
});

class SearchQuery {
  final String term;
  final String? ageBand;
  final String? bookLanguage;
  const SearchQuery({this.term = '', this.ageBand, this.bookLanguage});

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.term == term &&
      other.ageBand == ageBand &&
      other.bookLanguage == bookLanguage;

  @override
  int get hashCode => Object.hash(term, ageBand, bookLanguage);
}

final userOrdersProvider =
    StreamProvider.family<List<BookOrder>, String>((ref, uid) {
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .where('uid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map(BookOrder.fromDoc).toList());
});

final orderProvider = StreamProvider.family<BookOrder, String>((ref, orderId) {
  return ref
      .watch(firestoreProvider)
      .collection('orders')
      .doc(orderId)
      .snapshots()
      .map(BookOrder.fromDoc);
});

final kidProfilesProvider =
    StreamProvider.family<List<KidProfile>, String>((ref, uid) {
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(uid)
      .collection('kidsProfiles')
      .snapshots()
      .map((s) => s.docs.map(KidProfile.fromDoc).toList());
});
