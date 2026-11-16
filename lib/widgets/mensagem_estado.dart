import 'package:flutter/material.dart';

import '../services/cptec_service.dart';

class MensagemEstado extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? textoAcao;
  final VoidCallback? onAcao;
  final Color? cor;

  const MensagemEstado({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.textoAcao,
    this.onAcao,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 64, color: cor ?? tema.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium,
            ),
            if (textoAcao != null && onAcao != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAcao,
                icon: const Icon(Icons.refresh),
                label: Text(textoAcao!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MensagemErro extends StatelessWidget {
  final CptecException erro;
  final VoidCallback onTentarNovamente;

  const MensagemErro({
    super.key,
    required this.erro,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    final (icone, titulo) = switch (erro.tipo) {
      TipoErroCptec.semConexao => (Icons.wifi_off, 'Sem conexão'),
      TipoErroCptec.tempoEsgotado => (Icons.timer_off, 'Tempo esgotado'),
      TipoErroCptec.servicoIndisponivel =>
        (Icons.cloud_off, 'Serviço indisponível'),
      TipoErroCptec.respostaInvalida =>
        (Icons.error_outline, 'Resposta inválida'),
    };
    return MensagemEstado(
      icone: icone,
      titulo: titulo,
      mensagem: erro.mensagem,
      cor: Theme.of(context).colorScheme.error,
      textoAcao: 'Tentar novamente',
      onAcao: onTentarNovamente,
    );
  }
}
