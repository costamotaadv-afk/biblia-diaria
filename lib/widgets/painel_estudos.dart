import 'package:flutter/material.dart';

import '../catalogo_estudos.dart';

/// Painel reutilizável que exibe os recursos de estudo de um trecho (ou da
/// biblioteca "Estudos").
///
/// Não contém regra de negócio: recebe a lista já pronta e callbacks. É usado
/// em dois pontos — no bottom sheet da leitura e na seção "Estudos" — evitando
/// duplicar a apresentação (constituição, princípio I).
class PainelEstudos extends StatelessWidget {
  /// Recursos já filtrados para o contexto em que o painel é exibido.
  final List<RecursoEstudo> recursos;

  /// Ids de recursos já salvos (para o estado do botão).
  final Set<String> favoritos;

  /// Chamado ao tocar em "Salvar"/"Salvo".
  final void Function(RecursoEstudo recurso) onAlternarFavorito;

  /// Chamado ao tocar em "Ouvir"; `null` desabilita a ação.
  final void Function(RecursoEstudo recurso)? onOuvir;

  /// Se o TTS está disponível nesta plataforma/dispositivo.
  final bool ttsDisponivel;

  const PainelEstudos({
    super.key,
    required this.recursos,
    required this.favoritos,
    required this.onAlternarFavorito,
    this.onOuvir,
    this.ttsDisponivel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (recursos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Sem recursos de estudo para este trecho.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final grupos = agruparPorTipo(recursos);
    final blocos = <Widget>[];
    grupos.forEach((tipo, lista) {
      blocos.add(_cabecalhoTipo(context, tipo));
      for (final recurso in lista) {
        blocos.add(_cartaoRecurso(context, recurso));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocos,
    );
  }

  Widget _cabecalhoTipo(BuildContext context, String tipo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        rotuloTipo(tipo),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _cartaoRecurso(BuildContext context, RecursoEstudo recurso) {
    final salvo = favoritos.contains(recurso.id);
    final credito = recurso.temFonte ? recurso.fonte!.credito : '';
    final titulo =
        recurso.titulo.isEmpty ? rotuloTipo(recurso.tipo) : recurso.titulo;
    final podeOuvir = ttsDisponivel && recurso.temCorpo && onOuvir != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        child: Semantics(
          container: true,
          label: '$titulo. ${rotuloTipo(recurso.tipo)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (recurso.referencia.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  recurso.referencia,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                recurso.temCorpo ? recurso.corpo : 'Conteúdo não disponível.',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              if (credito.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Fonte: $credito',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 4),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: podeOuvir ? () => onOuvir!(recurso) : null,
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('Ouvir'),
                  ),
                  TextButton.icon(
                    onPressed: () => onAlternarFavorito(recurso),
                    icon: Icon(salvo ? Icons.bookmark : Icons.bookmark_border),
                    label: Text(salvo ? 'Salvo' : 'Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
