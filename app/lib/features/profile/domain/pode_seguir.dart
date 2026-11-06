import 'package:integra/features/profile/data/models/perfil.dart';

/// Quem pode seguir quem. **A única definição disso no app.**
///
/// Seguir é registro de interesse: ele coloca o autor no feed de quem segue, e não
/// abre nada restrito — a mesma separação que o modelo v2 fez entre formação e
/// vínculo. Por isso a matriz é sobre *o que faz sentido aparecer no feed de quem*,
/// e não sobre permissão de leitura.
///
///     segue →        aluno   faculdade   empresa
///     aluno            sim      sim        sim
///     faculdade        não      não        sim
///     empresa          sim      não        sim
///
/// **Faculdade só segue empresa.** Ela alcança os alunos dela pelo vínculo, que é
/// outra coisa e não precisa de seguir; e uma instituição seguindo outra não tem
/// feed onde isso apareça.
///
/// **Empresa não segue faculdade.** O que uma faculdade publica é comunicado
/// institucional, do pilar Acadêmico — que a conta empresa não tem.
///
/// Seguir a si mesmo não é caso desta função: o próprio perfil não mostra o botão, e
/// o serviço recusa com 409. A tela passa por aqui só quando o perfil é de outra
/// conta.
bool podeSeguir({required TipoConta de, required TipoConta para}) =>
    switch ((de, para)) {
      (TipoConta.aluno, _) => true,
      (TipoConta.faculdade, TipoConta.empresa) => true,
      (TipoConta.faculdade, _) => false,
      (TipoConta.empresa, TipoConta.faculdade) => false,
      (TipoConta.empresa, _) => true,
    };
