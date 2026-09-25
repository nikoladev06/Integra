import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:integra/core/providers.dart';
import 'package:integra/core/storage/token_storage.dart';
import 'package:integra/features/auth/data/fake_auth_repository.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/profile/data/fake_profile_repository.dart';
import 'package:integra/main.dart';

/// Sobe o app inteiro com dependências controladas.
///
/// É o que faz o portão da sprint ser verificável: o app completo — tema,
/// roteador, guarda de sessão e repositórios — roda em teste **sem servidor e
/// sem tocar no keystore do sistema**, porque tudo que sai da máquina está
/// atrás de uma interface que o `ProviderScope` substitui aqui.
///
/// Devolve o [BancoFalso] do caso para o teste poder inspecionar o que as telas
/// gravaram — é assim que se verifica que o cadastro criou mesmo a conta, em vez
/// de só conferir que a tela navegou.
Future<BancoFalso> bombearApp(
  WidgetTester tester, {
  BancoFalso? banco,
  TokenStorage? tokens,
}) async {
  // Um banco por caso. Um singleton faria o usuário cadastrado num teste
  // aparecer na busca de outro, e a ordem dos testes passaria a importar.
  final oBanco = banco ?? BancoFalso();

  // A janela padrão do teste tem 600 px de altura, e as telas de perfil e de
  // edição são mais altas que isso. Num `ListView` o item fora da viewport nem
  // é construído, então o teste falharia por não achar um botão que existe —
  // um falso negativo sobre a altura da janela, não sobre o app. Uma janela
  // alta tira essa variável do caminho; a rolagem em si não é o que estes
  // testes verificam.
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Latência zero: os falsos simulam 300–400 ms em desenvolvimento para
        // os estados de carregamento serem visíveis, o que em teste só gastaria
        // tempo de espera.
        bancoFalsoProvider.overrideWithValue(oBanco),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(oBanco, latencia: Duration.zero),
        ),
        profileRepositoryProvider.overrideWithValue(
          FakeProfileRepository(oBanco, latencia: Duration.zero),
        ),
        tokenStorageProvider.overrideWithValue(
          tokens ?? TokenStorageEmMemoria(),
        ),
      ],
      child: const IntegraApp(),
    ),
  );
  // A primeira passada monta, a segunda deixa o `restaurar()` do post-frame
  // resolver e o `redirect` reavaliar.
  await tester.pumpAndSettle();

  return oBanco;
}

/// Abre o app já autenticado como [email].
///
/// Sem isto, todo teste de tela interna começaria repetindo o formulário de
/// login — e falharia por um motivo que não é o que ele queria verificar.
Future<BancoFalso> bombearAppAutenticado(
  WidgetTester tester, {
  required String email,
  BancoFalso? banco,
}) async {
  final oBanco = banco ?? BancoFalso();
  oBanco.usuarioAtualId = oBanco.usuarios.values
      .firstWhere((u) => u.email == email)
      .id;

  return bombearApp(
    tester,
    banco: oBanco,
    tokens: TokenStorageEmMemoria(
      accessToken: 'token-valido',
      refreshToken: 'refresh-valido',
    ),
  );
}
