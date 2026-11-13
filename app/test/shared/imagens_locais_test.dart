import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/fake_profile_repository.dart';
import 'package:integra/features/professional/data/fake_feed_repository.dart';
import 'package:integra/shared/domain/imagens_locais.dart';
import 'package:integra/shared/presentation/avatar_de_conta.dart';

/// O elo que faltava: no modo de fixtures o `PUT` não vai a lugar nenhum, então os
/// bytes enviados têm que ficar acessíveis pela `urlFinal` — senão o fluxo de três
/// passos termina com sucesso e a tela mostra imagem quebrada.
void main() {
  _avatar();

  final bytes = Uint8List.fromList(List<int>.filled(1024, 7));

  /// Os falsos derivam o caminho do arquivo de quem pede, então precisam de alguém
  /// logado — como qualquer tela que chegue a estas rotas.
  BancoFalso comAlguemLogado() {
    final banco = BancoFalso();
    banco.usuarioAtualId = banco.usuarios.values.first.id;
    return banco;
  }

  test('avatar enviado no modo de fixtures vem da memória', () async {
    final repo = FakeProfileRepository(comAlguemLogado(), latencia: Duration.zero);
    final destino = await repo.urlDeUploadDeAvatar(
      contentType: 'image/jpeg',
      tamanhoBytes: bytes.length,
    );

    expect(imagemDe(destino.urlFinal), isA<NetworkImage>());
    await repo.enviarAvatar(destino, bytes, contentType: 'image/jpeg');
    expect(imagemDe(destino.urlFinal), isA<MemoryImage>());
  });

  test('imagem de post enviada no modo de fixtures vem da memória', () async {
    final repo = FakeFeedRepository(comAlguemLogado(), latencia: Duration.zero);
    final destino = await repo.urlDeUploadDeImagem(
      contentType: 'image/png',
      tamanhoBytes: bytes.length,
    );

    await repo.enviarImagem(destino, bytes, contentType: 'image/png');
    expect(imagemDe(destino.urlFinal), isA<MemoryImage>());
  });
}

/// O avatar é o ponto único das oito telas: se ele deixar de olhar a `fotoUrl`, a foto
/// volta a não aparecer em nenhuma delas de uma vez.
void _avatar() {
  testWidgets('AvatarDeConta mostra a foto quando há fotoUrl', (tester) async {
    const url = 'https://storage.invalido/avatares/x.jpg';
    imagensLocais[url] = Uint8List.fromList(List<int>.filled(16, 7));
    addTearDown(() => imagensLocais.remove(url));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AvatarDeConta(
          fotoUrl: url,
          fundo: Color(0xFF000000),
          semFoto: Text('NI'),
        ),
      ),
    );

    expect(find.text('NI'), findsNothing);
    expect(
      tester.widget<Image>(find.byType(Image)).image,
      isA<MemoryImage>(),
    );
  });

  testWidgets('AvatarDeConta cai nas iniciais sem fotoUrl', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: AvatarDeConta(
          fotoUrl: null,
          fundo: Color(0xFF000000),
          semFoto: Text('NI'),
        ),
      ),
    );

    expect(find.text('NI'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
