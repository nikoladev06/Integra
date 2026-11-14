import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Os bytes das imagens escolhidas no modo de fixtures, pela URL que o falso devolveu.
///
/// Sem backend não existe storage: o `PUT` do passo 2 não vai a lugar nenhum e a
/// `fotoUrl`/`imagemUrl` gravada aponta para `storage.invalido`. O fluxo inteiro
/// terminava com sucesso e a tela mostrava as iniciais ou o card de imagem quebrada —
/// o que, de fora, é "adicionar foto não funciona em lugar nenhum". Guardar os bytes
/// aqui faz a imagem escolhida aparecer onde ela apareceria com o storage no ar.
///
/// ponytail: mapa global em memória, só cresce enquanto o app roda. Com
/// `API_BASE_URL` definido nada é gravado aqui — quem escreve são os repositórios
/// falsos. Se o crescimento incomodar, vira um `Provider` ao lado do `BancoFalso`.
final imagensLocais = <String, Uint8List>{};

/// De onde a imagem daquela URL vem: da memória no modo de fixtures, da rede com a API.
///
/// Um ponto só para as três telas que exibem imagem enviada — avatar no perfil, avatar
/// na edição, imagem do post. `Image.network` em cada uma delas deixaria a correção
/// valendo só onde alguém lembrasse de aplicá-la.
ImageProvider imagemDe(String url) {
  final bytes = imagensLocais[url];
  return bytes == null ? NetworkImage(url) : MemoryImage(bytes);
}
