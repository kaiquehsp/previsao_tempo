/// Localidade retornada pelo serviço `listaCidades` do CPTEC/INPE.
class Cidade {
  /// Código da localidade informado pelo próprio CPTEC/INPE.
  /// É esse código que é usado na consulta da previsão.
  final int id;
  final String nome;
  final String uf;

  const Cidade({required this.id, required this.nome, required this.uf});

  String get nomeCompleto => uf.isEmpty ? nome : '$nome - $uf';

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'uf': uf};

  /// Reconstrói uma cidade salva localmente. Retorna `null` se os dados
  /// estiverem incompletos ou corrompidos, em vez de lançar exceção.
  static Cidade? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final nome = json['nome'];
    final uf = json['uf'];
    if (id is! int || nome is! String || nome.isEmpty) return null;
    return Cidade(id: id, nome: nome, uf: uf is String ? uf : '');
  }

  @override
  bool operator ==(Object other) => other is Cidade && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Cidade($id, $nomeCompleto)';
}
