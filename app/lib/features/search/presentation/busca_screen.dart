import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/router/app_router.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/core/theme/tokens.dart';
import 'package:integra/features/profile/data/models/instituicao.dart';
import 'package:integra/features/profile/data/models/perfil.dart';

/// `GET /busca` — uma consulta, resultados agrupados por tipo.
///
/// Agrupado, e não uma lista só: quem digita "fatec" não deveria ter que
/// escolher aba antes de saber se achou. O serviço devolve sempre os três
/// grupos, ainda que vazios.
final resultadoDeBuscaProvider = FutureProvider.autoDispose
    .family<ResultadoDeBusca, String>(
      (ref, termo) => ref.watch(profileRepositoryProvider).buscar(termo),
    );

/// A busca do cabeçalho, em tela cheia.
///
/// Substitui o `buscausers_view` do protótipo, que procurava só usuários e era
/// alcançável apenas pelo menu. Universidades, empresas e pessoas vêm juntas
/// porque o usuário não sabe de antemão em qual das três está a coisa que
/// procura.
class BuscaScreen extends ConsumerStatefulWidget {
  const BuscaScreen({super.key});

  @override
  ConsumerState<BuscaScreen> createState() => _BuscaScreenState();
}

class _BuscaScreenState extends ConsumerState<BuscaScreen> {
  final _controlador = TextEditingController();
  Timer? _debounce;
  String _termo = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  /// Uma requisição por pausa de digitação, não por tecla. Sem isto, "fatec"
  /// dispara cinco consultas e as respostas chegam fora de ordem.
  void _aoDigitar(String valor) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => setState(() => _termo = valor.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: tema.colorScheme.background,
      appBar: AppBar(
        backgroundColor: tema.colorScheme.card,
        surfaceTintColor: Colors.transparent,
        title: ShadInput(
          controller: _controlador,
          autofocus: true,
          placeholder: const Text('Universidades, empresas e pessoas'),
          leading: const Icon(LucideIcons.search, size: 16),
          onChanged: _aoDigitar,
        ),
      ),
      body: _termo.length < 2
          ? _Mensagem(
              texto: 'Digite pelo menos 2 letras para buscar.',
              estilo: tema.textTheme.muted,
            )
          : _Resultados(termo: _termo),
    );
  }
}

class _Resultados extends ConsumerWidget {
  const _Resultados({required this.termo});

  final String termo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ShadTheme.of(context);
    final resultado = ref.watch(resultadoDeBuscaProvider(termo));

    return switch (resultado) {
      AsyncError(:final error) => _Mensagem(
        texto: error is Failure
            ? error.mensagem
            : 'Não foi possível buscar agora.',
        estilo: tema.textTheme.muted,
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
      AsyncData(:final value) when value.vazio => _Mensagem(
        // "Nada encontrado" e "deu erro" são estados diferentes, e o protótipo
        // mostrava o mesmo texto para os dois porque todo controller devolvia
        // lista vazia em erro.
        texto: 'Nada encontrado para "$termo".',
        estilo: tema.textTheme.muted,
      ),
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          if (value.universidades.isNotEmpty) ...[
            _Grupo(titulo: 'Universidades'),
            for (final u in value.universidades)
              _LinhaDeUniversidade(universidade: u),
            const SizedBox(height: Espaco.md),
          ],
          if (value.empresas.isNotEmpty) ...[
            _Grupo(titulo: 'Empresas'),
            for (final e in value.empresas) _LinhaDePerfil(perfil: e),
            const SizedBox(height: Espaco.md),
          ],
          if (value.pessoas.isNotEmpty) ...[
            _Grupo(titulo: 'Pessoas'),
            for (final p in value.pessoas) _LinhaDePerfil(perfil: p),
          ],
        ],
      ),
    };
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Espaco.sm),
    child: Text(titulo, style: ShadTheme.of(context).textTheme.small),
  );
}

class _LinhaDeUniversidade extends StatelessWidget {
  const _LinhaDeUniversidade({required this.universidade});

  final Universidade universidade;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: cores.academico.withValues(alpha: 0.12),
        child: Icon(LucideIcons.school, size: 18, color: cores.academico),
      ),
      title: Text(universidade.sigla, style: tema.textTheme.small),
      subtitle: Text(
        // Universidade sem conta não publica e não matricula. Dizer isso na
        // lista evita a viagem até um perfil que não tem o que oferecer.
        universidade.temConta
            ? universidade.nome
            : '${universidade.nome} · ainda sem conta no Integra',
        style: tema.textTheme.muted,
      ),
      onTap: () => context.push(Rotas.universidade(universidade.id)),
    );
  }
}

class _LinhaDePerfil extends StatelessWidget {
  const _LinhaDePerfil({required this.perfil});

  final Perfil perfil;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;
    final vinculo = perfil.vinculo;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: cores.muted,
        child: Text(perfil.iniciais, style: tema.textTheme.muted),
      ),
      title: Text(perfil.nomeCompleto, style: tema.textTheme.small),
      subtitle: Text(
        // O vínculo é público de propósito: é o equivalente a "trabalha em" num
        // perfil profissional. A formação declarada não entra aqui.
        vinculo == null
            ? '@${perfil.username}'
            : '@${perfil.username} · ${vinculo.universidade.sigla}',
        style: tema.textTheme.muted,
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.texto, this.estilo});

  final String texto;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Espaco.xl),
      child: Text(texto, style: estilo, textAlign: TextAlign.center),
    ),
  );
}
