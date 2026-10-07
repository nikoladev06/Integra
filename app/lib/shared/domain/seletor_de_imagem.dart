import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Uma imagem escolhida pelo usuário, pronta para o `PUT`.
///
/// Guarda os **bytes**, e não um caminho de arquivo: o `PUT` na URL pré-assinada
/// precisa do corpo e do tamanho exato — o `Content-Length` entra na assinatura —, e
/// no navegador não existe caminho de arquivo para abrir depois.
class ImagemEscolhida {
  const ImagemEscolhida({required this.bytes, required this.contentType});

  final Uint8List bytes;

  /// Um dos três que o contrato aceita: `image/jpeg`, `image/png`, `image/webp`.
  final String contentType;

  int get tamanhoBytes => bytes.length;
}

/// Escolher uma imagem da galeria.
///
/// Uma interface com uma implementação, e **não** é abstração especulativa: ela existe
/// para os testes de widget. `image_picker` fala por canal de plataforma, que não
/// existe no ambiente de teste — sem este ponto de substituição, toda tela que oferece
/// troca de foto ficaria fora do alcance dos testes, e são justamente as telas em que
/// o fluxo de três passos pode dar errado.
abstract interface class SeletorDeImagem {
  /// Nulo quando o usuário cancela. Cancelar não é erro, e tratá-lo como erro faria a
  /// tela mostrar um aviso para quem só mudou de ideia.
  Future<ImagemEscolhida?> escolher();
}

class SeletorDeImagemDaGaleria implements SeletorDeImagem {
  const SeletorDeImagemDaGaleria();

  @override
  Future<ImagemEscolhida?> escolher() async {
    final escolhido = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Reduz antes de ler os bytes. O limite do contrato é 5 MB, e uma foto de
      // celular moderno passa disso com folga: sem o corte, a maioria das escolhas
      // seria recusada com "a imagem deve ter até 5 MB" e o usuário não teria como
      // corrigir — não há editor de imagem no app.
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (escolhido == null) return null;

    return ImagemEscolhida(
      bytes: await escolhido.readAsBytes(),
      // O `mimeType` vem nulo em várias plataformas, e aí a extensão decide. JPEG como
      // último recurso porque é o que o `imageQuality` acima produz: o corte
      // recodifica, então o arquivo entregue é JPEG mesmo quando o original não era.
      contentType: _tipo(escolhido.mimeType, escolhido.name),
    );
  }

  static String _tipo(String? mimeType, String nome) {
    if (mimeType != null && _aceitos.contains(mimeType)) return mimeType;

    final minusculo = nome.toLowerCase();
    if (minusculo.endsWith('.png')) return 'image/png';
    if (minusculo.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  static const _aceitos = {'image/jpeg', 'image/png', 'image/webp'};
}

/// O seletor em uso. Substituído nos testes por um que devolve bytes fixos.
final seletorDeImagemProvider = Provider<SeletorDeImagem>(
  (ref) => const SeletorDeImagemDaGaleria(),
);
