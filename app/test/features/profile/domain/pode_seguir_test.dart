import 'package:flutter_test/flutter_test.dart';

import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/features/profile/domain/pode_seguir.dart';

/// A matriz inteira, nove casos, afirmada de uma vez.
///
/// Uma tabela e não nove `test`: a regra é a matriz, e o que quebra quando alguém
/// mexer num ramo do `switch` é uma célula — ler qual delas no `reason` diz mais que
/// o nome de um teste.
void main() {
  test('a matriz de seguir', () {
    const esperado = <(TipoConta, TipoConta), bool>{
      (TipoConta.aluno, TipoConta.aluno): true,
      (TipoConta.aluno, TipoConta.faculdade): true,
      (TipoConta.aluno, TipoConta.empresa): true,

      // Faculdade só segue empresa: os alunos dela vêm pelo vínculo, e instituição
      // seguindo instituição não tem feed onde aparecer.
      (TipoConta.faculdade, TipoConta.aluno): false,
      (TipoConta.faculdade, TipoConta.faculdade): false,
      (TipoConta.faculdade, TipoConta.empresa): true,

      // Empresa não segue faculdade: o que a faculdade publica é comunicado do
      // pilar Acadêmico, que a conta empresa não tem.
      (TipoConta.empresa, TipoConta.aluno): true,
      (TipoConta.empresa, TipoConta.faculdade): false,
      (TipoConta.empresa, TipoConta.empresa): true,
    };

    for (final entrada in esperado.entries) {
      final (de, para) = entrada.key;
      expect(
        podeSeguir(de: de, para: para),
        entrada.value,
        reason: '${de.name} → ${para.name}',
      );
    }
  });
}
