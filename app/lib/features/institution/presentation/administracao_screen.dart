import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/academic/presentation/academic_providers.dart';
import 'package:integra/features/auth/domain/auth_validators.dart';
import 'package:integra/features/auth/presentation/sessao_controller.dart';
import 'package:integra/features/profile/data/models/instituicao.dart';
import 'package:integra/features/profile/data/models/perfil.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// As matrículas da instituição, no filtro escolhido.
final matriculasProvider = FutureProvider.autoDispose
    .family<List<Matricula>, String>(
      (ref, situacao) => ref
          .watch(profileRepositoryProvider)
          .minhasMatriculas(situacao: situacao),
    );

/// Administração da própria instituição: cursos e matrículas.
///
/// **É a tela que faz o vínculo poder nascer.** Sem ela, a única forma de ter
/// matrícula no banco era rodar o seed — e o "inserir CPF" do aluno procurava numa
/// lista que ninguém conseguia preencher pelo app. Por isso ela é herança da
/// Sprint 3 e entra no pilar Acadêmico antes de qualquer feed.
///
/// Duas abas, e a ordem não é alfabética: **curso vem antes de matrícula** porque
/// matricular exige escolher um curso, e uma instituição sem curso cadastrado só
/// consegue fazer uma das duas coisas.
class AdministracaoScreen extends ConsumerWidget {
  const AdministracaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final perfil = ref.watch(perfilAtualProvider);

    return Scaffold(
      backgroundColor: tema.colorScheme.background,
      appBar: AppBar(
        title: const Text('Administração da instituição'),
        backgroundColor: tema.colorScheme.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: switch (perfil) {
        // O roteador já barra quem não é faculdade; isto cobre o instante entre a
        // sessão cair e o redirect acontecer, e evita um `!` que estouraria ali.
        null => const Center(child: CircularProgressIndicator()),
        Perfil(tipo: != TipoConta.faculdade) => const _SemPermissao(),
        Perfil(ativadaEm: null) => const _Pendente(),
        _ => const _Abas(),
      },
    );
  }
}

class _SemPermissao extends StatelessWidget {
  const _SemPermissao();

  @override
  Widget build(BuildContext context) => const EstadoVazio(
    icone: LucideIcons.lock,
    titulo: 'Só contas de faculdade',
    descricao:
        'Cursos e matrículas são administrados pela conta da instituição, '
        'cadastrada com CNPJ.',
  );
}

/// Conta institucional ainda em análise.
///
/// A recusa vem do **servidor**, que consulta o banco e não o token — uma conta
/// desativada com token válido seguiria matriculando por até 15 minutos. Esta tela
/// é só a versão legível dela: oferecer os formulários para depois receber 403 em
/// cada envio seria pior que dizer antes.
class _Pendente extends StatelessWidget {
  const _Pendente();

  @override
  Widget build(BuildContext context) => EstadoVazio(
    icone: LucideIcons.clock,
    cor: ShadTheme.of(context).colorScheme.academico,
    titulo: 'Sua instituição está em análise',
    descricao:
        'Enquanto a conta não é ativada, você entra e edita o perfil, mas não '
        'cadastra cursos, não matricula alunos e não publica comunicados. '
        'É o que impede que consultar um CNPJ público baste para distribuir '
        'formações verificadas no nome de uma faculdade.',
  );
}

class _Abas extends StatelessWidget {
  const _Abas();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Espaco.md),
    child: ShadTabs<String>(
      value: 'cursos',
      tabs: [
        ShadTab(
          value: 'cursos',
          content: const _Cursos(),
          child: const Text('Cursos'),
        ),
        ShadTab(
          value: 'matriculas',
          content: const _Matriculas(),
          child: const Text('Matrículas'),
        ),
      ],
    ),
  );
}

// ──────────────────────────────  cursos  ──────────────────────────────

class _Cursos extends ConsumerStatefulWidget {
  const _Cursos();

  @override
  ConsumerState<_Cursos> createState() => _CursosState();
}

class _CursosState extends ConsumerState<_Cursos> {
  final _nome = TextEditingController();
  String? _erro;
  bool _enviando = false;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    final nome = _nome.text.trim();
    if (nome.length < 2) {
      setState(
        () => _erro = 'O nome do curso precisa ter ao menos 2 caracteres',
      );
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(profileRepositoryProvider).criarCurso(nome);
      _nome.clear();
      ref.invalidate(meusCursosProvider);
      // A lista de matrículas mostra o nome do curso de cada linha, e o combobox
      // de matricular oferece os cursos: os dois leem `meusCursosProvider`, então
      // invalidar um só bastaria — mas a de matrículas também cai porque uma
      // linha com "Curso removido" precisa voltar a ter nome.
      ref.invalidate(matriculasProvider);
    } on FalhaDeValidacao catch (falha) {
      setState(() => _erro = falha.campos['nome']?.first ?? falha.mensagem);
    } on Failure catch (falha) {
      setState(() => _erro = falha.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _remover(Curso curso) async {
    try {
      await ref.read(profileRepositoryProvider).removerCurso(curso.id);
      ref.invalidate(meusCursosProvider);
      ref.invalidate(matriculasProvider);
    } on Failure catch (falha) {
      // A recusa esperada: curso com matrícula ou formação não sai, porque apagar
      // o curso apagaria o selo de quem se formou nele.
      if (mounted) {
        ShadToaster.of(context)
            .show(ShadToast.destructive(description: Text(falha.mensagem)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cursos = ref.watch(meusCursosProvider);

    return ShadCard(
      title: const Text('Cursos da instituição'),
      child: Padding(
        padding: const EdgeInsets.only(top: Espaco.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _nome,
                    placeholder: const Text('Nome do curso'),
                    onSubmitted: (_) => _criar(),
                  ),
                ),
                const SizedBox(width: Espaco.sm),
                ShadButton(
                  onPressed: _enviando ? null : _criar,
                  child: const Text('Adicionar'),
                ),
              ],
            ),
            if (_erro != null) ...[
              const SizedBox(height: Espaco.xs),
              Text(
                _erro!,
                style: tema.textTheme.muted.copyWith(
                  color: tema.colorScheme.destructive,
                ),
              ),
            ],
            const SizedBox(height: Espaco.md),

            switch (cursos) {
              AsyncError(:final error) => Text(
                error is Failure
                    ? error.mensagem
                    : 'Não foi possível carregar os cursos.',
                style: tema.textTheme.muted,
              ),
              AsyncLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              AsyncData(:final value) when value.isEmpty => Text(
                'Nenhum curso cadastrado. Sem curso não é possível matricular '
                'ninguém, porque toda matrícula aponta para um.',
                style: tema.textTheme.muted,
              ),
              AsyncData(:final value) => Column(
                children: [
                  for (final curso in value)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(curso.nome, style: tema.textTheme.p),
                      trailing: ShadIconButton.ghost(
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        onPressed: () => _remover(curso),
                      ),
                    ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────  matrículas  ────────────────────────────

class _Matriculas extends ConsumerStatefulWidget {
  const _Matriculas();

  @override
  ConsumerState<_Matriculas> createState() => _MatriculasState();
}

class _MatriculasState extends ConsumerState<_Matriculas> {
  final _cpf = TextEditingController();
  String? _cursoId;
  String? _erroDeCpf;
  String? _erroDeCurso;
  bool _enviando = false;

  /// `todas`, `pendentes` ou `vinculadas` — os valores do contrato.
  String _situacao = 'todas';

  @override
  void dispose() {
    _cpf.dispose();
    super.dispose();
  }

  Future<void> _matricular() async {
    final erroDeCpf = validarCpf(_cpf.text);
    setState(() {
      _erroDeCpf = erroDeCpf;
      _erroDeCurso = _cursoId == null ? 'Escolha o curso' : null;
    });
    if (erroDeCpf != null || _cursoId == null) return;

    setState(() => _enviando = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .criarMatricula(cpf: _cpf.text, cursoId: _cursoId!);
      _cpf.clear();
      ref.invalidate(matriculasProvider);

      if (mounted) {
        ShadToaster.of(context).show(
          const ShadToast(
            description: Text(
              'Matrícula cadastrada. O vínculo nasce quando essa pessoa '
              'informar o CPF no perfil da instituição.',
            ),
          ),
        );
      }
    } on FalhaDeValidacao catch (falha) {
      setState(() {
        _erroDeCpf = falha.campos['cpf']?.first;
        _erroDeCurso = falha.campos['cursoId']?.first;
      });
    } on Failure catch (falha) {
      setState(() => _erroDeCpf = falha.mensagem);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _remover(Matricula matricula) async {
    final confirmado = await showShadDialog<bool>(
      context: context,
      builder: (_) => ShadDialog.alert(
        title: const Text('Remover matrícula?'),
        description: Text(
          matricula.vinculada
              ? 'O vínculo de ${matricula.usuario?.nomeCompleto ?? 'quem tem esse CPF'} '
                    'com a instituição será encerrado. A formação continua '
                    'verificada no perfil — a pessoa realmente estudou aqui.'
              : 'Este CPF sai da lista de alunos. Ninguém o reivindicou ainda.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await ref.read(profileRepositoryProvider).removerMatricula(matricula.id);
      ref.invalidate(matriculasProvider);
    } on Failure catch (falha) {
      if (mounted) {
        ShadToaster.of(context)
            .show(ShadToast.destructive(description: Text(falha.mensagem)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cursos = ref.watch(meusCursosProvider);
    final matriculas = ref.watch(matriculasProvider(_situacao));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadCard(
          title: const Text('Matricular aluno'),
          child: Padding(
            padding: const EdgeInsets.only(top: Espaco.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShadInput(
                  controller: _cpf,
                  placeholder: const Text('000.000.000-00'),
                  keyboardType: TextInputType.number,
                ),
                if (_erroDeCpf != null) ...[
                  const SizedBox(height: Espaco.xs),
                  Text(
                    _erroDeCpf!,
                    style: tema.textTheme.muted.copyWith(
                      color: tema.colorScheme.destructive,
                    ),
                  ),
                ],
                const SizedBox(height: Espaco.sm),

                switch (cursos) {
                  AsyncData(:final value) when value.isEmpty => Text(
                    'Cadastre um curso na aba anterior antes de matricular: toda '
                    'matrícula aponta para um curso.',
                    style: tema.textTheme.muted,
                  ),
                  AsyncData(:final value) => ShadSelect<String>(
                    placeholder: const Text('Curso'),
                    initialValue: _cursoId,
                    onChanged: (valor) => setState(() {
                      _cursoId = valor;
                      _erroDeCurso = null;
                    }),
                    selectedOptionBuilder: (context, valor) =>
                        Text(value.firstWhere((c) => c.id == valor).nome),
                    options: [
                      for (final c in value)
                        ShadOption(value: c.id, child: Text(c.nome)),
                    ],
                  ),
                  _ => Text('Carregando cursos…', style: tema.textTheme.muted),
                },
                if (_erroDeCurso != null) ...[
                  const SizedBox(height: Espaco.xs),
                  Text(
                    _erroDeCurso!,
                    style: tema.textTheme.muted.copyWith(
                      color: tema.colorScheme.destructive,
                    ),
                  ),
                ],
                const SizedBox(height: Espaco.sm),
                ShadButton(
                  onPressed: _enviando ? null : _matricular,
                  child: const Text('Matricular'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Espaco.md),

        // O filtro que responde a pergunta da secretaria: quem ainda não entrou?
        Row(
          children: [
            Expanded(
              child: Text('Alunos cadastrados', style: tema.textTheme.small),
            ),
            ShadSelect<String>(
              initialValue: _situacao,
              minWidth: 150,
              onChanged: (valor) =>
                  setState(() => _situacao = valor ?? 'todas'),
              selectedOptionBuilder: (context, valor) =>
                  Text(_rotuloDaSituacao(valor)),
              options: const [
                ShadOption(value: 'todas', child: Text('Todas')),
                ShadOption(value: 'pendentes', child: Text('Sem vínculo')),
                ShadOption(value: 'vinculadas', child: Text('Com vínculo')),
              ],
            ),
          ],
        ),
        const SizedBox(height: Espaco.sm),

        switch (matriculas) {
          AsyncError(:final error) => Text(
            error is Failure
                ? error.mensagem
                : 'Não foi possível carregar as matrículas.',
            style: tema.textTheme.muted,
          ),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          AsyncData(:final value) when value.isEmpty => Text(
            _situacao == 'todas'
                ? 'Nenhum aluno cadastrado ainda.'
                : 'Nenhuma matrícula nesta situação.',
            style: tema.textTheme.muted,
          ),
          AsyncData(:final value) => Column(
            children: [
              for (final matricula in value)
                _LinhaDeMatricula(
                  matricula: matricula,
                  aoRemover: () => _remover(matricula),
                ),
            ],
          ),
        },
      ],
    );
  }

  String _rotuloDaSituacao(String valor) => switch (valor) {
    'pendentes' => 'Sem vínculo',
    'vinculadas' => 'Com vínculo',
    _ => 'Todas',
  };
}

class _LinhaDeMatricula extends StatelessWidget {
  const _LinhaDeMatricula({required this.matricula, required this.aoRemover});

  final Matricula matricula;
  final VoidCallback aoRemover;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        // O nome quando existe conta; o CPF quando ainda não. A instituição
        // digitou o CPF, então mostrá-lo aqui não revela nada a quem já o tem — e
        // é o único identificador que ela reconhece de quem não entrou no app.
        matricula.usuario?.nomeCompleto ?? matricula.cpfFormatado,
        style: tema.textTheme.p,
      ),
      subtitle: Text(
        matricula.usuario == null
            ? matricula.curso.nome
            : '${matricula.cpfFormatado} · ${matricula.curso.nome}',
        style: tema.textTheme.muted,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (matricula.vinculada)
            ShadBadge.secondary(
              child: Text('Vínculo', style: TextStyle(color: cores.ok)),
            )
          else
            // "Aguardando" e não "pendente": não há nada errado nesta linha. A
            // pessoa simplesmente ainda não informou o CPF no perfil da
            // instituição, e pode até não ter conta.
            const ShadBadge.outline(child: Text('Aguardando')),
          ShadIconButton.ghost(
            icon: const Icon(LucideIcons.trash2, size: 16),
            onPressed: aoRemover,
          ),
        ],
      ),
    );
  }
}
