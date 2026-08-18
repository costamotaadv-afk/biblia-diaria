import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Banner de anúncio do AdMob.
///
/// IMPORTANTE (Etapa 2):
/// Os IDs abaixo são os IDENTIFICADORES DE TESTE padrão do Google.
/// Eles exibem anúncios de teste apenas em dispositivos configurados como
/// "dispositivo de teste". Antes de publicar, troque-os pelos IDs reais
/// da sua conta do AdMob.
class BannerAnuncio extends StatefulWidget {
  const BannerAnuncio({super.key});

  @override
  State<BannerAnuncio> createState() => _BannerAnuncioState();
}

class _BannerAnuncioState extends State<BannerAnuncio> {
  /// ID do bloco de anúncio de TESTE do Google (banner).
  ///
  /// TROQUE este valor pelo ID real do seu bloco de banner no AdMob antes
  /// de publicar. Formato: ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  BannerAd? _bannerAd;
  bool _carregado = false;

  @override
  void initState() {
    super.initState();
    _carregarBanner();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _carregarBanner() {
    final ancoragem = AdSize(
      width: MediaQuery.of(context).size.width.round(),
      height: 60,
    );

    final banner = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: ancoragem,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
            _carregado = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
        onAdImpression: (ad) {},
        onAdClicked: (ad) {},
      ),
    );
    banner.load();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_carregado || ad == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      child: AdWidget(ad: ad),
    );
  }
}

