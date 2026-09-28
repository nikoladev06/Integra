import 'package:integra/features/academic/data/models/post.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// Dados de exemplo para o app rodar sem backend.
///
/// São a semente do [BancoFalso], não o estado dele: o banco copia daqui na
/// abertura e daí em diante muda com o uso. Ficam em um arquivo só para ninguém
/// ter que caçar de onde veio um nome na tela.
///
/// A FATEC RP e ADS aparecem aqui de propósito: eram valores **hardcoded** nos
/// controllers do protótipo, aplicados a todo usuário. Agora são apenas dados de
/// exemplo, num lugar que se chama `fixtures`.
///
/// Os CPF e CNPJ são estruturalmente válidos — gerados pelo mesmo algoritmo de
/// `integra_shared`. Precisam ser: o cadastro e o "inserir CPF" validam os
/// dígitos no cliente, e um número inventado à mão travaria a demonstração no
/// próprio formulário.
abstract final class Fixtures {
  static const emailDemo = 'ana@fatec.sp.gov.br';
  static const senhaDemo = 'integra123';

  /// A conta que ainda **não** tem vínculo. É com ela que se demonstra o fluxo
  /// inteiro: entrar, achar a FATEC na busca, inserir o CPF e ver a formação
  /// declarada ganhar o selo.
  static const emailSemVinculo = 'bruno@exemplo.com';
  static const senhaSemVinculo = 'integra123';

  /// A conta da FATEC: `faculdade` **ativada**. É com ela que se publica
  /// comunicado, cadastra curso e matricula aluno.
  ///
  /// Nomeada, e não escrita à mão onde é usada, porque três lugares precisam dela
  /// — a dica do login, os testes de administração e os do feed — e um literal
  /// repetido em três arquivos é o que faz renomear a conta virar caça ao erro.
  static const emailFaculdade = 'contato@fatecrp.edu.br';

  /// A conta de empresa, **pendente**. Serve para ver o aviso de análise e as
  /// recusas que ele explica.
  static const emailEmpresa = 'rh@orbita.com.br';

  /// Uma segunda aluna, com vínculo em outro curso da mesma faculdade. É o que
  /// distingue "não publicaram nada" de "não é do seu curso".
  static const emailOutroCurso = 'carla@exemplo.com';

  // ---------------------------- instituições ----------------------------

  static const fatecRp = Universidade(
    id: 'uni-fatec-rp',
    nome: 'Faculdade de Tecnologia de Ribeirão Preto',
    sigla: 'FATEC RP',
    // Tem conta institucional: publica, cadastra cursos e matricula.
    temConta: true,
  );

  /// Sem conta institucional — a tela precisa dizer isso em vez de mostrar um
  /// perfil vazio sem explicação, e é o caso mais comum no catálogo semeado.
  static const usp = Universidade(
    id: 'uni-usp',
    nome: 'Universidade de São Paulo',
    sigla: 'USP',
  );

  static const ads = Curso(
    id: 'curso-ads',
    nome: 'Análise e Desenvolvimento de Sistemas',
  );
  static const gestaoEmpresarial = Curso(
    id: 'curso-gestao',
    nome: 'Gestão Empresarial',
  );
  static const cienciaComputacao = Curso(
    id: 'curso-cc',
    nome: 'Ciência da Computação',
  );

  static const universidades = [fatecRp, usp];

  /// Cursos por universidade — o `GET /universidades/{id}/cursos` do contrato.
  static const cursosPorUniversidade = <String, List<Curso>>{
    'uni-fatec-rp': [ads, gestaoEmpresarial],
    'uni-usp': [cienciaComputacao],
  };

  // ------------------------------ documentos ------------------------------

  static const cpfAna = '39046350851';
  static const cpfBruno = '52998224725';
  static const cpfCarla = '11144477735';
  static const cnpjFatec = '46395000000139';
  static const cnpjEmpresa = '60746948000112';

  // -------------------------------- contas --------------------------------

  static final DateTime _verificadaEm = DateTime.utc(2026, 3, 12);

  /// A conta com que o login de demonstração entra: formação **verificada** e
  /// vínculo ativo com a FATEC.
  static final perfilDemo = Perfil(
    id: 'user-ana',
    nomeCompleto: 'Ana Paula Souza',
    username: 'ana_souza',
    tipo: TipoConta.aluno,
    criadoEm: DateTime.utc(2026, 3, 12),
    email: emailDemo,
    cpf: cpfAna,
    telefone: '(16)99999-1234',
    bio: 'Estudante de ADS. Procurando estágio em back-end.',
    formacoes: [
      Formacao(
        id: 'form-ana-ads',
        universidade: fatecRp,
        curso: ads,
        criadoEm: DateTime.utc(2026, 3, 12),
        verificadaEm: _verificadaEm,
      ),
    ],
    vinculo: Vinculo(
      universidade: fatecRp,
      curso: ads,
      criadoEm: _verificadaEm,
    ),
  );

  /// Declarou a formação e **não** tem vínculo: o selo está ausente, e é a
  /// diferença que o modelo da v2 existe para representar.
  static final perfilSemVinculo = Perfil(
    id: 'user-bruno',
    nomeCompleto: 'Bruno Carvalho Lima',
    username: 'brunocl',
    tipo: TipoConta.aluno,
    criadoEm: DateTime.utc(2026, 4, 2),
    email: emailSemVinculo,
    cpf: cpfBruno,
    telefone: '(16)98888-4321',
    formacoes: [
      Formacao(
        id: 'form-bruno-ads',
        universidade: fatecRp,
        curso: ads,
        criadoEm: DateTime.utc(2026, 4, 2),
      ),
    ],
  );

  static final perfilCarla = Perfil(
    id: 'user-carla',
    nomeCompleto: 'Carla Ribeiro',
    username: 'carlar',
    tipo: TipoConta.aluno,
    criadoEm: DateTime.utc(2026, 2, 20),
    email: emailOutroCurso,
    cpf: cpfCarla,
    telefone: '(16)97777-0000',
    formacoes: [
      Formacao(
        id: 'form-carla-gestao',
        universidade: fatecRp,
        curso: gestaoEmpresarial,
        criadoEm: DateTime.utc(2026, 2, 20),
        verificadaEm: _verificadaEm,
      ),
    ],
    vinculo: Vinculo(
      universidade: fatecRp,
      curso: gestaoEmpresarial,
      criadoEm: _verificadaEm,
    ),
  );

  /// A conta institucional da FATEC — ativada, e por isso capaz de matricular.
  static final perfilFatec = Perfil(
    id: 'user-fatec',
    nomeCompleto: 'FATEC Ribeirão Preto',
    username: 'fatec_rp',
    tipo: TipoConta.faculdade,
    criadoEm: DateTime.utc(2026, 1, 10),
    email: emailFaculdade,
    cnpj: cnpjFatec,
    telefone: '(16)3333-0000',
    bio: 'Faculdade de Tecnologia de Ribeirão Preto.',
    ativadaEm: DateTime.utc(2026, 1, 12),
  );

  /// Conta de empresa **pendente**: entrou, vê o próprio perfil e recebe o aviso
  /// de análise. É o estado em que toda conta institucional nasce.
  static final perfilEmpresa = Perfil(
    id: 'user-empresa',
    nomeCompleto: 'Órbita Tecnologia',
    username: 'orbita_tech',
    tipo: TipoConta.empresa,
    criadoEm: DateTime.utc(2026, 5, 4),
    email: emailEmpresa,
    cnpj: cnpjEmpresa,
    telefone: '(16)3222-1111',
    bio: 'Software house em Ribeirão Preto.',
  );

  static List<Perfil> get contas => [
    perfilDemo,
    perfilSemVinculo,
    perfilCarla,
    perfilFatec,
    perfilEmpresa,
  ];

  /// E-mail → senha, para o [FakeAuthRepository].
  static Map<String, String> get senhas => {
    emailDemo: senhaDemo,
    emailSemVinculo: senhaSemVinculo,
    emailOutroCurso: senhaDemo,
    emailFaculdade: senhaDemo,
    emailEmpresa: senhaDemo,
  };

  /// As matrículas que a FATEC cadastrou: CPF e curso, **sem conta de usuário
  /// atrelada**. É assim no banco também — a faculdade matricula quem ainda não
  /// tem conta, e o encontro acontece quando o aluno insere o CPF.
  static const matriculas =
      <(String universidadeId, String cpf, String cursoId)>[
        ('uni-fatec-rp', cpfAna, 'curso-ads'),
        ('uni-fatec-rp', cpfBruno, 'curso-ads'),
        ('uni-fatec-rp', cpfCarla, 'curso-gestao'),
      ];

  /// universidade → conta `faculdade` que a administra.
  ///
  /// No banco é `universidades.conta_id`. A USP não aparece aqui de propósito:
  /// ela existe no catálogo, pode ser seguida e declarada, e **não publica** —
  /// é o estado de toda universidade semeada sem ninguém a operando.
  static const contasInstitucionais = <String, String>{
    'uni-fatec-rp': 'user-fatec',
  };

  // ------------------------------- comunicados -------------------------------

  /// Os posts de exemplo do pilar Acadêmico, um por alcance.
  ///
  /// Os três existem para a demonstração mostrar a **diferença** que o modelo da
  /// v2 produz: entrando como Bruno (sem vínculo) aparece só o público; entrando
  /// como Ana (vínculo em ADS) aparecem os três; como Carla (vínculo em Gestão),
  /// dois — o restrito a ADS não é dela.
  ///
  /// Recebe o gerador de id do [BancoFalso] em vez de trazer ids fixos: o post é
  /// a primeira entidade que o app **cria** em quantidade, e id fixo colidiria
  /// com o do primeiro post publicado na sessão.
  static List<PostFalso> posts(String Function(String prefixo) proximoId) {
    final agora = DateTime.utc(2026, 9, 20, 10);

    return [
      PostFalso(
        id: proximoId('post'),
        universidadeId: fatecRp.id,
        autorId: perfilFatec.id,
        visibilidade: Visibilidade.publico,
        conteudo:
            'Inscrições abertas para o processo seletivo do próximo semestre. '
            'As provas acontecem no campus e o edital está no site da unidade.',
        criadoEm: agora,
      ),
      PostFalso(
        id: proximoId('post'),
        universidadeId: fatecRp.id,
        autorId: perfilFatec.id,
        visibilidade: Visibilidade.institucional,
        conteudo:
            'A biblioteca funcionará em horário reduzido na próxima semana, das '
            '9h às 16h, por causa do inventário anual do acervo.',
        criadoEm: agora.add(const Duration(hours: 3)),
      ),
      PostFalso(
        id: proximoId('post'),
        universidadeId: fatecRp.id,
        autorId: perfilFatec.id,
        visibilidade: Visibilidade.curso,
        cursoId: ads.id,
        conteudo:
            'A entrega do projeto integrador de ADS foi remarcada para o dia 30. '
            'O repositório precisa estar público até as 23h59.',
        criadoEm: agora.add(const Duration(hours: 6)),
      ),
    ];
  }
}
