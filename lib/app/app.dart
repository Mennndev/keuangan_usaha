import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/domain/business_settings.dart';
import '../features/settings/presentation/providers/settings_providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class KeuanganUsahaApp extends ConsumerWidget {
  const KeuanganUsahaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileProvider);
    final themeMode = profile.maybeWhen(
      data: (value) => value?.theme.themeMode ?? ThemeMode.system,
      orElse: () => ThemeMode.system,
    );
    return MaterialApp.router(
      title: 'Keuangan Usaha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
