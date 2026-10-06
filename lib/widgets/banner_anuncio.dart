import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config.dart';
import '../platform_support.dart';

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
  static const String _bannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _bannerIos = 'ca-app-pub-3940256099942544/2934735716';

  BannerAd? _bannerAd;
  bool _carregado = false;
  int? _larguraSolicitada;

  String get _bannerAdUnitId {
    final id = defaultTargetPlatform == TargetPlatform.iOS
        ? _bannerIos
        : _bannerAndroid;
    // Caso B8 da matriz: em release, o ID de TESTE do Google não pode ir para
    // produção (viola política do AdMob e zera a receita). O assert falha em
    // debug; a função pura também é coberta por teste unitário.
    final erro = erroIdAnuncioEmProducao(isRelease: kReleaseMode, id: id);
    assert(
        erro == null,
        'ID de anúncio de TESTE do Google em release: '
        'troque pelo ID real antes de publicar.');
    return id;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!suportaAdMob) return;

    // O banner está dentro do padding horizontal de 20 px da tela inicial.
    final largura = (MediaQuery.sizeOf(context).width - 40).floor();
    if (largura > 0 && largura != _larguraSolicitada) {
      _larguraSolicitada = largura;
      _carregarBanner(largura);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _carregarBanner(int largura) async {
    AdSize? tamanho;
    try {
      tamanho = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        largura,
      );
    } on MissingPluginException {
      // Mantém o app funcional se o SDK não estiver registrado no ambiente.
      return;
    }
    if (!mounted || tamanho == null || largura != _larguraSolicitada) return;

    await _bannerAd?.dispose();
    _bannerAd = null;
    _carregado = false;

    final banner = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: tamanho,
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
    try {
      await banner.load();
    } catch (_) {
      // Falha ao carregar o anúncio (rede indisponível, dispositivo sem
      // Google Play Services, etc.): mantém o app funcionando sem banner,
      // sem exceção não tratada (caso C9 da matriz de QA).
      banner.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (!_carregado || ad == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
