import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';

void main() {
  runApp(
    // `ProviderScope` na raiz: é o que permite aos testes substituírem qualquer
    // dependência por `overrides`, sem servidor e sem keystore.
    ProviderScope(
      child: DevicePreview(
        enabled: kDebugMode,
        builder: (_) => const IntegraApp(),
      ),
    ),
  );
}

class IntegraApp extends ConsumerStatefulWidget {
  const IntegraApp({super.key});

  @override
  ConsumerState<IntegraApp> createState() => _IntegraAppState();
}

class _IntegraAppState extends ConsumerState<IntegraApp> {
  @override
  void initState() {
    super.initState();
    // Checa a sessão guardada uma vez, depois do primeiro frame. O roteador
    // segura na tela de carregamento até isto responder.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessaoProvider.notifier).restaurar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // `ShadApp.custom` em vez de `ShadApp`: é a forma de usar o `Router` do
    // go_router junto com o tema do shadcn. O `ShadAppBuilder` no `builder` é o
    // que injeta o tema abaixo do `MaterialApp`.
    return ShadApp.custom(
      themeMode: ThemeMode.system,
      theme: IntegraTheme.claro(),
      darkTheme: IntegraTheme.escuro(),
      appBuilder: (context) => MaterialApp.router(
        title: 'Integra',
        debugShowCheckedModeBanner: false,
        theme: Theme.of(context),
        routerConfig: router,
        locale: DevicePreview.locale(context),
        localizationsDelegates: const [
          GlobalShadLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        builder: (context, child) => ShadAppBuilder(
          child: DevicePreview.appBuilder(context, child),
        ),
      ),
    );
  }
}
