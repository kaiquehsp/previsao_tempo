class PrevisaoDia {
  final DateTime? data;

  final String? sigla;
  final int? minima;
  final int? maxima;

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

class PrevisaoCidade {
  final String? nome;
  final String? uf;

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
