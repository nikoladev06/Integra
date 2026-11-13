import 'package:flutter/material.dart';

import 'package:integra/shared/domain/imagens_locais.dart';

/// O avatar redondo de uma conta — pessoa, empresa ou instituição.
///
/// Um widget só porque o avatar aparece em oito lugares com a mesma regra e três
/// fallbacks diferentes: iniciais no comentário e na busca, ícone de empresa na vaga,
/// ícone de escola no comunicado. Cada tela escolhia o seu, e nenhuma delas chegava a
/// olhar a `fotoUrl` que o contrato já entrega — era por isso que a foto não aparecia
/// em nenhum card.
///
/// [semFoto] continua existindo e não é decoração: a foto é opcional em toda conta, e
/// no feed de uma instituição o ícone é o que distingue um comunicado de um post de
/// pessoa antes de a linha de texto ser lida.
class AvatarDeConta extends StatelessWidget {
  const AvatarDeConta({
    super.key,
    required this.fotoUrl,
    required this.semFoto,
    required this.fundo,
    this.diametro = 36,
  });

  /// Nula ou vazia em quem nunca enviou foto — o caso comum.
  final String? fotoUrl;

  /// Iniciais ou ícone. Também é o destino quando a URL existe e a imagem não
  /// carrega: o arquivo vive num storage separado, e o serviço não confere que ele
  /// chegou.
  final Widget semFoto;

  final Color fundo;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final url = fotoUrl;

    return Container(
      width: diametro,
      height: diametro,
      decoration: BoxDecoration(color: fundo, shape: BoxShape.circle),
      alignment: Alignment.center,
      // Recorta a imagem no círculo da decoração, em vez de um `ClipOval` por tela.
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? semFoto
          : Image(
              // `imagemDe`, e não `NetworkImage`: no modo de fixtures os bytes da
              // foto escolhida estão em memória, e é de lá que ela vem.
              image: imagemDe(url),
              width: diametro,
              height: diametro,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => semFoto,
            ),
    );
  }
}
