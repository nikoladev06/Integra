import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/error/failure.dart';
import 'package:integra/core/providers.dart';
import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/features/jobs/data/models/vaga.dart';
import 'package:integra/features/jobs/presentation/jobs_providers.dart';

/// Publicar ou editar uma vaga.
///
/// Uma tela para as duas coisas porque os campos são os mesmos e as invariantes
/// também. O que muda é o título, o texto do botão e a presença do controle de
/// encerramento — que só existe na edição, porque uma vaga não nasce fechada.
///
/// ## O campo de local, e por que ele aparece e desaparece
///
/// `local` é **obrigatório fora de `remoto` e recusado em `remoto`**, nos dois
/// sentidos. O campo some quando a modalidade é remota em vez de ficar desabilitado:
/// um campo cinza convida a perguntar por que não dá para preencher, e a resposta é
/// que não há o que preencher.
///
/// A regra vive no servidor — ele responde 422 nomeando `local` — e a tela a repete
/// para o usuário não descobrir no envio. É duplicação consciente de uma regra de
/// formulário, não de uma regra de autorização.
class ComporVagaScreen extends ConsumerStatefulWidget {
  const ComporVagaScreen({this.vaga, super.key});

  /// Nula ao publicar, preenchida ao editar.
  final Vaga? vaga;

  @override
  ConsumerState<ComporVagaScreen> createState() => _ComporVagaScreenState();
}

class _ComporVagaScreenState extends ConsumerState<ComporVagaScreen> {
  late final TextEditingController _titulo;
  late final TextEditingController _descricao;
  late final TextEditingController _local;

  late TipoDeVaga _tipo;
  late Modalidade _modalidade;
  late EstadoDaVaga _estado;

  bool _salvando = false;
  String? _erroDeLocal;
  String? _erroDeTitulo;

  bool get _editando => widget.vaga != null;

  @override
  void initState() {
    super.initState();
    final vaga = widget.vaga;
    _titulo = TextEditingController(text: vaga?.titulo ?? '');
    _descricao = TextEditingController(text: vaga?.descricao ?? '');
    _local = TextEditingController(text: vaga?.local ?? '');
    _tipo = vaga?.tipo ?? TipoDeVaga.estagio;
    _modalidade = vaga?.modalidade ?? Modalidade.presencial;
    _estado = vaga?.estado ?? EstadoDaVaga.aberta;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _local.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final titulo = _titulo.text.trim();
    final descricao = _descricao.text.trim();
    final local = _local.text.trim();

    setState(() {
      _erroDeTitulo = titulo.isEmpty ? 'Informe o título da vaga' : null;
      // A mesma checagem que o serviço faz, com a mesma mensagem. Antecipá-la poupa
      // uma ida de rede para um erro que o formulário já conhece.
      _erroDeLocal = _modalidade.exigeLocal && local.isEmpty
          ? 'Informe a cidade da vaga'
          : null;
    });
    if (_erroDeTitulo != null || _erroDeLocal != null) return;
    if (descricao.isEmpty) {
      setState(() => _erroDeTitulo = 'Descreva a vaga antes de publicar');
      return;
    }

    setState(() => _salvando = true);
    try {
      final repo = ref.read(jobsRepositoryProvider);
      final vaga = widget.vaga;

      if (vaga == null) {
        await repo.publicar(
          titulo: titulo,
          descricao: descricao,
          tipo: _tipo,
          modalidade: _modalidade,
          // Nulo em remoto: o serviço **recusa** o campo ali, e mandar sempre
          // renderia 422 numa vaga que o usuário preencheu certo.
          local: _modalidade.exigeLocal ? local : null,
        );
      } else {
        await repo.editar(
          vaga.id,
          titulo: titulo,
          descricao: descricao,
          tipo: _tipo,
          modalidade: _modalidade,
          local: _modalidade.exigeLocal ? local : null,
          estado: _estado,
        );
        ref.invalidate(vagaProvider(vaga.id));
      }

      ref.invalidate(vagasProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ShadToaster.of(context).show(
        ShadToast(
          description: Text(_editando ? 'Vaga atualizada.' : 'Vaga publicada.'),
        ),
      );
    } on FalhaDeValidacao catch (falha) {
      setState(() {
        _erroDeLocal = falha.primeiroErroDe('local');
        _erroDeTitulo = falha.primeiroErroDe('titulo');
      });
      if (_erroDeLocal == null && _erroDeTitulo == null) {
        _avisar(falha.mensagem, erro: true);
      }
    } on Failure catch (falha) {
      _avisar(falha.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _avisar(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      erro
          ? ShadToast.destructive(description: Text(mensagem))
          : ShadToast(description: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return Scaffold(
      backgroundColor: cores.background,
      appBar: AppBar(
        title: Text(_editando ? 'Editar vaga' : 'Nova vaga'),
        backgroundColor: cores.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(Espaco.md),
        children: [
          Text('Título', style: tema.textTheme.small),
          const SizedBox(height: Espaco.xs),
          ShadInput(
            controller: _titulo,
            placeholder: const Text('Estágio em desenvolvimento'),
            maxLength: 120,
          ),
          if (_erroDeTitulo != null) ...[
            const SizedBox(height: Espaco.xs),
            Text(
              _erroDeTitulo!,
              style: tema.textTheme.muted.copyWith(color: cores.destructive),
            ),
          ],
          const SizedBox(height: Espaco.md),

          Text('Descrição', style: tema.textTheme.small),
          const SizedBox(height: Espaco.xs),
          ShadTextarea(
            controller: _descricao,
            placeholder: const Text(
              'O que a pessoa vai fazer, o que é desejável, como é o processo…',
            ),
            minHeight: 160,
            maxLength: 5000,
          ),
          const SizedBox(height: Espaco.md),

          _Escolha<TipoDeVaga>(
            rotulo: 'Tipo',
            valor: _tipo,
            opcoes: TipoDeVaga.values,
            nome: (t) => t.rotulo,
            aoTrocar: (t) => setState(() => _tipo = t),
          ),
          const SizedBox(height: Espaco.md),

          _Escolha<Modalidade>(
            rotulo: 'Modalidade',
            valor: _modalidade,
            opcoes: Modalidade.values,
            nome: (m) => m.rotulo,
            explicacao: (m) => m.explicacao,
            aoTrocar: (m) => setState(() {
              _modalidade = m;
              // Trocar para remoto limpa o erro de local: o campo deixou de existir, e
              // um erro apontando para um campo invisível é o tipo de coisa que
              // trava um formulário sem dizer por quê.
              if (!m.exigeLocal) _erroDeLocal = null;
            }),
          ),

          if (_modalidade.exigeLocal) ...[
            const SizedBox(height: Espaco.md),
            Text('Cidade', style: tema.textTheme.small),
            const SizedBox(height: Espaco.xs),
            ShadInput(
              controller: _local,
              placeholder: const Text('Ribeirão Preto, SP'),
              maxLength: 120,
            ),
            if (_erroDeLocal != null) ...[
              const SizedBox(height: Espaco.xs),
              Text(
                _erroDeLocal!,
                style: tema.textTheme.muted.copyWith(color: cores.destructive),
              ),
            ],
          ],

          if (_editando) ...[
            const SizedBox(height: Espaco.lg),
            _Encerramento(
              estado: _estado,
              candidaturas: widget.vaga!.totalDeCandidaturas,
              aoTrocar: (novo) => setState(() => _estado = novo),
            ),
          ],

          const SizedBox(height: Espaco.lg),
          ShadButton(
            onPressed: _salvando ? null : _salvar,
            leading: _salvando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.check, size: 16),
            child: Text(
              _salvando
                  ? 'Salvando…'
                  : (_editando ? 'Salvar alterações' : 'Publicar vaga'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma escolha de valor único, com a explicação abaixo quando ela existe.
///
/// A explicação vem do enum, não da tela: em [Modalidade] ela é consequente — decide
/// se o campo de cidade aparece —, e escrevê-la aqui a deixaria fora de sincronia com
/// a regra que o enum já carrega em `exigeLocal`.
class _Escolha<T> extends StatelessWidget {
  const _Escolha({
    required this.rotulo,
    required this.valor,
    required this.opcoes,
    required this.nome,
    required this.aoTrocar,
    this.explicacao,
  });

  final String rotulo;
  final T valor;
  final List<T> opcoes;
  final String Function(T) nome;
  final String Function(T)? explicacao;
  final ValueChanged<T> aoTrocar;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: tema.textTheme.small),
        const SizedBox(height: Espaco.xs),
        Wrap(
          spacing: Espaco.xs,
          runSpacing: Espaco.xs,
          children: [
            for (final opcao in opcoes)
              opcao == valor
                  ? ShadButton(
                      size: ShadButtonSize.sm,
                      onPressed: () => aoTrocar(opcao),
                      child: Text(nome(opcao)),
                    )
                  : ShadButton.outline(
                      size: ShadButtonSize.sm,
                      onPressed: () => aoTrocar(opcao),
                      child: Text(nome(opcao)),
                    ),
          ],
        ),
        if (explicacao != null) ...[
          const SizedBox(height: Espaco.xs),
          Text(explicacao!(valor), style: tema.textTheme.muted),
        ],
      ],
    );
  }
}

/// Encerrar e reabrir, com o custo escrito.
///
/// Encerrar **não apaga candidatura nenhuma** — é estado, não remoção —, e a frase diz
/// isso porque é a dúvida que a palavra "encerrar" provoca em quem tem candidatos.
/// Reabrir também não recria nada: as que existiam nunca saíram.
class _Encerramento extends StatelessWidget {
  const _Encerramento({
    required this.estado,
    required this.candidaturas,
    required this.aoTrocar,
  });

  final EstadoDaVaga estado;
  final int candidaturas;
  final ValueChanged<EstadoDaVaga> aoTrocar;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final fechada = estado == EstadoDaVaga.fechada;

    return ShadCard(
      padding: const EdgeInsets.all(Espaco.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fechada ? 'Vaga encerrada' : 'Vaga aberta',
                  style: tema.textTheme.small,
                ),
              ),
              ShadSwitch(
                value: !fechada,
                onChanged: (aberta) => aoTrocar(
                  aberta ? EstadoDaVaga.aberta : EstadoDaVaga.fechada,
                ),
              ),
            ],
          ),
          const SizedBox(height: Espaco.xs),
          Text(
            fechada
                ? 'A vaga sai da listagem e não recebe candidaturas novas. As '
                      '$candidaturas que você já recebeu continuam aqui, e quem se '
                      'candidatou continua vendo a vaga.'
                : 'Encerrar tira a vaga da listagem sem apagar candidatura '
                      'nenhuma. Você pode reabrir depois, e as $candidaturas '
                      'recebidas continuam as mesmas.',
            style: tema.textTheme.muted,
          ),
        ],
      ),
    );
  }
}
