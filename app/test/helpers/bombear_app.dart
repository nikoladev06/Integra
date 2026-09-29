import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:integra/core/providers.dart';
import 'package:integra/core/storage/token_storage.dart';
import 'package:integra/features/academic/data/fake_academic_repository.dart';
import 'package:integra/features/auth/data/fake_auth_repository.dart';
import 'package:integra/features/profile/data/banco_falso.dart';
import 'package:integra/features/jobs/data/fake_jobs_repository.dart';
import 'package:integra/features/professional/data/fake_feed_repository.dart';
import 'package:integra/features/profile/data/fake_profile_repository.dart';
import 'package:integra/main.dart';
import 'package:integra/shared/domain/seletor_de_imagem.dart';

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
  SeletorDeImagem? seletor,
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

  // Desmonta o que estiver na tela antes de montar o app.
  //
  // Sem isto, um teste que chama este helper duas vezes — trocando de conta no meio,
  // que é como o portão da sprint é verificado — trava no `pumpAndSettle`: o
  // `ShadToaster` e as transições do roteador da árvore anterior continuam animando
  // enquanto a nova monta, e `pumpAndSettle` espera por uma tela que nunca fica
  // parada. Uma árvore vazia no meio descarta os dois.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

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
        academicRepositoryProvider.overrideWithValue(
          FakeAcademicRepository(oBanco, latencia: Duration.zero),
        ),
        feedRepositoryProvider.overrideWithValue(
          FakeFeedRepository(oBanco, latencia: Duration.zero),
        ),
        jobsRepositoryProvider.overrideWithValue(
          FakeJobsRepository(oBanco, latencia: Duration.zero),
        ),
        // A galeria fala por canal de plataforma, que não existe em teste. Sem este
        // override, toda tela com troca de foto ficaria fora do alcance dos testes —
        // e são justamente as telas em que o fluxo de três passos pode dar errado.
        seletorDeImagemProvider.overrideWithValue(
          seletor ?? const SemImagem(),
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
  SeletorDeImagem? seletor,
}) async {
  final oBanco = banco ?? BancoFalso();
  oBanco.usuarioAtualId = oBanco.usuarios.values
      .firstWhere((u) => u.email == email)
      .id;

  return bombearApp(
    tester,
    banco: oBanco,
    seletor: seletor,
    tokens: TokenStorageEmMemoria(
      accessToken: 'token-valido',
      refreshToken: 'refresh-valido',
    ),
  );
}

/// Abre o menu de opções da conta, no canto direito do cabeçalho do perfil.
///
/// As ações de conta — editar perfil, trocar senha, sair, e a administração da
/// instituição — saíram do corpo da tela e foram para este menu quando o perfil
/// ganhou abas: elas não pertencem nem às publicações nem ao currículo.
///
/// Um helper porque quatro arquivos de teste precisam da mesma sequência, e porque
/// quando o menu mudar de forma a correção é num lugar só.
Future<void> abrirMenuDaConta(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Perfil'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Opções da conta'));
  await tester.pumpAndSettle();
}


/// Um seletor que nunca escolhe nada — o padrão em teste.
///
/// Devolver nulo é o mesmo que o usuário cancelar, e é o que as telas tratam sem
/// avisar: cancelar não é erro. Um seletor que lançasse faria toda tela com botão de
/// foto falhar por um caminho que o teste não estava exercitando.
class SemImagem implements SeletorDeImagem {
  const SemImagem();

  @override
  Future<ImagemEscolhida?> escolher() async => null;
}

/// Um seletor que devolve sempre os mesmos bytes.
///
/// Os bytes não são uma imagem de verdade, e não precisam ser: nada é decodificado no
/// caminho que este seletor exercita — o fluxo pede a URL, envia os bytes e grava a
/// `imagemUrl`. O `Image.memory` da pré-visualização falha em renderizar, e o
/// `errorBuilder` do card é justamente o ramo que o teste quer poder alcançar.
class ImagemFixa implements SeletorDeImagem {
  const ImagemFixa({this.tamanho = 1024, this.contentType = 'image/jpeg'});

  final int tamanho;
  final String contentType;

  @override
  Future<ImagemEscolhida?> escolher() async => ImagemEscolhida(
    bytes: Uint8List.fromList(List<int>.filled(tamanho, 7)),
    contentType: contentType,
  );
}
