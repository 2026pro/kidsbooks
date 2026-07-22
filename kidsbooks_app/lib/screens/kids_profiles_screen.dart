import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/kid_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class KidsProfilesScreen extends ConsumerWidget {
  const KidsProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final uid = ref.watch(currentUidProvider);
    if (uid == null) return Center(child: Text(loc.signInPrompt));
    final kids = ref.watch(kidProfilesProvider(uid));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(loc.kidsProfiles,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          kids.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (list) => Column(children: [
              for (final kid in list) _KidCard(kid: kid),
              if (list.length < 4)
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded),
                  label: Text(loc.addProfile),
                  onPressed: () => _showAddDialog(context, ref, uid),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          Card(
            color: const Color(0xFFFFF4D9),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(loc.kidModePinNote,
                  style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, String uid) {
    final loc = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.addProfile),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: loc.kidName)),
          TextField(
              controller: yearCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: loc.birthYear)),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          ElevatedButton(
            onPressed: () async {
              final year = int.tryParse(yearCtrl.text);
              if (nameCtrl.text.trim().isEmpty || year == null) return;
              await ref
                  .read(firestoreProvider)
                  .collection('users')
                  .doc(uid)
                  .collection('kidsProfiles')
                  .add(KidProfile(
                          id: '',
                          name: nameCtrl.text.trim(),
                          avatar: '🦊',
                          birthYear: year)
                      .toMap());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }
}

class _KidCard extends StatelessWidget {
  const _KidCard({required this.kid});
  final KidProfile kid;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: KBColors.sunshine,
            child: Text(kid.avatar, style: const TextStyle(fontSize: 20))),
        title: Text(kid.name,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(kid.ageBand),
        trailing: FilledButton.tonal(
          onPressed: () {
            // Enter Kid Mode: catalog filtered to kid.ageBand, purchases
            // disabled, PIN required to exit (see spec §2.2).
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${loc.kidMode}: ${kid.name}')));
          },
          child: Text(loc.kidMode),
        ),
      ),
    );
  }
}
