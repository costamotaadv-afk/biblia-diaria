import 'package:flutter/material.dart';

import '../contexto_historico.dart';

/// Painel reutilizável que exibe a contextualização histórica completa de um
/// Salmo: identificação, autoria, período, contexto político, acontecimentos,
/// localização, referências cruzadas (navegáveis), grau de certeza, explicação
/// e fontes. Sem regra de negócio; legível em 320 px × fonte 1.18.
class PainelContextoHistorico extends StatelessWidget {
  final ContextoSalmo contexto;
  final bool ttsDisponivel;
  final void Function(ContextoSalmo contexto)? onOuvir;
  final void Function(String referencia) onNavegarReferencia;

  const PainelContextoHistorico({
    super.key,
    required this.contexto,
    required this.onNavegarReferencia,
    this.onOuvir,
    this.ttsDisponivel = false,
  });

  @override
  Widget build(BuildContext context) {
    final podeOuvir =
        ttsDisponivel && contexto.temExplicacao && onOuvir != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Salmo ${contexto.numero}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (contexto.temTitulo) ...[
          const SizedBox(height: 2),
          Text(
            contexto.titulo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
        if (contexto.temClassificacao) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final classe in contexto.classificacao)
                Chip(
                  label: Text(classe),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        _seloCerteza(context),
        _secao(context, 'Autoria', _blocoAutoria(context)),
        if (contexto.temPeriodo ||
            contexto.temPeriodoRetratado ||
            contexto.temPeriodoComposicao)
          _secao(context, 'Período histórico', _blocoPeriodo(context)),
        if (contexto.temContextoPolitico)
          _secao(
            context,
            'Contexto político e social',
            Text(
              contexto.contextoPolitico,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        if (contexto.temEventos)
          _secao(
            context,
            'Acontecimentos históricos relacionados',
            _blocoTopicos(contexto.eventos),
          ),
        if (contexto.temLocalizacao)
          _secao(
            context,
            'Localização geográfica',
            Text(
              contexto.localizacao,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        if (contexto.temReferencias)
          _secao(
            context,
            'Referências bíblicas cruzadas',
            _blocoReferencias(context),
          ),
        if (contexto.temExplicacao)
          _secao(
            context,
            'Contextualização histórica',
            Text(
              contexto.explicacao,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        if (contexto.temFontes)
          _secao(context, 'Fontes', _blocoFontes(context)),
        if (podeOuvir) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onOuvir!(contexto),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Ouvir contexto'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ],
    );
  }

  Widget _secao(BuildContext context, String titulo, Widget conteudo) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          conteudo,
        ],
      ),
    );
  }

  Widget _seloCerteza(BuildContext context) {
    final cor = switch (contexto.certeza) {
      CertezaHistorica.documentado => Colors.green,
      CertezaHistorica.tradicional => const Color(0xFF7A5C00),
      CertezaHistorica.hipotese => const Color(0xFF3F51B5),
      CertezaHistorica.indeterminado => Colors.grey,
    };
    final icone = switch (contexto.certeza) {
      CertezaHistorica.documentado => Icons.menu_book,
      CertezaHistorica.tradicional => Icons.people_outline,
      CertezaHistorica.hipotese => Icons.science_outlined,
      CertezaHistorica.indeterminado => Icons.help_outline,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 20, color: cor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grau de certeza: ${rotuloCerteza(contexto.certeza)}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: cor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            explicacaoCerteza(contexto.certeza),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _blocoAutoria(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contexto.autoria.isEmpty ? 'Autoria desconhecida' : contexto.autoria,
          style: const TextStyle(
              fontSize: 16, height: 1.5, fontWeight: FontWeight.w600),
        ),
        if (contexto.temOrigemAutoria) ...[
          const SizedBox(height: 2),
          Text(
            'Origem da atribuição: ${contexto.origemAutoria}',
            style: const TextStyle(fontSize: 15, height: 1.45),
          ),
        ],
        if (contexto.autoriaIncerta) ...[
          const SizedBox(height: 4),
          Text(
            contexto.autoria.isEmpty
                ? 'Não há elementos suficientes para identificar o autor com segurança.'
                : 'Observação: a atribuição é tradicional e não possui comprovação histórica independente conclusiva.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _blocoPeriodo(BuildContext context) {
    final linhas = <Widget>[];
    if (contexto.temPeriodo) {
      linhas.add(_linhaPeriodo('Período associado', contexto.periodo));
    }
    if (contexto.temPeriodoRetratado) {
      linhas.add(
          _linhaPeriodo('Época retratada no texto', contexto.periodoRetratado));
    }
    if (contexto.temPeriodoComposicao) {
      linhas.add(_linhaPeriodo(
          'Provável época de composição', contexto.periodoComposicao));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: linhas,
    );
  }

  Widget _linhaPeriodo(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$rotulo: $valor',
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }

  Widget _blocoTopicos(List<String> topicos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final topico in topicos)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•', style: TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    topico,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _blocoReferencias(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ref in contexto.referenciasCruzadas)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onNavegarReferencia(ref.referencia),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref.referencia,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (ref.temNota)
                          Text(
                            ref.nota,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new, size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _blocoFontes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final fonte in contexto.fontes)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              fonte.credito.isEmpty ? 'Fonte não identificada.' : fonte.credito,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}


