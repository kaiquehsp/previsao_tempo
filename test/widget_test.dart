import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao_tempo/main.dart';
import 'package:previsao_tempo/screens/tela_busca.dart';
import 'package:previsao_tempo/services/cptec_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response respostaXml(String xml) => http.Response.bytes(
      latin1.encode(xml),
      200,
      headers: {'content-type': 'text/xml; charset=ISO-8859-1'},
    );

Widget appComServico(CptecService servico) =>
    MaterialApp(home: TelaBusca(servico: servico));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tela inicial mostra a busca e a fonte dos dados',
      (tester) async {
    await tester.pumpWidget(const PrevisaoTempoApp());
    await tester.pumpAndSettle();

    expect(find.text('Previsão do Tempo'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('CPTEC/INPE'), findsWidgets);
  });

  testWidgets('lista as cidades encontradas com a UF', (tester) async {
    late Uri chamada;
    final servico = CptecService(
      client: MockClient((request) async {
        chamada = request.url;
        return respostaXml(
          "<?xml version='1.0' encoding='ISO-8859-1'?><cidades>"
          '<cidade><nome>São Paulo</nome><uf>SP</uf><id>244</id></cidade>'
          '</cidades>',
        );
      }),
    );

    await tester.pumpWidget(appComServico(servico));
    await tester.enterText(find.byType(TextField), 'São Paulo');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(chamada.toString(), contains('listaCidades?city=sao%20paulo'));
    expect(find.text('São Paulo'), findsWidgets);
    expect(find.text('Unidade da federação: SP'), findsOneWidget);
  });

  testWidgets('informa quando nenhuma cidade é encontrada', (tester) async {
    final servico = CptecService(
      client: MockClient((_) async => respostaXml('<cidades></cidades>')),
    );

    await tester.pumpWidget(appComServico(servico));
    await tester.enterText(find.byType(TextField), 'xyzabc');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma cidade encontrada'), findsOneWidget);
  });

  testWidgets('trata indisponibilidade do serviço', (tester) async {
    final servico = CptecService(
      client: MockClient((_) async => http.Response('erro', 503)),
    );

    await tester.pumpWidget(appComServico(servico));
    await tester.enterText(find.byType(TextField), 'Campinas');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('Serviço indisponível'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('trata resposta inválida', (tester) async {
    final servico = CptecService(
      client: MockClient((_) async => respostaXml('<html>pagina de erro')),
    );

    await tester.pumpWidget(appComServico(servico));
    await tester.enterText(find.byType(TextField), 'Campinas');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('Resposta inválida'), findsOneWidget);
  });

  testWidgets('trata falha de conexão', (tester) async {
    final servico = CptecService(
      client: MockClient((request) async {
        throw http.ClientException('sem internet', request.url);
      }),
    );

    await tester.pumpWidget(appComServico(servico));
    await tester.enterText(find.byType(TextField), 'Campinas');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão'), findsOneWidget);
  });
}
