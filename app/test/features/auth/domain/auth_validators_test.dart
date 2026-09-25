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

  group('validarFormacaoDeclarada', () {
    test('nenhum dos dois é válido: declarar formação é opcional na v2', () {
      // Na v1 os dois eram obrigatórios e a seleção concedia acesso aos posts
      // internos da instituição. Agora declarar é cosmético, e exigir no
      // cadastro só fazia todo mundo escolher a primeira faculdade da lista.
      expect(validarFormacaoDeclarada(), isNull);
      expect(
        validarFormacaoDeclarada(universidadeId: '', cursoId: ''),
        isNull,
      );
    });

    test('os dois juntos é válido', () {
      expect(
        validarFormacaoDeclarada(universidadeId: 'uni-1', cursoId: 'curso-1'),
        isNull,
      );
    });

    test('só um dos dois é recusado', () {
      // Meia formação é uma linha de currículo que nenhuma tela sabe exibir, e
      // o `auth-service` recusa pelo mesmo critério.
      expect(
        validarFormacaoDeclarada(universidadeId: 'uni-1'),
        'Escolha também o curso',
      );
      expect(
        validarFormacaoDeclarada(cursoId: 'curso-1'),
        'Escolha também a universidade',
      );
    });
  });

  group('validarCpf', () {
    test('aceita válido, com e sem pontuação', () {
      expect(validarCpf('39046350851'), isNull);
      expect(validarCpf('390.463.508-51'), isNull);
    });

    test('recusa vazio com mensagem própria', () {
      // "Obrigatório" e "inválido" são coisas diferentes para quem preenche:
      // uma diz que faltou, a outra que está errado.
      expect(validarCpf(''), 'CPF é obrigatório');
      expect(validarCpf(null), 'CPF é obrigatório');
    });

    test('recusa inválido com a mesma mensagem do serviço', () {
      expect(validarCpf('39046350852'), 'CPF inválido');
      expect(validarCpf('11111111111'), 'CPF inválido');
    });
  });

  group('validarCnpj', () {
    test('aceita válido, com e sem pontuação', () {
      expect(validarCnpj('46395000000139'), isNull);
      expect(validarCnpj('46.395.000/0001-39'), isNull);
    });

    test('recusa vazio e inválido', () {
      expect(validarCnpj(''), 'CNPJ é obrigatório');
      expect(validarCnpj('46395000000138'), 'CNPJ inválido');
    });
  });

  group('validarNomeDaInstituicao', () {
    test('aceita nome plausível', () {
      expect(validarNomeDaInstituicao('Faculdade de Tecnologia'), isNull);
    });

    test('recusa vazio e nome longo demais', () {
      expect(validarNomeDaInstituicao(''), 'Informe o nome da instituição');
      expect(
        validarNomeDaInstituicao('a' * 201),
        'Nome muito longo (máximo 200 caracteres)',
      );
    });
  });
}
