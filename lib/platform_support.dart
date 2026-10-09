import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// O SDK Google Mobile Ads só oferece implementação para Android e iOS.
bool get suportaAdMob {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// O flutter_tts possui implementação para web (via `speechSynthesis` do
/// navegador), Android, iOS, macOS e Windows. Fica indisponível apenas no
/// Linux, que não tem implementação nativa.
bool get suportaTts {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}

/// Inicializa o AdMob com degradação graciosa: se o SDK não estiver
/// disponível (ex.: dispositivo sem Google Play Services) ou o App ID
/// estiver ausente, o app segue abrindo normalmente, apenas sem anúncios.
///
/// Nunca lança exceção para o chamador.
Future<void> inicializarAdMob() async {
  if (!suportaAdMob) return;
  try {
    await MobileAds.instance.initialize();
  } catch (_) {
    // Sem anúncios nesta sessão; o restante do app não é afetado.
  }
}
