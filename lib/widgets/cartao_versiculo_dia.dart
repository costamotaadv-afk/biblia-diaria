import 'package:flutter/material.dart';

import '../tema.dart';

/// Cartão imersivo do "Versículo do Dia" na aba Início.
///
/// Componente puramente apresentacional (constituição, princípio I): recebe o
/// texto e os callbacks, sem regra de negócio. As ações grandes ficam na base
/// com ícone + rótulo, eliminando adivinhação para usuários idosos.
class CartaoVersiculoDia extends StatelessWidget {
  final String versiculo;
  final String referencia;
  final bool isFavorito;
  final bool ttsDisponivel;
  final VoidCallback? onOuvir;
  final VoidCallback? onFavoritar;
  final void Function(BuildContext contexto)? onCompartilhar;

  const CartaoVersiculoDia({
    super.key,
    required this.versiculo,
    required this.referencia,
    required this.isFavorito,
    required this.ttsDisponivel,
    this.onOuvir,
    this.onFavoritar,
    this.onCompartilhar,
  });

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Versículo do Dia. $versiculo. $referencia',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [esquema.primaryContainer, esquema.secondaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: esquema.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -16,
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 150,
                  color: esquema.onPrimaryContainer.withValues(alpha: 0.07),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_stories_rounded,
                          size: 26,
                          color: esquema.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'VERSÍCULO DO DIA',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: esquema.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '“$versiculo”',
                      style: const TextStyle(
                        fontFamily: fonteSerifada,
                        fontFamilyFallback: ['Georgia', 'Noto Serif', 'serif'],
                        fontSize: 19.5,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ).copyWith(color: esquema.onSurface),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        referencia,
                        style: estiloReferencia.copyWith(color: esquema.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AcaoDoCard(
                            icon: Icons.volume_up_rounded,
                            label: 'Ouvir',
                            cor: esquema.primary,
                            onTap: (ttsDisponivel && onOuvir != null)
                                ? onOuvir
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AcaoDoCard(
                            icon: isFavorito
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            label: isFavorito ? 'Salvo' : 'Favoritar',
                            cor: isFavorito
                                ? esquema.secondary
                                : esquema.onSurfaceVariant,
                            onTap: onFavoritar,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Builder(
                            builder: (ctx) => _AcaoDoCard(
                              icon: Icons.share_rounded,
                              label: 'Compartilhar',
                              cor: esquema.onSurfaceVariant,
                              onTap: onCompartilhar == null
                                  ? null
                                  : () => onCompartilhar!(ctx),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ação grande (ícone + rótulo) do cartão, com alvo de toque confortável.
class _AcaoDoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color cor;
  final VoidCallback? onTap;

  const _AcaoDoCard({
    required this.icon,
    required this.label,
    required this.cor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(72, 60),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor:
            onTap == null ? Theme.of(context).disabledColor : cor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
