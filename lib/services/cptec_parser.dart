import 'dart:convert';

import 'package:xml/xml.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';

class RespostaInvalidaException implements Exception {
  final String detalhe;
  const RespostaInvalidaException(this.detalhe);

  @override
  String toString() => 'RespostaInvalidaException: $detalhe';
}

class CptecParser {
  CptecParser._();

  static String decodificar(List<int> bytes) {
    final inicio = latin1.decode(bytes.take(200).toList(), allowInvalid: true);
    final encoding = RegExp(r'''encoding\s*=\s*["']([^"']+)["']''')
        .firstMatch(inicio)
        ?.group(1)
        ?.toLowerCase();
    const latinos = {'iso-8859-1', 'latin1', 'latin-1', 'windows-1252'};
    if (encoding != null && latinos.contains(encoding)) {
      return latin1.decode(bytes, allowInvalid: true);
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  static List<Cidade> parseCidades(String xml) {
    try {
      final raiz = _raiz(xml, 'cidades');
      final cidades = <Cidade>[];
      for (final el in raiz.findElements('cidade')) {
        final id = int.tryParse(_texto(el, 'id') ?? '');
        final nome = _texto(el, 'nome');
        if (id == null || nome == null) continue;
        cidades.add(Cidade(id: id, nome: nome, uf: _texto(el, 'uf') ?? ''));
      }
      return cidades;
    } on RespostaInvalidaException {
      rethrow;
    } catch (e) {
      throw RespostaInvalidaException('$e');
    }
  }

  static PrevisaoCidade parsePrevisao(String xml) {
    try {
      final raiz = _raiz(xml, 'cidade');
      final dias = raiz
          .findElements('previsao')
          .map(
            (el) => PrevisaoDia(
              data: _data(_texto(el, 'dia')),
              sigla: _texto(el, 'tempo')?.toLowerCase(),
              maxima: _temperatura(_texto(el, 'maxima')),
              minima: _temperatura(_texto(el, 'minima')),
              iuv: _iuv(_texto(el, 'iuv')),
            ),
          )
          .where((dia) => dia.temDados)
          .toList();

      return PrevisaoCidade(
        nome: _texto(raiz, 'nome'),
        uf: _texto(raiz, 'uf'),
        atualizacao: _data(_texto(raiz, 'atualizacao')),
        dias: dias,
      );
    } on RespostaInvalidaException {
      rethrow;
    } catch (e) {
      throw RespostaInvalidaException('$e');
    }
  }

  static XmlElement _raiz(String xml, String nomeEsperado) {
    final conteudo = xml.trim();
    if (conteudo.isEmpty) {
      throw const RespostaInvalidaException('resposta vazia');
    }
    final XmlDocument documento;
    try {
      documento = XmlDocument.parse(conteudo);
    } on XmlException catch (e) {
      throw RespostaInvalidaException('XML malformado: ${e.message}');
    }
    final raiz = documento.rootElement;
    if (raiz.name.local != nomeEsperado) {
      throw RespostaInvalidaException(
        'elemento raiz inesperado: <${raiz.name.local}>',
      );
    }
    return raiz;
  }

  static String? _texto(XmlElement pai, String tag) {
    final valor = pai.getElement(tag)?.innerText.trim();
    if (valor == null || valor.isEmpty) return null;
    const nulos = {'null', 'undefined', 'nan', '-'};
    if (nulos.contains(valor.toLowerCase())) return null;
    return valor;
  }

  static DateTime? _data(String? valor) {
    if (valor == null) return null;
    final data = DateTime.tryParse(valor);
    if (data == null || data.year < 2000) return null;
    return data;
  }

  static int? _temperatura(String? valor) {
    if (valor == null) return null;
    final numero = num.tryParse(valor.replaceAll(',', '.'));
    if (numero == null || numero < -60 || numero > 60) return null;
    return numero.round();
  }

  static double? _iuv(String? valor) {
    if (valor == null) return null;
    final numero = double.tryParse(valor.replaceAll(',', '.'));
    if (numero == null || numero < 0 || numero > 30) return null;
    return numero;
  }
}
