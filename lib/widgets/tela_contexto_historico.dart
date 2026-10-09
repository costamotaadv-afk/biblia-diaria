import 'package:flutter/material.dart';

import '../contexto_historico.dart';
import 'painel_contexto_historico.dart';

/// Tela dedicada de consulta/busca dos 150 contextos históricos dos Salmos
/// (especificação §4.6). Recebe a lista já carregada e callbacks; a própria
/// tela abre o painel via bottom sheet. Sem regra de negócio.
class TelaContextoHistorico extends StatefulWidget {
  final List<ContextoSalmo> contextos;
  final bool ttsDisponivel;
  final void Function(ContextoSalmo contexto)? onOuvir;
  final void Function(String referencia) onNavegarReferencia;

  const TelaContextoHistorico({
    super.key,
    required this.contextos,
    required this.onNavegarReferencia,
    this.onOuvir,
    this.ttsDisponivel = false,
  });

  @override
  State<TelaContextoHistorico> createState() => _TelaContextoHistoricoState();
}

class _TelaContextoHistoricoState extends State<TelaContextoHistorico> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final filtrados = filtrarContextoPorBusca(widget.contextos, _busca);

    return Scaffold(
      appBar: AppBar(title: const Text('Contexto histórico dos Salmos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por personagem, evento, lugar ou período',
                border: OutlineInputBorder(),
              ),
              onChanged: (valor) => setState(() => _busca = valor),
            ),
          ),
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum Salmo encontrado com essa busca.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: filtrados.length,
                    itemBuilder: (context, i) {
                      final contexto = filtrados[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.history_edu,
                              color: Colors.indigo),
                          title: Text(
                            contexto.titulo.isEmpty
                                ? 'Salmo ${contexto.numero}'
                                : 'Salmo ${contexto.numero} — ${contexto.titulo}',
                          ),
                          subtitle: Text(
                            [
                              if (contexto.temAutoria) contexto.autoria,
                              if (contexto.temPeriodo) contexto.periodo,
                            ].join(' • '),
                          ),
                          onTap: () => _abrir(contexto),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrir(ContextoSalmo contexto) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: PainelContextoHistorico(
                contexto: contexto,
                ttsDisponivel: widget.ttsDisponivel,
                onOuvir: widget.onOuvir,
                onNavegarReferencia: widget.onNavegarReferencia,
              ),
            ),
          ),
        );
      },
    );
  }
}
