import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../utils/texto.dart';
import 'cptec_parser.dart';

enum TipoErroCptec {
  semConexao,
  tempoEsgotado,
  servicoIndisponivel,
  respostaInvalida,
}

/// Erro tratado e já com uma mensagem amigável para o usuário.
class CptecException implements Exception {
  final TipoErroCptec tipo;
  final String mensagem;

  const CptecException(this.tipo, this.mensagem);

  @override
  String toString() => mensagem;
}

class ResultadoPrevisao {
  final PrevisaoCidade previsao;

  /// XML original, guardado no cache local para uso sem conexão.
  final String xml;

  const ResultadoPrevisao(this.previsao, this.xml);
}

/// Cliente do serviço XML do CPTEC/INPE (https://servicos.cptec.inpe.br/XML/).
class CptecService {
  /// Tentamos HTTPS primeiro; se a conexão falhar, tentamos HTTP.
  static const List<String> enderecosBase = [
    'https://servicos.cptec.inpe.br/XML',
    'http://servicos.cptec.inpe.br/XML',
  ];

  static const Duration tempoLimite = Duration(seconds: 15);

  final http.Client _client;

  CptecService({http.Client? client}) : _client = client ?? http.Client();

  /// Pesquisa localidades pelo nome (`listaCidades?city=`).
  /// O serviço exige o nome sem acentos.
  Future<List<Cidade>> buscarCidades(String termo) async {
    final busca = removerAcentos(termo)
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .toLowerCase();
    if (busca.isEmpty) return const [];

    final xml = await _get('/listaCidades?city=${Uri.encodeComponent(busca)}');
    return _converter(() => CptecParser.parseCidades(xml));
  }

  /// Previsão para 4 dias (`cidade/{codigo}/previsao.xml`).
  Future<ResultadoPrevisao> buscarPrevisao(int codigoCidade) async {
    final xml = await _get('/cidade/$codigoCidade/previsao.xml');
    final previsao = _converter(() => CptecParser.parsePrevisao(xml));
    return ResultadoPrevisao(previsao, xml);
  }

  Future<String> _get(String caminho) async {
    for (final base in enderecosBase) {
      try {
        final resposta =
            await _client.get(Uri.parse('$base$caminho')).timeout(tempoLimite);

        if (resposta.statusCode != 200) {
          throw CptecException(
            TipoErroCptec.servicoIndisponivel,
            'O serviço do CPTEC/INPE está indisponível no momento '
            '(código ${resposta.statusCode}). Tente novamente mais tarde.',
          );
        }
        if (resposta.bodyBytes.isEmpty) {
          throw const CptecException(
            TipoErroCptec.respostaInvalida,
            'O serviço do CPTEC/INPE retornou uma resposta vazia.',
          );
        }
        return CptecParser.decodificar(resposta.bodyBytes);
      } on CptecException {
        rethrow;
      } on TimeoutException {
        throw const CptecException(
          TipoErroCptec.tempoEsgotado,
          'O serviço do CPTEC/INPE demorou demais para responder. '
          'Verifique sua conexão e tente novamente.',
        );
      } catch (_) {
        // Falha de conexão (sem internet, DNS, TLS...). Tenta o próximo
        // endereço; se todos falharem, informa o usuário abaixo.
      }
    }
    throw const CptecException(
      TipoErroCptec.semConexao,
      'Não foi possível conectar ao serviço do CPTEC/INPE. '
      'Verifique sua conexão com a internet.',
    );
  }

  T _converter<T>(T Function() converter) {
    try {
      return converter();
    } on RespostaInvalidaException {
      throw const CptecException(
        TipoErroCptec.respostaInvalida,
        'O serviço do CPTEC/INPE retornou dados em um formato inválido. '
        'Tente novamente mais tarde.',
      );
    }
  }
}
