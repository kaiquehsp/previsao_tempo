import 'package:flutter/material.dart';

/// Descrição, ícone e cor de uma condição do tempo.
class CondicaoTempo {
  final String descricao;
  final IconData icone;
  final Color cor;

  const CondicaoTempo(this.descricao, this.icone, this.cor);
}

// Ícones e cores por "família" de condição.
const _sol = (Icons.wb_sunny, Color(0xFFF9A825));
const _solComNuvens = (Icons.filter_drama, Color(0xFFFFB300));
const _nublado = (Icons.cloud, Color(0xFF78909C));
const _encoberto = (Icons.cloud, Color(0xFF546E7A));
const _possivelChuva = (Icons.water_drop_outlined, Color(0xFF4FC3F7));
const _pancadas = (Icons.water_drop, Color(0xFF29B6F6));
const _chuva = (Icons.umbrella, Color(0xFF1E88E5));
const _chuvisco = (Icons.grain, Color(0xFF64B5F6));
const _tempestade = (Icons.flash_on, Color(0xFF5E35B1));
const _nevoeiro = (Icons.blur_on, Color(0xFF90A4AE));
const _frio = (Icons.ac_unit, Color(0xFF4DD0E1));
const _indefinido = (Icons.help_outline, Color(0xFF9E9E9E));

CondicaoTempo _c(String descricao, (IconData, Color) estilo) =>
    CondicaoTempo(descricao, estilo.$1, estilo.$2);

/// Tabela de siglas conforme a documentação do CPTEC/INPE
/// (https://servicos.cptec.inpe.br/XML/ – "Condições do tempo").
final Map<String, CondicaoTempo> condicoesTempo = {
  'ec': _c('Encoberto com chuvas isoladas', _pancadas),
  'ci': _c('Chuvas isoladas', _pancadas),
  'c': _c('Chuva', _chuva),
  'in': _c('Instável', _tempestade),
  'pp': _c('Possibilidade de pancadas de chuva', _possivelChuva),
  'cm': _c('Chuva pela manhã', _chuva),
  'cn': _c('Chuva à noite', _chuva),
  'pt': _c('Pancadas de chuva à tarde', _pancadas),
  'pm': _c('Pancadas de chuva pela manhã', _pancadas),
  'np': _c('Nublado e pancadas de chuva', _pancadas),
  'pc': _c('Pancadas de chuva', _pancadas),
  'pn': _c('Parcialmente nublado', _solComNuvens),
  'cv': _c('Chuvisco', _chuvisco),
  'ch': _c('Chuvoso', _chuva),
  't': _c('Tempestade', _tempestade),
  'ps': _c('Predomínio de sol', _sol),
  'e': _c('Encoberto', _encoberto),
  'n': _c('Nublado', _nublado),
  'cl': _c('Céu claro', _sol),
  'nv': _c('Nevoeiro', _nevoeiro),
  'g': _c('Geada', _frio),
  'ne': _c('Neve', _frio),
  'nd': _c('Não definido', _indefinido),
  'pnt': _c('Pancadas de chuva à noite', _pancadas),
  'psc': _c('Possibilidade de chuva', _possivelChuva),
  'pcm': _c('Possibilidade de chuva pela manhã', _possivelChuva),
  'pct': _c('Possibilidade de chuva à tarde', _possivelChuva),
  'pcn': _c('Possibilidade de chuva à noite', _possivelChuva),
  'npt': _c('Nublado com pancadas à tarde', _pancadas),
  'npn': _c('Nublado com pancadas à noite', _pancadas),
  'ncn': _c('Nublado com possibilidade de chuva à noite', _possivelChuva),
  'nct': _c('Nublado com possibilidade de chuva à tarde', _possivelChuva),
  'ncm': _c('Nublado com possibilidade de chuva pela manhã', _possivelChuva),
  'npm': _c('Nublado com pancadas pela manhã', _pancadas),
  'npp': _c('Nublado com possibilidade de chuva', _possivelChuva),
  'vn': _c('Variação de nebulosidade', _solComNuvens),
  'ct': _c('Chuva à tarde', _chuva),
  'ppn': _c('Possibilidade de pancadas de chuva à noite', _possivelChuva),
  'ppt': _c('Possibilidade de pancadas de chuva à tarde', _possivelChuva),
  'ppm': _c('Possibilidade de pancadas de chuva pela manhã', _possivelChuva),
};

/// Converte a sigla recebida do serviço em uma descrição compreensível.
/// Nunca lança exceção: siglas ausentes ou desconhecidas têm um texto padrão.
CondicaoTempo condicaoPorSigla(String? sigla) {
  if (sigla == null || sigla.trim().isEmpty) {
    return _c('Condição não informada', _indefinido);
  }
  final chave = sigla.trim().toLowerCase();
  return condicoesTempo[chave] ??
      _c('Condição desconhecida ($chave)', _indefinido);
}

/// Classificação do índice ultravioleta (escala da OMS).
class FaixaUv {
  final String rotulo;
  final Color cor;

  const FaixaUv(this.rotulo, this.cor);
}

FaixaUv? faixaUv(double? iuv) {
  if (iuv == null) return null;
  if (iuv < 3) return const FaixaUv('Baixo', Color(0xFF43A047));
  if (iuv < 6) return const FaixaUv('Moderado', Color(0xFFF9A825));
  if (iuv < 8) return const FaixaUv('Alto', Color(0xFFEF6C00));
  if (iuv < 11) return const FaixaUv('Muito alto', Color(0xFFD32F2F));
  return const FaixaUv('Extremo', Color(0xFF7B1FA2));
}
