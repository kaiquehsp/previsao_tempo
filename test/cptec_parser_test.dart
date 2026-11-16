import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo/services/cptec_parser.dart';
import 'package:previsao_tempo/utils/condicoes_tempo.dart';
import 'package:previsao_tempo/utils/texto.dart';

const xmlCidades = '''<?xml version='1.0' encoding='ISO-8859-1'?>
<cidades>
  <cidade><nome>São Paulo</nome><uf>SP</uf><id>244</id></cidade>
  <cidade><nome>São Paulo das Missões</nome><uf>RS</uf><id>5016</id></cidade>
  <cidade><nome>Sem código</nome><uf>MG</uf></cidade>
</cidades>''';

const xmlPrevisao = '''<?xml version='1.0' encoding='ISO-8859-1'?>
<cidade>
  <nome>São Paulo</nome>
  <uf>SP</uf>
  <atualizacao>2026-11-16</atualizacao>
  <previsao><dia>2026-11-16</dia><tempo>pn</tempo><maxima>28</maxima><minima>18</minima><iuv>11.0</iuv></previsao>
  <previsao><dia>2026-11-17</dia><tempo>c</tempo><maxima>24</maxima><minima>17</minima><iuv>9.0</iuv></previsao>
  <previsao><dia>2026-11-18</dia><tempo>ps</tempo><maxima>27</maxima><minima>16</minima></previsao>
  <previsao><dia>2026-11-19</dia><tempo>xx</tempo><maxima>null</maxima><minima>15</minima><iuv>null</iuv></previsao>
</cidade>''';

void main() {
  group('CptecParser.parseCidades', () {
    test('lê nome, UF e código e ignora itens sem código', () {
      final cidades = CptecParser.parseCidades(xmlCidades);
      expect(cidades, hasLength(2));
      expect(cidades.first.nome, 'São Paulo');
      expect(cidades.first.uf, 'SP');
      expect(cidades.first.id, 244);
      expect(cidades.last.id, 5016);
    });

    test('lista vazia quando nenhuma cidade é encontrada', () {
      expect(CptecParser.parseCidades('<cidades></cidades>'), isEmpty);
      expect(CptecParser.parseCidades('<cidades/>'), isEmpty);
    });

    test('resposta inválida gera RespostaInvalidaException', () {
      expect(
        () => CptecParser.parseCidades('<html><body>Erro'),
        throwsA(isA<RespostaInvalidaException>()),
      );
      expect(
        () => CptecParser.parseCidades('<outro></outro>'),
        throwsA(isA<RespostaInvalidaException>()),
      );
      expect(
        () => CptecParser.parseCidades(''),
        throwsA(isA<RespostaInvalidaException>()),
      );
    });
  });

  group('CptecParser.parsePrevisao', () {
    test('lê os quatro dias e a data de atualização', () {
      final previsao = CptecParser.parsePrevisao(xmlPrevisao);
      expect(previsao.nome, 'São Paulo');
      expect(previsao.atualizacao, DateTime(2026, 11, 16));
      expect(previsao.dias, hasLength(4));

      final primeiro = previsao.dias.first;
      expect(primeiro.data, DateTime(2026, 11, 16));
      expect(primeiro.sigla, 'pn');
      expect(primeiro.maxima, 28);
      expect(primeiro.minima, 18);
      expect(primeiro.iuv, 11.0);
    });

    test('campos ausentes ou "null" viram null sem lançar exceção', () {
      final dias = CptecParser.parsePrevisao(xmlPrevisao).dias;
      expect(dias[2].iuv, isNull); // tag <iuv> ausente
      expect(dias[3].maxima, isNull); // "null"
      expect(dias[3].iuv, isNull);
      expect(dias[3].minima, 15);
    });

    test('código sem previsão resulta em lista vazia', () {
      const xml = '<cidade><nome>null</nome><uf>null</uf>'
          '<atualizacao>1969-12-31</atualizacao>'
          '<previsao><dia>null</dia><tempo>null</tempo>'
          '<maxima>null</maxima><minima>null</minima><iuv>null</iuv>'
          '</previsao></cidade>';
      final previsao = CptecParser.parsePrevisao(xml);
      expect(previsao.vazia, isTrue);
      expect(previsao.atualizacao, isNull);
      expect(previsao.nome, isNull);
    });
  });

  test('decodifica respostas em ISO-8859-1 e UTF-8', () {
    expect(CptecParser.decodificar(latin1.encode(xmlCidades)), xmlCidades);
    const utf = '<?xml version="1.0" encoding="UTF-8"?><cidades/>';
    expect(CptecParser.decodificar(utf8.encode(utf)), utf);
    expect(CptecParser.decodificar(latin1.encode('<a>São</a>')), '<a>São</a>');
  });

  test('condições do tempo convertidas em descrições', () {
    expect(condicaoPorSigla('pn').descricao, 'Parcialmente nublado');
    expect(condicaoPorSigla('CL').descricao, 'Céu claro');
    expect(condicaoPorSigla(null).descricao, 'Condição não informada');
    expect(condicaoPorSigla('xx').descricao, contains('desconhecida'));
    expect(condicoesTempo, hasLength(40));
  });

  test('remove acentos para a busca', () {
    expect(removerAcentos('São João del-Rei'), 'Sao Joao del-Rei');
    expect(removerAcentos('Goiânia, Maceió, Itajubá'), 'Goiania, Maceio, Itajuba');
  });

  test('formata datas em português', () {
    final data = DateTime(2026, 11, 16);
    expect(formatarData(data), '16/11/2026');
    expect(diaDaSemana(data), 'Segunda-feira');
    expect(rotuloDia(data, agora: DateTime(2026, 11, 16, 23)), 'Hoje');
    expect(rotuloDia(data, agora: DateTime(2026, 11, 15)), 'Amanhã');
  });
}
