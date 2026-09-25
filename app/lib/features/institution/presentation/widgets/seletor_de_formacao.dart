import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/institution/presentation/instituicoes_providers.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// O par universidade + curso, em dois combobox encadeados.
///
/// Usado no cadastro de aluno e na edição de perfil, que precisam exatamente da
/// mesma regra: escolher a universidade habilita o de cursos, e os cursos
/// oferecidos são **os que aquela instituição cadastrou**, nunca texto livre.
///
/// Os dois vão juntos ou nenhum vai. Quando [opcional] é `true` — o caso do
/// cadastro — deixar em branco é uma resposta válida: declarar formação é
/// cosmético desde a v2, e exigir no cadastro era o que fazia todo mundo
/// escolher a primeira faculdade da lista para conseguir passar da tela.
class SeletorDeFormacao extends ConsumerStatefulWidget {
  const SeletorDeFormacao({
    required this.aoMudar,
    this.universidadeId,
    this.cursoId,
    this.opcional = true,
    this.erro,
    super.key,
  });

  final String? universidadeId;
  final String? cursoId;
  final bool opcional;

  /// Mensagem de erro do par, vinda do formulário que hospeda o seletor.
  final String? erro;

  /// Chamado a cada mudança. `cursoId` volta a nulo quando a universidade muda,
  /// porque o curso antigo pertencia a outra instituição.
  final void Function(String? universidadeId, String? cursoId) aoMudar;

  @override
  ConsumerState<SeletorDeFormacao> createState() => _SeletorDeFormacaoState();
}

class _SeletorDeFormacaoState extends ConsumerState<SeletorDeFormacao> {
  String _buscaUniversidade = '';
  String _buscaCurso = '';

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final universidades = ref.watch(universidadesProvider);
    final universidadeId = widget.universidadeId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.opcional ? 'Formação (opcional)' : 'Formação',
          style: tema.textTheme.small,
        ),
        const SizedBox(height: Espaco.xs),
        Text(
          'Aparece no seu perfil como currículo. Não dá acesso aos comunicados '
          'internos da instituição — para isso, informe o CPF no perfil dela.',
          style: tema.textTheme.muted,
        ),
        const SizedBox(height: Espaco.sm),

        switch (universidades) {
          AsyncError(:final error) => _Aviso(
            texto: 'Não foi possível carregar as universidades. $error',
          ),
          AsyncLoading() => const _Aviso(texto: 'Carregando universidades…'),
          AsyncData(:final value) => _selecaoDeUniversidade(value),
        },

        if (universidadeId != null) ...[
          const SizedBox(height: Espaco.sm),
          _selecaoDeCurso(universidadeId),
        ],

        if (widget.erro != null) ...[
          const SizedBox(height: Espaco.xs),
          Text(
            widget.erro!,
            style: tema.textTheme.muted.copyWith(
              color: tema.colorScheme.destructive,
            ),
          ),
        ],
      ],
    );
  }

  Widget _selecaoDeUniversidade(List<Universidade> universidades) {
    final porId = {for (final u in universidades) u.id: u};

    bool casa(Universidade u) {
      final termo = _buscaUniversidade.toLowerCase();
      return u.nome.toLowerCase().contains(termo) ||
          u.sigla.toLowerCase().contains(termo);
    }

    return ShadSelect<String>.withSearch(
      placeholder: const Text('Universidade'),
      searchPlaceholder: const Text('Buscar universidade'),
      initialValue: widget.universidadeId,
      allowDeselection: widget.opcional,
      onSearchChanged: (v) => setState(() => _buscaUniversidade = v),
      onChanged: (valor) {
        // Trocar de universidade zera o curso: o anterior pertencia a outra
        // instituição, e o serviço recusa o par.
        setState(() => _buscaCurso = '');
        widget.aoMudar(valor, null);
      },
      selectedOptionBuilder: (context, value) =>
          Text(porId[value]?.sigla ?? value),
      options: [
        if (universidades.where(casa).isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Espaco.lg),
            child: Text('Nenhuma universidade encontrada'),
          ),
        // `Offstage` em vez de filtrar a lista: manter o widget na árvore evita
        // o campo de busca perder o foco quando os resultados voltam.
        for (final u in universidades)
          Offstage(
            offstage: !casa(u),
            child: ShadOption(
              value: u.id,
              child: Text('${u.sigla} — ${u.nome}'),
            ),
          ),
      ],
    );
  }

  Widget _selecaoDeCurso(String universidadeId) {
    final cursos = ref.watch(cursosDaUniversidadeProvider(universidadeId));

    return switch (cursos) {
      AsyncError() => const _Aviso(
        texto: 'Não foi possível carregar os cursos desta universidade.',
      ),
      AsyncLoading() => const _Aviso(texto: 'Carregando cursos…'),
      AsyncData(:final value) when value.isEmpty => const _Aviso(
        // Universidade sem conta institucional não cadastrou curso nenhum, e a
        // tela diz isso em vez de mostrar um combobox vazio.
        texto:
            'Esta instituição ainda não cadastrou cursos no Integra. '
            'Você pode concluir sem declarar a formação.',
      ),
      AsyncData(:final value) => _comboDeCursos(value),
    };
  }

  Widget _comboDeCursos(List<Curso> cursos) {
    final porId = {for (final c in cursos) c.id: c};

    bool casa(Curso c) =>
        c.nome.toLowerCase().contains(_buscaCurso.toLowerCase());

    return ShadSelect<String>.withSearch(
      // A chave é o que força um combobox **novo** quando a universidade muda.
      // Sem ela o elemento é reaproveitado, o `State` do anterior sobrevive, e o
      // campo continua exibindo um curso que agora pertence a outra
      // instituição — o par que o serviço recusa.
      key: ValueKey('cursos-${widget.universidadeId}'),
      placeholder: const Text('Curso'),
      searchPlaceholder: const Text('Buscar curso'),
      initialValue: widget.cursoId,
      allowDeselection: widget.opcional,
      onSearchChanged: (v) => setState(() => _buscaCurso = v),
      onChanged: (valor) => widget.aoMudar(widget.universidadeId, valor),
      selectedOptionBuilder: (context, value) =>
          Text(porId[value]?.nome ?? value),
      options: [
        if (cursos.where(casa).isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Espaco.lg),
            child: Text('Nenhum curso encontrado'),
          ),
        for (final c in cursos)
          Offstage(
            offstage: !casa(c),
            child: ShadOption(value: c.id, child: Text(c.nome)),
          ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.sm),
      child: Text(texto, style: ShadTheme.of(context).textTheme.muted),
    );
  }
}
