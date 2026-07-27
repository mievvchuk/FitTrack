import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/core_providers.dart';

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

class LocaleController extends Notifier<Locale?> {
  static const storageKey = 'fittrack.locale';

  @override
  Locale? build() {
    _loadSavedLocale();
    return null;
  }

  Future<void> setLocale(Locale? locale) async {
    final storage = ref.read(secureStorageServiceProvider);
    if (locale == null) {
      await storage.delete(storageKey);
      state = null;
      return;
    }

    await storage.write(storageKey, locale.languageCode);
    state = locale;
  }

  Future<void> _loadSavedLocale() async {
    final storage = ref.read(secureStorageServiceProvider);
    final languageCode = await storage.read(storageKey);
    if (languageCode == null || languageCode.isEmpty) {
      return;
    }

    final locale = Locale(languageCode);
    if (isSupported(locale)) {
      state = locale;
    }
  }

  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }
}
