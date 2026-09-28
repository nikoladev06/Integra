import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:integra/core/theme/integra_theme.dart';
import 'package:integra/shared/widgets/estado_vazio.dart';

/// Mensagens diretas — **não implementadas**, e a tela diz isso.
///
/// Chat não estava no escopo de nenhuma das cinco sprints nem em nenhum dos três
/// pilares: entrou como decisão de produto durante a Sprint 4, junto do desenho
/// novo do cabeçalho. O botão no canto direito leva aqui desde já, pelo mesmo
/// motivo que as telas de Acadêmico e Profissional existiam vazias desde a Sprint
/// 2: a navegação fica completa, e mudar a posição dos elementos do cabeçalho
/// depois de as pessoas se acostumarem custa mais que uma tela honesta.
///
/// Um **vazio honesto**, não um protótipo de conversa com dados inventados. Uma
/// lista falsa de mensagens esconderia que o serviço não existe — e é o erro que o
/// plano registra como a primeira conta que trabalhar com falsos cobra.
///
/// O que falta é um serviço: conversa entre duas contas tem estado próprio (lida,
/// entregue, quem começou), tempo real de algum tipo, e uma decisão de produto que
/// ninguém tomou ainda — quem pode iniciar conversa com quem. Nenhuma das três
/// cabe como apêndice de um serviço existente.
class MensagensScreen extends StatelessWidget {
  const MensagensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: tema.colorScheme.background,
      appBar: AppBar(
        // Esta tela mantém o título: é destino de toque, com botão de voltar, e o
        // título é a única coisa que diz onde o usuário chegou. O cabeçalho sem
        // texto é o das telas de navegação, onde a aba já responde isso.
        title: const Text('Mensagens'),
        backgroundColor: tema.colorScheme.card,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: Espaco.xl),
        child: EstadoVazio(
          icone: LucideIcons.messageCircle,
          titulo: 'As mensagens ainda não existem',
          descricao:
              'Conversa direta entre contas é um serviço à parte: tem estado '
              'próprio, precisa de tempo real e depende de uma decisão que ainda '
              'não foi tomada — quem pode iniciar conversa com quem. O botão já '
              'está no lugar definitivo para não mudar de posição depois.',
        ),
      ),
    );
  }
}
