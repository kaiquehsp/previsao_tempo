import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import 'cptec_parser.dart';

/// Previsão recuperada do cache local, com a data em que foi salva.
class PrevisaoSalva {
  final PrevisaoCidade previsao;
  final DateTime salvaEm;

  const PrevisaoSalva(this.previsao, this.salvaEm);
}

/// Persistência local com `shared_preferences` (chave/valor):
///
/// * `cidades_recentes`  → JSON com as últimas cidades consultadas;
/// * `cidades_favoritas` → JSON com as cidades marcadas como favoritas;
/// * `previsao_cache_{codigo}` → JSON com o XML da última previsão
///   obtida para a cidade e a data/hora em que foi salva.
///
/// Qualquer dado corrompido é ignorado (nunca derruba o aplicativo).
class ArmazenamentoLocal {
  static const chaveRecentes = 'cidades_recentes';
  static const chaveFavoritas = 'cidades_favoritas';
  static const prefixoCache = 'previsao_cache_';
  static const maximoRecentes = 8;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---------------------------------------------------------------- recentes

  Future<List<Cidade>> recentes() => _lerCidades(chaveRecentes);

  Future<void> registrarRecente(Cidade cidade) async {
    final lista = await recentes();
    lista.remove(cidade);
    lista.insert(0, cidade);
    await _salvarCidades(chaveRecentes, lista.take(maximoRecentes).toList());
  }

  Future<void> limparRecentes() async {
    final prefs = await _prefs;
    await prefs.remove(chaveRecentes);
  }

  // --------------------------------------------------------------- favoritas

  Future<List<Cidade>> favoritas() => _lerCidades(chaveFavoritas);

  Future<bool> ehFavorita(Cidade cidade) async =>
      (await favoritas()).contains(cidade);

  /// Adiciona ou remove dos favoritos. Retorna `true` se ficou favorita.
  Future<bool> alternarFavorita(Cidade cidade) async {
    final lista = await favoritas();
    final bool favorita;
    if (lista.contains(cidade)) {
      lista.remove(cidade);
      favorita = false;
    } else {
      lista.add(cidade);
      lista.sort((a, b) => a.nome.compareTo(b.nome));
      favorita = true;
    }
    await _salvarCidades(chaveFavoritas, lista);
    return favorita;
  }

  // -------------------------------------------------------- cache previsão

  Future<void> salvarPrevisao(int codigoCidade, String xml) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$prefixoCache$codigoCidade',
      jsonEncode({'xml': xml, 'salvaEm': DateTime.now().toIso8601String()}),
    );
  }

  Future<PrevisaoSalva?> previsaoSalva(int codigoCidade) async {
    try {
      final prefs = await _prefs;
      final texto = prefs.getString('$prefixoCache$codigoCidade');
      if (texto == null) return null;
      final dados = jsonDecode(texto);
      if (dados is! Map) return null;
      final xml = dados['xml'];
      final salvaEm = DateTime.tryParse('${dados['salvaEm']}');
      if (xml is! String || salvaEm == null) return null;
      final previsao = CptecParser.parsePrevisao(xml);
      if (previsao.vazia) return null;
      return PrevisaoSalva(previsao, salvaEm);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------- auxiliares

  Future<List<Cidade>> _lerCidades(String chave) async {
    try {
      final prefs = await _prefs;
      final texto = prefs.getString(chave);
      if (texto == null) return [];
      final dados = jsonDecode(texto);
      if (dados is! List) return [];
      return dados.map(Cidade.fromJson).whereType<Cidade>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _salvarCidades(String chave, List<Cidade> cidades) async {
    final prefs = await _prefs;
    await prefs.setString(
      chave,
      jsonEncode(cidades.map((c) => c.toJson()).toList()),
    );
  }
}
