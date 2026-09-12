import 'package:integra/features/profile/data/models/perfil.dart';

/// Dados de exemplo para o app rodar sem backend.
///
/// São o que faz o portão desta sprint ser alcançável: app navegável ponta a
/// ponta e teste de widget na CI, sem servidor. Ficam em um arquivo só para
/// ninguém ter que caçar de onde veio um nome na tela.
///
/// A FATEC RP e ADS aparecem aqui de propósito: eram valores **hardcoded** nos
/// controllers do protótipo, aplicados a todo usuário. Agora são apenas dados
/// de exemplo, num lugar que se chama `fixtures`.
abstract final class Fixtures {
  static const emailDemo = 'ana@fatec.sp.gov.br';
  static const senhaDemo = 'integra123';

  static const fatecRp = Universidade(
    id: 'uni-fatec-rp',
    nome: 'Faculdade de Tecnologia de Ribeirão Preto',
    sigla: 'FATEC RP',
  );

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

  /// A conta com que o login de demonstração entra.
  static final perfilDemo = Perfil(
    id: 'user-ana',
    nomeCompleto: 'Ana Paula Souza',
    username: 'ana_souza',
    tipo: TipoConta.aluno,
    afiliacao: const Afiliacao(universidade: fatecRp, curso: ads),
    criadoEm: DateTime.utc(2026, 3, 12),
    email: emailDemo,
    telefone: '(16)99999-1234',
    bio: 'Estudante de ADS. Procurando estágio em back-end.',
  );

  /// Outros alunos, para a tela de busca ter o que mostrar.
  static final outrosAlunos = [
    Perfil(
      id: 'user-bruno',
      nomeCompleto: 'Bruno Carvalho Lima',
      username: 'brunocl',
      tipo: TipoConta.aluno,
      afiliacao: const Afiliacao(universidade: fatecRp, curso: ads),
      criadoEm: DateTime.utc(2026, 4, 2),
    ),
    Perfil(
      id: 'user-carla',
      nomeCompleto: 'Carla Ribeiro',
      username: 'carlar',
      tipo: TipoConta.aluno,
      afiliacao: const Afiliacao(
        universidade: fatecRp,
        curso: gestaoEmpresarial,
      ),
      criadoEm: DateTime.utc(2026, 2, 20),
    ),
    Perfil(
      id: 'user-fatec',
      nomeCompleto: 'FATEC Ribeirão Preto',
      username: 'fatec_rp',
      tipo: TipoConta.faculdade,
      afiliacao: const Afiliacao(universidade: fatecRp, curso: ads),
      criadoEm: DateTime.utc(2026, 1, 10),
    ),
  ];
}
