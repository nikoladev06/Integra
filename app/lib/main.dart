import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ponto de entrada mínimo: sem backend acoplado e sem segredos em `assets`.
///
/// O app real é construído no Sprint 2 — `ProviderScope`, `go_router` com
/// guarda de autenticação e tema por tokens entram lá. Até então, este arquivo
/// existe para manter o projeto compilando e a CI verde.
void main() {
  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (context) => const IntegraApp(),
    ),
  );
}

class IntegraApp extends StatelessWidget {
  const IntegraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'Integra',
      home: const PlaceholderHome(),
    );
  }
}

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logoappintegra.png', height: 96),
              const SizedBox(height: 24),
              Text('Integra', style: texto.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Base limpa. As telas entram no Sprint 2.',
                style: texto.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
