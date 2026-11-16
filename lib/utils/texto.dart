const _comAcento = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñÝýÿ';
const _semAcento = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNnYyy';

String removerAcentos(String texto) {
  final buffer = StringBuffer();
  for (final caractere in texto.split('')) {
    final indice = _comAcento.indexOf(caractere);
    buffer.write(indice >= 0 ? _semAcento[indice] : caractere);
  }
  return buffer.toString();
}

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

String formatarData(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}/${data.year}';

String formatarDiaMes(DateTime data) =>
    '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}';

String formatarDataHora(DateTime data) =>
    '${formatarData(data)} às ${_doisDigitos(data.hour)}:${_doisDigitos(data.minute)}';

const _diasSemana = [
  'Segunda-feira',
  'Terça-feira',
  'Quarta-feira',
  'Quinta-feira',
  'Sexta-feira',
  'Sábado',
  'Domingo',
];

String diaDaSemana(DateTime data) => _diasSemana[data.weekday - 1];

String diaDaSemanaAbreviado(DateTime data) =>
    diaDaSemana(data).substring(0, 3);

String rotuloDia(DateTime data, {DateTime? agora}) {
  final hoje = DateUtilsSimples.somenteData(agora ?? DateTime.now());
  final dia = DateUtilsSimples.somenteData(data);
  final diferenca = dia.difference(hoje).inDays;
  if (diferenca == 0) return 'Hoje';
  if (diferenca == 1) return 'Amanhã';
  return diaDaSemana(data);
}

class DateUtilsSimples {
  DateUtilsSimples._();

  static DateTime somenteData(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);
}
