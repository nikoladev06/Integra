import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// O olho de revelar a senha, **dentro** do retângulo do campo.
///
/// É um builder, e não um `ShadInputFormField` embrulhado, porque os campos de
/// senha do app são de dois tipos: os dos formulários (`id`, `label`,
/// `validator`, `autofillHints`) e os soltos da troca de senha (`controller`).
/// Embrulhar os dois exigiria repassar a união dos parâmetros em duas classes
/// que divergiriam no primeiro parâmetro novo. O builder entrega só o que varia
/// — o estado e o botão — e cada campo continua escrito onde já estava.
///
/// O `trailing` do `ShadInput` fica na mesma `Row` que o texto, dentro da borda:
/// é o que põe o olho dentro do campo, e não ao lado dele.
class CampoDeSenha extends StatefulWidget {
  const CampoDeSenha({required this.construir, super.key});

  /// Recebe se o texto está oculto e o botão do olho — para `obscureText` e
  /// `trailing` do input, nessa ordem.
  final Widget Function(bool oculta, Widget olho) construir;

  @override
  State<CampoDeSenha> createState() => _CampoDeSenhaState();
}

class _CampoDeSenhaState extends State<CampoDeSenha> {
  /// Nasce oculta, e o estado morre com a tela. Uma senha que continuasse
  /// visível depois de navegar é o oposto do que o botão promete.
  bool _oculta = true;

  @override
  Widget build(BuildContext context) => widget.construir(
    _oculta,
    // 24x24 com padding zero: o padrão do `ShadIconButton` é 40, e como o
    // trailing entra na Row do campo, o campo inteiro cresceria com ele.
    //
    // O rótulo diz a **ação**, não o estado — é o que o toque faz —, e existe
    // porque ícone sozinho é botão sem nome para quem não enxerga. Mesmo
    // padrão do botão de escopo do feed.
    Tooltip(
      message: _oculta ? 'Mostrar senha' : 'Ocultar senha',
      child: ShadIconButton.ghost(
        width: 24,
        height: 24,
        padding: EdgeInsets.zero,
        icon: Icon(_oculta ? LucideIcons.eye : LucideIcons.eyeOff, size: 16),
        onPressed: () => setState(() => _oculta = !_oculta),
      ),
    ),
  );
}
