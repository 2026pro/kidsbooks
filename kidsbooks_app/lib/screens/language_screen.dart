import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale_provider.dart';
import '../l10n/app_localizations.dart';

const _languageNames = {
  'mn': '🇲🇳 Монгол',
  'en': '🇬🇧 English',
  'fr': '🇫🇷 Français',
  'es': '🇪🇸 Español',
  'ko': '🇰🇷 한국어',
  'zh': '🇨🇳 中文',
  'ru': '🇷🇺 Русский',
};

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final current = ref.watch(localeProvider).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(loc.chooseLanguage)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          for (final code in supportedLanguageCodes)
            Card(
              child: ListTile(
                title: Text(_languageNames[code]!,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                trailing: current == code
                    ? const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2EC4B6))
                    : null,
                onTap: () =>
                    ref.read(localeProvider.notifier).setLocale(code),
              ),
            ),
          const SizedBox(height: 8),
          Text(loc.languageNote,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
