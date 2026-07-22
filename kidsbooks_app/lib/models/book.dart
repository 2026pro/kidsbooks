import 'package:cloud_firestore/cloud_firestore.dart';

/// Localized string map, e.g. {"mn": "...", "en": "..."} with fallback chain
/// selected locale → en → mn → first available.
class LocalizedText {
  final Map<String, String> values;
  const LocalizedText(this.values);

  factory LocalizedText.fromMap(Map<String, dynamic>? map) =>
      LocalizedText((map ?? {}).map((k, v) => MapEntry(k, v.toString())));

  String resolve(String locale) =>
      values[locale] ??
      values['en'] ??
      values['mn'] ??
      (values.isNotEmpty ? values.values.first : '');

  Map<String, String> toMap() => values;
}

enum BookFormat { paper, ebook }

class FormatOffer {
  final int priceMnt;
  final int? stock; // paper only
  final String? fileFormat; // ebook: "epub" | "pdf"
  final String? filePath; // Storage path, entitlement-gated

  const FormatOffer({
    required this.priceMnt,
    this.stock,
    this.fileFormat,
    this.filePath,
  });

  factory FormatOffer.fromMap(Map<String, dynamic> m) => FormatOffer(
        priceMnt: (m['price'] as num).toInt(),
        stock: (m['stock'] as num?)?.toInt(),
        fileFormat: m['fileFormat'] as String?,
        filePath: m['filePath'] as String?,
      );
}

class Book {
  final String id;
  final LocalizedText title;
  final LocalizedText description;
  final List<String> authors;
  final List<String> coverUrls;
  final String bookLanguage; // language the book itself is written in
  final String ageBand; // "0-2" | "3-5" | "6-8" | "9-12"
  final List<String> categories;
  final FormatOffer? paper;
  final FormatOffer? ebook;
  final double ratingAvg;
  final int ratingCount;
  final bool isFeatured;

  const Book({
    required this.id,
    required this.title,
    required this.description,
    required this.authors,
    required this.coverUrls,
    required this.bookLanguage,
    required this.ageBand,
    required this.categories,
    this.paper,
    this.ebook,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.isFeatured = false,
  });

  factory Book.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final formats = (d['formats'] as Map<String, dynamic>?) ?? {};
    return Book(
      id: doc.id,
      title: LocalizedText.fromMap(d['title'] as Map<String, dynamic>?),
      description:
          LocalizedText.fromMap(d['description'] as Map<String, dynamic>?),
      authors: List<String>.from(d['authors'] ?? []),
      coverUrls: List<String>.from(d['coverUrls'] ?? []),
      bookLanguage: d['bookLanguage'] as String? ?? 'mn',
      ageBand: d['ageBand'] as String? ?? '3-5',
      categories: List<String>.from(d['categories'] ?? []),
      paper: formats['paper'] != null
          ? FormatOffer.fromMap(Map<String, dynamic>.from(formats['paper']))
          : null,
      ebook: formats['ebook'] != null
          ? FormatOffer.fromMap(Map<String, dynamic>.from(formats['ebook']))
          : null,
      ratingAvg: (d['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      isFeatured: d['isFeatured'] as bool? ?? false,
    );
  }
}
