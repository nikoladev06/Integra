import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/tokens.dart';

/// Os dois temas do app. Nenhuma tela constrói `ShadThemeData` própria.
abstract final class IntegraTheme {
  static ShadThemeData claro() => ShadThemeData(
    brightness: Brightness.light,
    colorScheme: esquemaClaro(),
  );

  static ShadThemeData escuro() => ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: esquemaEscuro(),
  );
}

/// Espaçamentos nomeados, na escala de 4.
///
/// Existe para o mesmo motivo dos tokens de cor: no protótipo cada tela
/// escolhia seus próprios `EdgeInsets`, e telas irmãs ficavam desalinhadas.
abstract final class Espaco {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
