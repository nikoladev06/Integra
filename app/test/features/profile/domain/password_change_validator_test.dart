import 'package:flutter_test/flutter_test.dart';
import 'package:integra/features/profile/domain/password_change_validator.dart';

void main() {
  group('validarTrocaDeSenha', () {
    test('aceita troca válida', () {
      expect(
        validarTrocaDeSenha(
          senhaAtual: 'antiga1',
          novaSenha: 'novaSenha1',
          confirmacao: 'novaSenha1',
        ),
        isEmpty,
      );
    });

    test('exige a senha atual', () {
      expect(
        validarTrocaDeSenha(
          senhaAtual: '',
          novaSenha: 'novaSenha1',
          confirmacao: 'novaSenha1',
        ),
        contains('Senha atual é obrigatória'),
      );
    });

    test('exige comprimento mínimo na nova senha', () {
      expect(
        validarTrocaDeSenha(
          senhaAtual: 'antiga1',
          novaSenha: '123',
          confirmacao: '123',
        ),
        contains('Nova senha deve ter pelo menos 6 caracteres'),
      );
    });

    test('exige confirmação idêntica', () {
      expect(
        validarTrocaDeSenha(
          senhaAtual: 'antiga1',
          novaSenha: 'novaSenha1',
          confirmacao: 'novaSenha2',
        ),
        contains('As senhas não correspondem'),
      );
    });

    test('recusa reutilizar a senha atual', () {
      expect(
        validarTrocaDeSenha(
          senhaAtual: 'mesmaSenha1',
          novaSenha: 'mesmaSenha1',
          confirmacao: 'mesmaSenha1',
        ),
        contains('A nova senha deve ser diferente da atual'),
      );
    });

    test('não acusa reutilização quando a senha atual está em branco', () {
      final erros = validarTrocaDeSenha(
        senhaAtual: '',
        novaSenha: '',
        confirmacao: '',
      );
      expect(erros, contains('Senha atual é obrigatória'));
      expect(erros, isNot(contains('A nova senha deve ser diferente da atual')));
    });

    test('acumula todos os erros de uma vez', () {
      expect(
        validarTrocaDeSenha(
          senhaAtual: '',
          novaSenha: '123',
          confirmacao: '456',
        ),
        hasLength(3),
      );
    });
  });
}
