import 'package:flutter_test/flutter_test.dart';
import 'package:integra/features/auth/domain/auth_validators.dart';

void main() {
  group('validarEmail', () {
    test('aceita e-mail bem formado', () {
      expect(validarEmail('aluno@fatec.sp.gov.br'), isNull);
      expect(validarEmail('  aluno@exemplo.com  '), isNull);
    });

    test('recusa vazio', () {
      expect(validarEmail(''), 'E-mail não pode ficar em branco');
      expect(validarEmail(null), 'E-mail não pode ficar em branco');
      expect(validarEmail('   '), 'E-mail não pode ficar em branco');
    });

    test('recusa formatos inválidos', () {
      for (final invalido in ['aluno', 'aluno@', '@exemplo.com', 'a@b.c']) {
        expect(
          validarEmail(invalido),
          'Insira um e-mail válido (ex: usuario@exemplo.com)',
          reason: 'esperava recusar "$invalido"',
        );
      }
    });

    test('usa a regra estrita nos dois fluxos, não a permissiva do cadastro', () {
      // 'a@b.c' passava no regex de cadastrar_controller e falhava no de
      // login_controller — o usuário cadastrava e depois não conseguia entrar.
      expect(validarEmail('a@b.c'), isNotNull);
    });
  });

  group('validarSenha', () {
    test('aceita senha no comprimento mínimo', () {
      expect(validarSenha('a' * senhaComprimentoMinimo), isNull);
    });

    test('recusa vazia', () {
      expect(validarSenha(''), 'Senha não pode ficar em branco');
      expect(validarSenha(null), 'Senha não pode ficar em branco');
    });

    test('recusa abaixo do mínimo', () {
      expect(
        validarSenha('a' * (senhaComprimentoMinimo - 1)),
        'Senha deve ter no mínimo $senhaComprimentoMinimo caracteres',
      );
    });
  });

  group('validarConfirmacaoSenha', () {
    test('aceita quando as duas coincidem', () {
      expect(validarConfirmacaoSenha('segredo1', 'segredo1'), isNull);
    });

    test('recusa quando divergem', () {
      expect(
        validarConfirmacaoSenha('segredo1', 'segredo2'),
        'As senhas não correspondem',
      );
    });
  });

  group('validarNomeCompleto', () {
    test('aceita dois nomes ou mais', () {
      expect(validarNomeCompleto('Ana Souza'), isNull);
      expect(validarNomeCompleto('Ana Paula de Souza'), isNull);
    });

    test('recusa nome único, vazio ou só espaços', () {
      const erro = 'Nome completo deve ter pelo menos 2 nomes';
      expect(validarNomeCompleto('Ana'), erro);
      expect(validarNomeCompleto(''), erro);
      expect(validarNomeCompleto('   '), erro);
    });

    test('não conta espaços repetidos como nome extra', () {
      expect(validarNomeCompleto('Ana    '), isNotNull);
    });
  });

  group('validarUsername', () {
    test('aceita letras, números e underscore', () {
      expect(validarUsername('ana_souza'), isNull);
      expect(validarUsername('ana2024'), isNull);
    });

    test('recusa com menos de 3 caracteres', () {
      expect(validarUsername('an'), 'Username deve ter pelo menos 3 caracteres');
      expect(validarUsername(''), 'Username deve ter pelo menos 3 caracteres');
      expect(validarUsername(null), 'Username deve ter pelo menos 3 caracteres');
    });

    test('recusa caracteres fora do conjunto permitido', () {
      const erro = 'Username pode conter apenas letras, números e underscore';
      expect(validarUsername('ana.souza'), erro);
      expect(validarUsername('ana souza'), erro);
      expect(validarUsername('ana-souza'), erro);
    });
  });

  group('validarTelefone', () {
    test('aceita os formatos que o protótipo aceitava', () {
      for (final valido in [
        '(16)99999-9999',
        '16999999999',
        '16 99999-9999',
        '1699999999',
      ]) {
        expect(validarTelefone(valido), isNull, reason: 'esperava aceitar "$valido"');
      }
    });

    test('recusa vazio e malformado', () {
      const erro =
          'Telefone inválido. Use o formato (XX)XXXXX-XXXX ou XXXXXXXXXXX';
      expect(validarTelefone(''), erro);
      expect(validarTelefone(null), erro);
      expect(validarTelefone('99999'), erro);
      expect(validarTelefone('telefone'), erro);
    });
  });

  group('afiliação', () {
    test('exige universidade e curso selecionados', () {
      expect(validarUniversidadeSelecionada(null), 'Universidade é obrigatória');
      expect(validarUniversidadeSelecionada(''), 'Universidade é obrigatória');
      expect(validarUniversidadeSelecionada('uni-1'), isNull);

      expect(validarCursoSelecionado(null), 'Curso é obrigatório');
      expect(validarCursoSelecionado(''), 'Curso é obrigatório');
      expect(validarCursoSelecionado('curso-1'), isNull);
    });
  });
}
