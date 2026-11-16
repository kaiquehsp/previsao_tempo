import 'package:flutter/material.dart';

import '../models/previsao.dart';
import '../utils/condicoes_tempo.dart';
import '../utils/texto.dart';

/// Cartão com a previsão de um dia: data, ícone, condição, mín/máx e IUV.
class CartaoDia extends StatelessWidget {
  final PrevisaoDia dia;

  const CartaoDia({super.key, required this.dia});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final condicao = condicaoPorSigla(dia.sigla);
    final data = dia.data;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: tema.colorScheme.surfaceContainerHighest,
                  child: Icon(condicao.icone, size: 34, color: condicao.cor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data == null ? 'Data não informada' : rotuloDia(data),
                        style: tema.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (data != null)
                        Text(
                          '${diaDaSemana(data)}, ${formatarData(data)}',
                          style: tema.textTheme.bodySmall,
                        ),
                      const SizedBox(height: 4),
                      Text(condicao.descricao,
                          style: tema.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Temperaturas(minima: dia.minima, maxima: dia.maxima),
              ],
            ),
            const SizedBox(height: 12),
            _IndiceUv(iuv: dia.iuv),
          ],
        ),
      ),
    );
  }
}

class _Temperaturas extends StatelessWidget {
  final int? minima;
  final int? maxima;

  const _Temperaturas({required this.minima, required this.maxima});

  String _formatar(int? valor) => valor == null ? '--' : '$valor °C';

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.titleMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward, size: 16, color: Colors.deepOrange),
            Text(
              _formatar(maxima),
              style: estilo?.copyWith(color: Colors.deepOrange),
              semanticsLabel: 'Máxima ${_formatar(maxima)}',
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward, size: 16, color: Colors.blue),
            Text(
              _formatar(minima),
              style: estilo?.copyWith(color: Colors.blue),
              semanticsLabel: 'Mínima ${_formatar(minima)}',
            ),
          ],
        ),
      ],
    );
  }
}

class _IndiceUv extends StatelessWidget {
  final double? iuv;

  const _IndiceUv({required this.iuv});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final faixa = faixaUv(iuv);
    final valor = iuv;

    if (faixa == null || valor == null) {
      return Row(
        children: [
          Icon(Icons.wb_sunny_outlined,
              size: 18, color: tema.colorScheme.outline),
          const SizedBox(width: 6),
          Text('Índice UV não disponível', style: tema.textTheme.bodySmall),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.wb_sunny_outlined, size: 18, color: faixa.cor),
        const SizedBox(width: 6),
        Text(
          'Índice UV: ${valor.toStringAsFixed(1)}',
          style: tema.textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: faixa.cor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            faixa.rotulo,
            style: tema.textTheme.labelSmall?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
