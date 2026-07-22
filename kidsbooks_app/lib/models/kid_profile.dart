import 'package:cloud_firestore/cloud_firestore.dart';

class KidProfile {
  final String id;
  final String name;
  final String avatar; // emoji or asset key
  final int birthYear;
  final Map<String, int> lastReadPositions; // bookId -> page

  const KidProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.birthYear,
    this.lastReadPositions = const {},
  });

  /// Derived age band used to filter the catalog in Kid Mode.
  String get ageBand {
    final age = DateTime.now().year - birthYear;
    if (age <= 2) return '0-2';
    if (age <= 5) return '3-5';
    if (age <= 8) return '6-8';
    return '9-12';
  }

  factory KidProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return KidProfile(
      id: doc.id,
      name: d['name'] ?? '',
      avatar: d['avatar'] ?? '🦊',
      birthYear: (d['birthYear'] as num?)?.toInt() ?? DateTime.now().year - 5,
      lastReadPositions: Map<String, int>.from(d['lastReadPositions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'avatar': avatar,
        'birthYear': birthYear,
        'lastReadPositions': lastReadPositions,
      };
}
