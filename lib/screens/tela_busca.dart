import 'package:flutter/material.dart';

import '../models/cidade.dart';
import '../services/armazenamento_local.dart';
import '../services/cptec_service.dart';
import '../widgets/mensagem_estado.dart';
import '../widgets/rodape_fonte.dart';
import 'tela_previsao.dart';

class TelaBusca extends StatefulWidget {
  final CptecService? servico;
  final ArmazenamentoLocal? armazenamento;

  const TelaBusca({super.key, this.servico, this.armazenamento});

  @override
  State<TelaBusca> createState() => _TelaBuscaState();
}

class _TelaBuscaState extends State<TelaBusca> {
  late final CptecService _servico = widget.servico ?? CptecService();
  late final ArmazenamentoLocal _armazenamento =
      widget.armazenamento ?? ArmazenamentoLocal();
  final _controller = TextEditingController();

  bool _carregando = false;
  List<Cidade>? _resultados;
  CptecException? _erro;
  String _termoPesquisado = '';
  List<Cidade> _recentes = [];
  List<Cidade> _favoritas = [];

  @override
  void initState() {
    super.initState();
    _carregarCidadesSalvas();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _carregarCidadesSalvas() async {
    final recentes = await _armazenamento.recentes();
    final favoritas = await _armazenamento.favoritas();
    if (!mounted) return;
    setState(() {
      _recentes = recentes;
      _favoritas = favoritas;
    });
  }

  Future<void> _buscar() async {
    final termo = _controller.text.trim();
    FocusScope.of(context).unfocus();
    if (termo.length < 2) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Digite pelo menos 2 letras do nome da cidade.'),
          ),
        );
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
      _termoPesquisado = termo;
    });

    try {
      final cidades = await _servico.buscarCidades(termo);
      if (!mounted) return;
      setState(() => _resultados = cidades);
    } catch (falha) {
      final e = falha is CptecException
          ? falha
          : const CptecException(
              TipoErroCptec.respostaInvalida,
              'Ocorreu um erro inesperado ao buscar as cidades.',
            );
      if (!mounted) return;
      setState(() {
        _erro = e;
        _resultados = null;
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _limparBusca() {
    _controller.clear();
    setState(() {
      _resultados = null;
      _erro = null;
    });
  }

  Future<void> _abrirPrevisao(Cidade cidade) async {
    await _armazenamento.registrarRecente(cidade);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TelaPrevisao(
          cidade: cidade,
          servico: _servico,
          armazenamento: _armazenamento,
        ),
      ),
    );
    await _carregarCidadesSalvas();
  }

  Future<void> _limparRecentes() async {
    await _armazenamento.limparRecentes();
    await _carregarCidadesSalvas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão do Tempo'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                labelText: 'Nome da cidade',
                hintText: 'Ex.: São Paulo',
                prefixIcon: const Icon(Icons.location_city),
                border: const OutlineInputBorder(),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, valor, child) => valor.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Limpar',
                          icon: const Icon(Icons.clear),
                          onPressed: _limparBusca,
                        ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _carregando ? null : _buscar,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ),
          ),
          if (_carregando) const LinearProgressIndicator(),
          Expanded(child: _conteudo()),
          const RodapeFonte(),
        ],
      ),
    );
  }

  Widget _conteudo() {
    if (_carregando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando cidades no CPTEC/INPE...'),
          ],
        ),
      );
    }

    final erro = _erro;
    if (erro != null) {
      return MensagemErro(erro: erro, onTentarNovamente: _buscar);
    }

    final resultados = _resultados;
    if (resultados != null) {
      if (resultados.isEmpty) {
        return MensagemEstado(
          icone: Icons.location_off,
          titulo: 'Nenhuma cidade encontrada',
          mensagem: 'Não encontramos localidades para "$_termoPesquisado". '
              'Verifique a grafia e tente novamente.',
        );
      }
      return _listaResultados(resultados);
    }

    return _cidadesSalvas();
  }

  Widget _listaResultados(List<Cidade> cidades) {
    return ListView.separated(
      itemCount: cidades.length + 1,
      separatorBuilder: (_, indice) =>
          indice == 0 ? const SizedBox.shrink() : const Divider(height: 1),
      itemBuilder: (context, indice) {
        if (indice == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              cidades.length == 1
                  ? '1 localidade encontrada'
                  : '${cidades.length} localidades encontradas',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          );
        }
        final cidade = cidades[indice - 1];
        return _ItemCidade(
          cidade: cidade,
          favorita: _favoritas.contains(cidade),
          onTap: () => _abrirPrevisao(cidade),
        );
      },
    );
  }

  Widget _cidadesSalvas() {
    if (_recentes.isEmpty && _favoritas.isEmpty) {
      return const MensagemEstado(
        icone: Icons.travel_explore,
        titulo: 'Pesquise uma cidade',
        mensagem: 'Digite o nome de uma cidade brasileira para consultar a '
            'previsão do tempo dos próximos dias.',
      );
    }

    final tema = Theme.of(context);
    return ListView(
      children: [
        if (_favoritas.isNotEmpty) ...[
          const _Cabecalho(titulo: 'Favoritas', icone: Icons.star),
          for (final cidade in _favoritas)
            _ItemCidade(
              cidade: cidade,
              favorita: true,
              onTap: () => _abrirPrevisao(cidade),
            ),
        ],
        if (_recentes.isNotEmpty) ...[
          _Cabecalho(
            titulo: 'Consultadas recentemente',
            icone: Icons.history,
            acao: TextButton(
              onPressed: _limparRecentes,
              child: const Text('Limpar'),
            ),
          ),
          for (final cidade in _recentes)
            _ItemCidade(
              cidade: cidade,
              favorita: _favoritas.contains(cidade),
              onTap: () => _abrirPrevisao(cidade),
            ),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'As cidades favoritas, as recentes e a última previsão de cada '
            'cidade ficam salvas no aparelho.',
            style: tema.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _Cabecalho extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Widget? acao;

  const _Cabecalho({required this.titulo, required this.icone, this.acao});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Icon(icone, size: 18, color: tema.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              style: tema.textTheme.titleSmall
                  ?.copyWith(color: tema.colorScheme.primary),
            ),
          ),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

class _ItemCidade extends StatelessWidget {
  final Cidade cidade;
  final bool favorita;
  final VoidCallback onTap;

  const _ItemCidade({
    required this.cidade,
    required this.favorita,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: tema.colorScheme.primaryContainer,
        foregroundColor: tema.colorScheme.onPrimaryContainer,
        child: Text(
          cidade.uf.isEmpty ? '?' : cidade.uf,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      title: Text(cidade.nome),
      subtitle: Text(
        cidade.uf.isEmpty
            ? 'UF não informada'
            : 'Unidade da federação: ${cidade.uf}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (favorita) const Icon(Icons.star, color: Colors.amber, size: 20),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
