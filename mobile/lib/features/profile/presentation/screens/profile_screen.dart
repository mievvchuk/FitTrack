import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final locale = ref.watch(localeControllerProvider);
    final user = authState.user;

    return AppScreen(
      title: l10n.profileTitle,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          CircleAvatar(
            radius: 36,
            child: Text(user?.email.substring(0, 1).toUpperCase() ?? 'F'),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? l10n.fitTrackUser,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(_languageLabel(l10n, locale)),
            onTap: () => _showLanguageSheet(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.premium),
            onTap: () => context.go(AppRoutes.payments),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOut),
            onTap: ref.read(authControllerProvider.notifier).signOut,
          ),
        ],
      ),
    );
  }
}

void _showLanguageSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, child) {
          final selectedLocale = ref.watch(localeControllerProvider);

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  title: Text(
                    l10n.language,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                RadioListTile<Locale?>(
                  value: null,
                  groupValue: selectedLocale,
                  title: Text(l10n.systemLanguage),
                  onChanged: (_) => _selectLocale(context, ref, null),
                ),
                RadioListTile<Locale?>(
                  value: const Locale('uk'),
                  groupValue: selectedLocale,
                  title: Text(l10n.ukrainian),
                  onChanged: (locale) => _selectLocale(context, ref, locale),
                ),
                RadioListTile<Locale?>(
                  value: const Locale('en'),
                  groupValue: selectedLocale,
                  title: Text(l10n.english),
                  onChanged: (locale) => _selectLocale(context, ref, locale),
                ),
                RadioListTile<Locale?>(
                  value: const Locale('de'),
                  groupValue: selectedLocale,
                  title: Text(l10n.german),
                  onChanged: (locale) => _selectLocale(context, ref, locale),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> _selectLocale(
  BuildContext context,
  WidgetRef ref,
  Locale? locale,
) async {
  await ref.read(localeControllerProvider.notifier).setLocale(locale);
  if (context.mounted) {
    Navigator.of(context).pop();
  }
}

String _languageLabel(AppLocalizations l10n, Locale? locale) {
  if (locale == null) {
    return l10n.systemLanguage;
  }

  return switch (locale.languageCode) {
    'uk' => l10n.ukrainian,
    'en' => l10n.english,
    'de' => l10n.german,
    _ => l10n.systemLanguage,
  };
}
