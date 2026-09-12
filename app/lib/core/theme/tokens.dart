import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Os tokens de cor do Integra, em um lugar só.
///
/// No protótipo havia **521 cores e `TextStyle` literais** espalhados pelas
/// telas, cada uma redefinindo a própria paleta. Nenhum literal de cor deve
/// voltar a aparecer em widget: tudo passa por aqui, via
/// `ShadTheme.of(context).colorScheme`.
///
/// As cores são as mesmas dos documentos de escopo e de plano, então app e
/// documentação leem como um só produto.
abstract final class IntegraCores {
  // ---------- claro ----------
  static const fundoClaro = Color(0xFFF2F3F7);
  static const superficieClara = Color(0xFFFFFFFF);
  static const superficie2Clara = Color(0xFFE9EBF3);
  static const tintaClara = Color(0xFF171A2B);
  static const tintaSuaveClara = Color(0xFF4B4F66);
  static const apagadoClaro = Color(0xFF7B7F98);
  static const linhaClara = Color(0xFFDBDEEA);

  // ---------- escuro ----------
  static const fundoEscuro = Color(0xFF0F1120);
  static const superficieEscura = Color(0xFF171A2E);
  static const superficie2Escura = Color(0xFF1E2138);
  static const tintaEscura = Color(0xFFEDEEF7);
  static const tintaSuaveEscura = Color(0xFFB7BAD1);
  static const apagadoEscuro = Color(0xFF8589A4);
  static const linhaEscura = Color(0xFF2B2F4A);

  /// Azul do pilar Acadêmico. É também a cor primária do app.
  static const academicoClaro = Color(0xFF2F5FE0);
  static const academicoEscuro = Color(0xFF7C9CF5);

  /// Dourado do pilar Profissional.
  static const profissionalClaro = Color(0xFFC9861B);
  static const profissionalEscuro = Color(0xFFE3AC4E);

  /// Cinza do pilar Social — adiado, e a cor registra isso.
  static const socialClaro = Color(0xFF8B90A6);
  static const socialEscuro = Color(0xFF7B7F98);

  static const erroClaro = Color(0xFFB3402F);
  static const erroEscuro = Color(0xFFEF8875);

  static const okClaro = Color(0xFF1E7F52);
  static const okEscuro = Color(0xFF57C68C);
}

/// Chaves do mapa `custom` do `ShadColorScheme`.
///
/// O `ShadColorScheme` não tem campo para "cor de pilar", então elas entram
/// pelo mapa `custom` e saem pela extensão abaixo — que é o que faz o acesso
/// ficar igual ao das cores nativas.
abstract final class _Chaves {
  static const academico = 'academico';
  static const profissional = 'profissional';
  static const social = 'social';
  static const ok = 'ok';
  static const tintaSuave = 'tintaSuave';
}

/// Dá às cores do Integra o mesmo acesso das nativas:
/// `ShadTheme.of(context).colorScheme.academico`.
extension IntegraColorScheme on ShadColorScheme {
  Color get academico => custom[_Chaves.academico] ?? primary;
  Color get profissional => custom[_Chaves.profissional] ?? primary;
  Color get social => custom[_Chaves.social] ?? mutedForeground;
  Color get ok => custom[_Chaves.ok] ?? primary;

  /// Texto corrido — mais suave que `foreground`, mais legível que
  /// `mutedForeground`. O nível do meio que o shadcn não nomeia.
  Color get tintaSuave => custom[_Chaves.tintaSuave] ?? foreground;

  /// A cor do pilar, para widgets genéricos que recebem o pilar como parâmetro.
  Color doPilar(Pilar pilar) => switch (pilar) {
    Pilar.academico => academico,
    Pilar.profissional => profissional,
    Pilar.social => social,
  };
}

/// Os três pilares do escopo. `social` existe no enum mas não tem tela até a
/// Fase 4 — está aqui para o código não precisar mudar de forma quando entrar.
enum Pilar {
  academico('Acadêmico'),
  profissional('Profissional'),
  social('Social');

  const Pilar(this.rotulo);

  final String rotulo;
}

ShadColorScheme esquemaClaro() => const ShadSlateColorScheme.light(
  background: IntegraCores.fundoClaro,
  foreground: IntegraCores.tintaClara,
  card: IntegraCores.superficieClara,
  cardForeground: IntegraCores.tintaClara,
  popover: IntegraCores.superficieClara,
  popoverForeground: IntegraCores.tintaClara,
  primary: IntegraCores.academicoClaro,
  primaryForeground: IntegraCores.superficieClara,
  secondary: IntegraCores.superficie2Clara,
  secondaryForeground: IntegraCores.tintaClara,
  muted: IntegraCores.superficie2Clara,
  mutedForeground: IntegraCores.apagadoClaro,
  accent: IntegraCores.superficie2Clara,
  accentForeground: IntegraCores.tintaClara,
  destructive: IntegraCores.erroClaro,
  destructiveForeground: IntegraCores.superficieClara,
  border: IntegraCores.linhaClara,
  input: IntegraCores.linhaClara,
  ring: IntegraCores.academicoClaro,
  custom: {
    _Chaves.academico: IntegraCores.academicoClaro,
    _Chaves.profissional: IntegraCores.profissionalClaro,
    _Chaves.social: IntegraCores.socialClaro,
    _Chaves.ok: IntegraCores.okClaro,
    _Chaves.tintaSuave: IntegraCores.tintaSuaveClara,
  },
);

ShadColorScheme esquemaEscuro() => const ShadSlateColorScheme.dark(
  background: IntegraCores.fundoEscuro,
  foreground: IntegraCores.tintaEscura,
  card: IntegraCores.superficieEscura,
  cardForeground: IntegraCores.tintaEscura,
  popover: IntegraCores.superficieEscura,
  popoverForeground: IntegraCores.tintaEscura,
  primary: IntegraCores.academicoEscuro,
  // Texto sobre o azul claro do tema escuro precisa ser escuro, não branco —
  // inverter a paleta sem inverter o contraste é como se produz botão ilegível.
  primaryForeground: IntegraCores.fundoEscuro,
  secondary: IntegraCores.superficie2Escura,
  secondaryForeground: IntegraCores.tintaEscura,
  muted: IntegraCores.superficie2Escura,
  mutedForeground: IntegraCores.apagadoEscuro,
  accent: IntegraCores.superficie2Escura,
  accentForeground: IntegraCores.tintaEscura,
  destructive: IntegraCores.erroEscuro,
  destructiveForeground: IntegraCores.fundoEscuro,
  border: IntegraCores.linhaEscura,
  input: IntegraCores.linhaEscura,
  ring: IntegraCores.academicoEscuro,
  custom: {
    _Chaves.academico: IntegraCores.academicoEscuro,
    _Chaves.profissional: IntegraCores.profissionalEscuro,
    _Chaves.social: IntegraCores.socialEscuro,
    _Chaves.ok: IntegraCores.okEscuro,
    _Chaves.tintaSuave: IntegraCores.tintaSuaveEscura,
  },
);
