import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// O `share_plus` oferece folha de compartilhamento nativa em Android, iOS,
/// macOS, Windows e web (Web Share API). Fica indisponível apenas no Linux,
/// que não tem folha nativa — nesse caso a UI cai no fallback de clipboard.
bool get suportaCompartilhamentoNativo {
  if (kIsWeb) return true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return true;
    default:
      return false;
  }
}

/// Abre a folha de compartilhamento nativa com [texto].
///
/// Nunca lança: retorna `false` quando o plugin falha ou está indisponível,
/// para que a UI caia no fallback de clipboard (degradação graciosa — caso
/// SH2 da matriz de QA). `dismissed` (usuário fechou a folha) conta como
/// tratado, para não copiar texto sem necessidade.
Future<bool> compartilharTexto(String texto, {Rect? origem}) async {
  if (!suportaCompartilhamentoNativo) return false;
  try {
    final resultado = await SharePlus.instance.share(
      ShareParams(text: texto, sharePositionOrigin: origem),
    );
    return resultado.status != ShareResultStatus.unavailable;
  } catch (_) {
    return false;
  }
}
