import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';

/// E-reader shell.
///
/// Production flow:
///  1. Callable function `getBookDownloadUrl` verifies the entitlement in
///     `library/{uid}/books/{bookId}` and returns a short-lived signed URL.
///  2. The file is downloaded once and stored AES-encrypted on device
///     (key in flutter_secure_storage) for offline reading.
///  3. EPUB renders via `epub_view`; fixed-layout picture books via `pdfx`.
///  4. Last-read page is synced to the active kid profile
///     (users/{uid}/kidsProfiles/{kid}.lastReadPositions[bookId]).
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.bookId});
  final String bookId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  int _page = 1;
  final int _pages = 48; // from book metadata after download

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF7),
      appBar: AppBar(
        title: Text('$_page / $_pages'),
        actions: [
          IconButton(
              icon: const Icon(Icons.text_fields_rounded), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.brightness_6_rounded), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Center(
                    // Placeholder page — replace with EpubView / PdfViewPinch
                    // wired to the decrypted local file.
                    child: Text(
                      loc.readerPlaceholder,
                      style: const TextStyle(fontSize: 17, height: 1.8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _page > 1
                      ? () => setState(() => _page--)
                      : null,
                  child: const Icon(Icons.chevron_left_rounded),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _page < _pages
                      ? () => setState(() => _page++)
                      : null,
                  child: const Icon(Icons.chevron_right_rounded),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
