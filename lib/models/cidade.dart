class Cidade {
  final int id;
  final String nome;
  final String uf;

  const Cidade({required this.id, required this.nome, required this.uf});

  String get nomeCompleto => uf.isEmpty ? nome : '$nome - $uf';

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'uf': uf};

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
