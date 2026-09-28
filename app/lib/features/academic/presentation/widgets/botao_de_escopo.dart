import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// O seletor de escopo do feed: um ícone no canto esquerdo do cabeçalho.
///
/// Substituiu a barra retrátil que ficava abaixo do cabeçalho. A barra custava uma
/// faixa permanente da tela para uma escolha que a maioria faz uma vez, e ainda
/// precisava de um botão "Alterar" para abrir — dois toques onde cabe um. Aqui o
/// toque no ícone **já** abre as opções.
///
/// Genérico sobre `T` porque os dois pilares o usam com opções diferentes: no
/// Acadêmico, **geral** e **minha instituição**; no Profissional, geral com
/// recomendações e somente seguidos, quando o `feed-service` entrar. Escrever o
/// mesmo seletor duas vezes é como as duas versões divergem.
///
/// ## O que o escopo é, e o que ele não é
///
/// Escolhe **quais instituições** entram no feed — nunca **qual conteúdo** dentro
/// delas. O que o leitor pode ver sai do vínculo, resolvido no serviço. Um seletor
/// que parecesse controlar visibilidade convidaria a tratar a regra como filtro de
/// UI, e no cliente ela é contornável por quem ler a resposta da API.
class BotaoDeEscopo<T> extends StatelessWidget {
  const BotaoDeEscopo({
    required this.opcoes,
    required this.selecionado,
    required this.rotulo,
    required this.descricao,
    required this.aoTrocar,
    required this.cor,
    this.padrao,
    super.key,
  });

  final List<T> opcoes;
  final T selecionado;

  /// O valor que dispensa destaque no ícone. Nulo trata qualquer escolha como
  /// digna de destaque.
  final T? padrao;

  final String Function(T) rotulo;
  final String Function(T) descricao;
  final ValueChanged<T> aoTrocar;

  /// A cor do pilar: azul no Acadêmico, dourado no Profissional.
  final Color cor;

  bool get _noPadrao => padrao == null || selecionado == padrao;

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);
    final cores = tema.colorScheme;

    return MenuAnchor(
      builder: (context, controlador, _) => Tooltip(
        // O rótulo diz o escopo **em vigor**, não só o nome do botão. Com o texto
        // fora da tela, é a única forma de o leitor de tela e o hover contarem que
        // o feed está filtrado.
        message: 'Escopo do feed: ${rotulo(selecionado)}',
        child: ShadIconButton.ghost(
          icon: Icon(
            LucideIcons.slidersHorizontal,
            size: 20,
            // Fora do padrão, o ícone ganha a cor do pilar. É o que impede o
            // usuário de ler um feed filtrado como um feed vazio e concluir que
            // não há nada publicado — sem gastar espaço com o rótulo escrito.
            color: _noPadrao ? cores.mutedForeground : cor,
          ),
          onPressed: () =>
              controlador.isOpen ? controlador.close() : controlador.open(),
        ),
      ),
      menuChildren: [
        for (final opcao in opcoes)
          MenuItemButton(
            leadingIcon: Icon(
              opcao == selecionado ? LucideIcons.check : LucideIcons.minus,
              size: 16,
              color: opcao == selecionado ? cor : Colors.transparent,
            ),
            onPressed: () => aoTrocar(opcao),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(rotulo(opcao)),
                // A descrição vem junto porque "geral" e "minha instituição" não
                // dizem sozinhos o que incluem, e a barra que explicava isso saiu.
                Text(descricao(opcao), style: tema.textTheme.muted),
              ],
            ),
          ),
      ],
    );
  }
}
