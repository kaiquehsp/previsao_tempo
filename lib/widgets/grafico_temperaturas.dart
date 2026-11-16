import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/previsao.dart';
import '../utils/texto.dart';

/// Gráfico de linhas com as temperaturas mínima e máxima de cada dia.
class GraficoTemperaturas extends StatelessWidget {
  final List<PrevisaoDia> dias;

  const GraficoTemperaturas({super.key, required this.dias});

  static const corMaxima = Colors.deepOrange;
  static const corMinima = Colors.blue;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final valores = <int>[
      for (final dia in dias) ...[
        if (dia.minima != null) dia.minima!,
        if (dia.maxima != null) dia.maxima!,
      ],
    ];

    if (valores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('Não há temperaturas disponíveis para montar o gráfico.'),
        ),
      );
    }

    // Eixo Y em múltiplos de 5 °C, com folga acima e abaixo.
    const intervaloY = 5.0;
    final menor = valores.reduce(math.min) - 2;
    final maior = valores.reduce(math.max) + 2;
    final minY = (menor / intervaloY).floor() * intervaloY;
    final maxY = (maior / intervaloY).ceil() * intervaloY;

    FlSpot ponto(int indice, int? valor) => valor == null
        ? FlSpot.nullSpot
        : FlSpot(indice.toDouble(), valor.toDouble());

    LineChartBarData linha(List<FlSpot> pontos, Color cor) => LineChartBarData(
          spots: pontos,
          isCurved: true,
          preventCurveOverShooting: true,
          color: cor,
          barWidth: 3,
          dotData: const FlDotData(show: true),
        );

    final maximas = [
      for (var i = 0; i < dias.length; i++) ponto(i, dias[i].maxima),
    ];
    final minimas = [
      for (var i = 0; i < dias.length; i++) ponto(i, dias[i].minima),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Temperaturas (°C)', style: tema.textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: -0.4,
              maxX: dias.length - 1 + 0.4,
              minY: minY,
              maxY: maxY,
              lineBarsData: [linha(maximas, corMaxima), linha(minimas, corMinima)],
              gridData: const FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: intervaloY,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: intervaloY,
                    reservedSize: 40,
                    getTitlesWidget: (valor, meta) => Text(
                      '${valor.round()}°',
                      style: tema.textTheme.bodySmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 40,
                    minIncluded: false,
                    maxIncluded: false,
                    getTitlesWidget: (valor, meta) =>
                        _rotuloEixoX(context, valor),
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (pontosTocados) => pontosTocados
                      .map(
                        (p) => LineTooltipItem(
                          '${p.barIndex == 0 ? 'Máx' : 'Mín'}: '
                          '${p.y.round()} °C',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legenda(cor: corMaxima, texto: 'Máxima'),
            SizedBox(width: 24),
            _Legenda(cor: corMinima, texto: 'Mínima'),
          ],
        ),
      ],
    );
  }

  Widget _rotuloEixoX(BuildContext context, double valor) {
    final indice = valor.round();
    if ((valor - indice).abs() > 0.01 || indice < 0 || indice >= dias.length) {
      return const SizedBox.shrink();
    }
    final data = dias[indice].data;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        data == null
            ? 'Dia ${indice + 1}'
            : '${diaDaSemanaAbreviado(data)}\n${formatarDiaMes(data)}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String texto;

  const _Legenda({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto),
      ],
    );
  }
}
