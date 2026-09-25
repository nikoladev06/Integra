import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Localiza um campo de formulário pelo rótulo visível, não por posição.
///
/// `ShadInputFormField` monta um `EditableText`, não o `TextField` do Material,
/// então os seletores usuais não o encontram. Buscar pelo rótulo mantém o teste
/// legível e não quebra quando a ordem dos campos muda — o que aconteceu duas
/// vezes nesta sprint, ao entrar o CPF no cadastro.
Finder campo(String rotulo) => find.descendant(
  of: find.ancestor(
    of: find.text(rotulo),
    matching: find.byType(ShadInputFormField),
  ),
  matching: find.byType(EditableText),
);
