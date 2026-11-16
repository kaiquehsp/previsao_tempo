import 'package:flutter/material.dart';

import '../models/cidade.dart';
import '../models/previsao.dart';
import '../services/armazenamento_local.dart';
import '../services/cptec_service.dart';
import '../utils/texto.dart';
import '../widgets/cartao_dia.dart';
import '../widgets/grafico_temperaturas.dart';
import '../widgets/mensagem_estado.dart';
import '../widgets/rodape_fonte.dart';

/// Previsão de 4 dias da cidade selecionada, com gráfico de temperaturas.
class TelaPrevisao extends StatefulWidget {
  final Cidade cidade;
  final CptecService servico;
  final ArmazenamentoLocal armazenamento;

  const TelaPrevisao({
    super.key,
    required this.cidade,
    required this.servico,
    required this.armazenamento,
  });

  @override
  State<TelaPrevisao> createState() => _TelaPrevisaoState();
}

class _TelaPrevisaoState extends State<TelaPrevisao> {
  PrevisaoCidade? _previsao;

  /// `true` quando a previsão exibida veio do cache local.
  bool _exibindoCache = false;
  DateTime? _salvaEm;

  bool _carregando = false;
  CptecException? _erro;
  bool _favorita = false;

  Cidade get _cidade => widget.cidade;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  /// Mostra imediatamente a última previsão salva (se houver) e, em seguida,
  /// busca a previsão atualizada no CPTEC/INPE.
  Future<void> _iniciar() async {
    final favorita = await widget.armazenamento.ehFavorita(_cidade);
    final salva = await widget.armazenamento.previsaoSalva(_cidade.id);
    if (!mounted) return;
    setState(() {
      _favorita = favorita;
      if (salva != null) {
        _previsao = salva.previsao;
        _salvaEm = salva.salvaEm;
        _exibindoCache = true;
      }
    });
    await _atualizar();
  }

  Future<void> _atualizar() async {
    if (_carregando) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await widget.servico.buscarPrevisao(_cidade.id);
      if (!resultado.previsao.vazia) {
        await widget.armazenamento.salvarPrevisao(_cidade.id, resultado.xml);
      }
      if (!mounted) return;
      setState(() {
        if (resultado.previsao.vazia && _previsao != null && _exibindoCache) {
          // O serviço não trouxe previsão: mantém a salva e avisa.
          _erro = const CptecException(
            TipoErroCptec.respostaInvalida,
            'O CPTEC/INPE não retornou previsão para esta cidade agora.',
          );
        } else {
          _previsao = resultado.previsao;
          _exibindoCache = false;
          _salvaEm = DateTime.now();
        }
      });
    } catch (falha) {
      // Erros não previstos também viram mensagem (o app não pode fechar).
      final e = falha is CptecException
          ? falha
          : const CptecException(
              TipoErroCptec.respostaInvalida,
              'Ocorreu um erro inesperado ao carregar a previsão.',
            );
      if (!mounted) return;
      setState(() => _erro = e);
      if (_previsao != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${e.mensagem} Exibindo a última previsão salva.'),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _alternarFavorita() async {
    final favorita = await widget.armazenamento.alternarFavorita(_cidade);
    if (!mounted) return;
    setState(() => _favorita = favorita);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            favorita
                ? '${_cidade.nome} adicionada às favoritas.'
                : '${_cidade.nome} removida das favoritas.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_cidade.nomeCompleto),
        actions: [
          IconButton(
            tooltip: _favorita
                ? 'Remover das favoritas'
                : 'Adicionar às favoritas',
            icon: Icon(_favorita ? Icons.star : Icons.star_border),
            onPressed: _alternarFavorita,
          ),
          IconButton(
            tooltip: 'Atualizar previsão',
            icon: const Icon(Icons.refresh),
            onPressed: _carregando ? null : _atualizar,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_carregando) const LinearProgressIndicator(),
          Expanded(child: _corpo()),
          const RodapeFonte(),
        ],
      ),
    );
  }

  Widget _corpo() {
    final previsao = _previsao;

    if (previsao == null) {
      final erro = _erro;
      if (erro != null && !_carregando) {
        return MensagemErro(erro: erro, onTentarNovamente: _atualizar);
      }
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Consultando a previsão no CPTEC/INPE...'),
          ],
        ),
      );
    }

    if (previsao.vazia) {
      return MensagemEstado(
        icone: Icons.cloud_off,
        titulo: 'Nenhuma previsão disponível',
        mensagem: 'O CPTEC/INPE não retornou previsão para '
            '${_cidade.nomeCompleto} no momento. '
            'Tente atualizar mais tarde.',
        textoAcao: 'Atualizar',
        onAcao: _carregando ? null : _atualizar,
      );
    }

    final tema = Theme.of(context);
    return RefreshIndicator(
      onRefresh: _atualizar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_exibindoCache && _erro != null) _avisoCache(tema),
          _cabecalho(previsao, tema),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
              child: GraficoTemperaturas(dias: previsao.dias),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            previsao.dias.length == 1
                ? 'Previsão para 1 dia'
                : 'Previsão para ${previsao.dias.length} dias',
            style: tema.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          for (final dia in previsao.dias) CartaoDia(dia: dia),
          const SizedBox(height: 8),
          Text(
            'Arraste para baixo ou toque em ↻ para atualizar.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _cabecalho(PrevisaoCidade previsao, ThemeData tema) {
    final nome = previsao.nome ?? _cidade.nome;
    final uf = previsao.uf ?? _cidade.uf;
    final atualizacao = previsao.atualizacao;
    return Card(
      color: tema.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              uf.isEmpty ? nome : '$nome - $uf',
              style: tema.textTheme.headlineSmall?.copyWith(
                color: tema.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.update,
                  size: 18,
                  color: tema.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    atualizacao == null
                        ? 'Data de atualização não informada pelo serviço'
                        : 'Atualizado pelo CPTEC/INPE em '
                            '${formatarData(atualizacao)}',
                    style: tema.textTheme.bodyMedium?.copyWith(
                      color: tema.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avisoCache(ThemeData tema) {
    final salvaEm = _salvaEm;
    return Card(
      color: tema.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.cloud_off, color: tema.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_erro?.mensagem ?? ''}\nExibindo a previsão salva no '
                'aparelho${salvaEm == null ? '' : ' em ${formatarDataHora(salvaEm)}'}.',
                style: TextStyle(color: tema.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
