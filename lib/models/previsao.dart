/// Previsão de um único dia (elemento `<previsao>` do XML do CPTEC/INPE).
///
/// Todos os campos são opcionais: o serviço pode omitir valores ou enviar
/// "null", e o aplicativo precisa continuar funcionando nesses casos.
class PrevisaoDia {
  final DateTime? data;

  /// Sigla da condição do tempo (ex.: `pn`, `c`, `cl`).
  final String? sigla;
  final int? minima;
  final int? maxima;

  /// Índice ultravioleta máximo do dia.
  final double? iuv;

  const PrevisaoDia({
    this.data,
    this.sigla,
    this.minima,
    this.maxima,
    this.iuv,
  });

  bool get temDados =>
      data != null || sigla != null || minima != null || maxima != null;
}

/// Previsão completa de uma cidade (elemento raiz `<cidade>`).
class PrevisaoCidade {
  final String? nome;
  final String? uf;

  /// Data de atualização informada pelo serviço.
  final DateTime? atualizacao;
  final List<PrevisaoDia> dias;

  const PrevisaoCidade({
    this.nome,
    this.uf,
    this.atualizacao,
    this.dias = const [],
  });

  bool get vazia => dias.isEmpty;
}
