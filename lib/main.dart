import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cache_estudos.dart';
import 'cache_livros.dart';
import 'catalogo_estudos.dart';
import 'config.dart';
import 'dados_seguros.dart';
import 'leitura_natural.dart';
import 'platform_support.dart';
import 'widgets/banner_anuncio.dart';
import 'widgets/painel_estudos.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  // O plugin não possui implementação para web ou desktop. A inicialização
  // engole erros (sem Google Play Services etc.) para nunca impedir o app.
  await inicializarAdMob();
  runApp(const BibliaApp());
}

class VozTts {
  final String id;
  final String name;
  final String locale;
  final String gender;

  const VozTts({
    required this.id,
    required this.name,
    required this.locale,
    required this.gender,
  });

  String get label {
    final generoLegivel = gender.contains('male')
        ? 'Masculina'
        : gender.contains('female')
            ? 'Feminina'
            : 'Neutra';
    return '$name ($locale, $generoLegivel)';
  }
}

class BibliaApp extends StatefulWidget {
  /// Relógio injetável para testes de virada de dia (caso B4 de QA).
  final DateTime Function()? relogio;

  const BibliaApp({super.key, this.relogio});

  @override
  State<BibliaApp> createState() => _BibliaAppState();
}

class _BibliaAppState extends State<BibliaApp> {
  bool temaEscuro = false;
  bool fonteGrande = true;

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  Future<void> _carregarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      temaEscuro = prefs.getBool('tema_escuro') ?? false;
      fonteGrande = prefs.getBool('fonte_grande') ?? true;
    });
  }

  Future<void> _atualizarTema(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => temaEscuro = valor);
    await prefs.setBool('tema_escuro', valor);
  }

  Future<void> _atualizarFonteGrande(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => fonteGrande = valor);
    await prefs.setBool('fonte_grande', valor);
  }

  /// Cor de destaque (dourado suave, remete a enfeite/borda de Bíblia).
  static const Color _dourado = Color(0xFFB49A00);

  /// Monta o tema (claro ou escuro) com uma paleta coerente, pensada para
  /// boa legibilidade de pessoas idosas: contraste alto e destaques quentes.
  ThemeData _construirTema(Brightness brightness) {
    final esquema = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F51B5), // índigo
      brightness: brightness,
      secondary: _dourado,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      brightness: brightness,
    );

    // Ajustes de tipografia para legibilidade em telas de celular.
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bíblia Diária',
      debugShowCheckedModeBanner: false,
      themeMode: temaEscuro ? ThemeMode.dark : ThemeMode.light,
      theme: _construirTema(Brightness.light),
      darkTheme: _construirTema(Brightness.dark),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final escala = fonteGrande ? 1.18 : 1.0;
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(escala)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: TelaPrincipal(
        relogio: widget.relogio,
        temaEscuro: temaEscuro,
        onToggleTema: _atualizarTema,
        fonteGrande: fonteGrande,
        onToggleFonteGrande: _atualizarFonteGrande,
      ),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  /// Relógio injetável para testes de virada de dia (caso B4 de QA).
  final DateTime Function()? relogio;
  final bool temaEscuro;
  final ValueChanged<bool> onToggleTema;
  final bool fonteGrande;
  final ValueChanged<bool> onToggleFonteGrande;

  const TelaPrincipal({
    super.key,
    this.relogio,
    required this.temaEscuro,
    required this.onToggleTema,
    required this.fonteGrande,
    required this.onToggleFonteGrande,
  });

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int aba = 0;
  // Carregamento sob demanda: índice leve + mensagens, e cada livro só quando
  // o usuário o abre. Evita baixar os ~13MB todos de uma vez (crítico na web).
  List<Map<String, dynamic>> _indice = [];
  List<String> _mensagens = [];
  late final CacheDeLivros _cacheLivros;
  late final CacheDeEstudos _cacheEstudos;
  bool _carregamentoInicial = true;
  Set<String> favoritosVersiculos = {};
  Set<String> favoritosCapitulos = {};
  Set<String> favoritosEstudos = {};
  List<RecursoEstudo> _indiceEstudos = [];
  // Estado de expansão da aba Bíblia. Um livro expandido vira linhas planas e
  // LAZY no ListView (capítulos/versículos só montam quando visíveis), em vez
  // de uma Column com todos os versículos de uma vez — o custo de CPU/memória
  // que o caso C6 da matriz expunha (Salmos chegava a ~2.400 ListTiles em um
  // único frame).
  final Set<String> _livrosExpandidos = {};
  final Map<String, List<dynamic>> _capitulosPorLivro = {};
  final Set<String> _livrosComErro = {};
  String? _tipoFiltroEstudos;
  String _livroFiltroEstudos = '';
  String _buscaEstudos = '';
  final FlutterTts _tts = FlutterTts();
  bool _falando = false;
  bool _pausado = false;
  bool _leituraAtiva = false;
  String? _textoLeituraAtual;
  // Fila de segmentos pendentes de fala (capítulos gigantes, E12). O completion
  // handler consome um por vez para o engine nunca truncar silenciosamente.
  final List<String> _filaFala = [];
  List<VozTts> _vozesDisponiveis = [];
  String? _vozSelecionadaId;
  String? _vozMasculinaId;
  String? _vozFemininaId;

  /// Sinaliza se o TTS está de fato disponível nesta plataforma/dispositivo.
  /// Começa otimista pelo suporte de plataforma e vira `false` se a
  /// configuração falhar (ex.: plugin ausente na web).
  bool _ttsDisponivel = suportaTts;

  // Filas de escrita serializadas: garantem que escritas concorrentes de
  // favoritos no SharedPreferences respeitem a ordem (last-write-wins),
  // evitando race entre memória e disco (caso C4 da matriz de QA).
  Future<void> _escritaFavVersiculos = Future<void>.value();
  Future<void> _escritaFavCapitulos = Future<void>.value();
  Future<void> _escritaFavEstudos = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _cacheLivros = CacheDeLivros(carregador: _carregarLivroMap);
    _cacheEstudos = CacheDeEstudos(carregador: _carregarEstudosLivro);
    _carregar();
    _configurarTts();
  }

  @override
  void dispose() {
    // Em plataformas sem plugin (web), o stop lançaria exceção assíncrona;
    // o catchError evita erro não tratado (caso C11 da matriz de QA).
    _tts.stop().catchError((Object _) {});
    super.dispose();
  }

  /// Data/hora atual; injetável via [TelaPrincipal.relogio] para testar a
  /// virada do dia com o app aberto (caso B4 da matriz de QA).
  DateTime get _agora => (widget.relogio ?? DateTime.now)();

  /// Carrega somente o essencial na abertura (índice leve, mensagens) e o
  /// livro escolhido para o versículo do dia. Os demais livros são carregados
  /// sob demanda ao navegar.
  Future<void> _carregar() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    List<Map<String, dynamic>> indice = [];
    try {
      final indiceJson = await rootBundle.loadString('assets/data/indice.json');
      indice = (comoLista(json.decode(indiceJson)) ?? const <dynamic>[])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    } catch (_) {
      indice = [];
    }

    List<String> mensagens = [];
    try {
      final msgJson = await rootBundle.loadString('assets/data/mensagens.json');
      mensagens = normalizarMensagens(json.decode(msgJson));
    } catch (_) {
      mensagens = [];
    }

    List<RecursoEstudo> indiceEstudos = [];
    try {
      final estudosJson =
          await rootBundle.loadString('assets/data/estudos_indice.json');
      indiceEstudos = recursosDeJson(json.decode(estudosJson));
    } catch (_) {
      indiceEstudos = [];
    }

    // Distribui o conteúdo diário pelos 66 livros sem carregar a Bíblia inteira.
    final diasDecorridos = diasDesdeEpoca(_agora);
    final nomeLivroDoDia = indice.isEmpty
        ? null
        : '${indice[diasDecorridos % indice.length]['nome']}';
    final livroDoDia =
        nomeLivroDoDia == null ? null : await _carregarLivroMap(nomeLivroDoDia);

    if (!mounted) return;
    setState(() {
      _indice = indice;
      _mensagens = mensagens;
      if (livroDoDia != null) {
        _cacheLivros.cache['${livroDoDia['nome']}'] = livroDoDia;
      }
      favoritosVersiculos =
          (prefs.getStringList('favoritos_versiculos') ?? []).toSet();
      favoritosCapitulos =
          (prefs.getStringList('favoritos_capitulos') ?? []).toSet();
      favoritosEstudos =
          (prefs.getStringList('favoritos_estudos') ?? []).toSet();
      _indiceEstudos = indiceEstudos;
      _carregamentoInicial = false;
    });
  }

  /// Lê o JSON de um livro da pasta assets/data/livros/<nome>.json.
  Future<Map<String, dynamic>?> _carregarLivroMap(String nomeLivro) async {
    if (_cacheLivros.cache.containsKey(nomeLivro)) {
      return _cacheLivros.cache[nomeLivro];
    }
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/livros/$nomeLivro.json');
      final decodificado = json.decode(jsonStr);
      if (decodificado is! Map) return null;
      return Map<String, dynamic>.from(decodificado);
    } catch (_) {
      return null;
    }
  }

  /// Lê os recursos de estudo de um livro (assets/data/estudos/<nome>.json).
  /// Livro sem arquivo → lista vazia (cacheada, para não repetir a leitura);
  /// nunca lança (caso EST1 da matriz de QA).
  Future<List<RecursoEstudo>?> _carregarEstudosLivro(String livro) async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/estudos/$livro.json');
      return recursosDeJson(json.decode(jsonStr));
    } catch (_) {
      return const <RecursoEstudo>[];
    }
  }

  /// True se há recurso de estudo aplicável a [referencia] naquele [livro].
  bool _temEstudos(String referencia, String livro) {
    if (_indiceEstudos.isEmpty) return false;
    for (final recurso in _indiceEstudos) {
      if (recurso.livro != livro) continue;
      if (recursoAplicavel(recurso, referencia, livro: livro)) return true;
    }
    return false;
  }

  /// Recursos aplicáveis a uma referência, carregando o detalhe do livro sob
  /// demanda (com cache/retry — mesmo padrão de _assegurarLivro).
  Future<List<RecursoEstudo>> _recursosDe(
    String referencia,
    String livro,
  ) async {
    if (!_temEstudos(referencia, livro)) return const <RecursoEstudo>[];
    final lista = await _cacheEstudos.assegurar(livro);
    if (lista == null) return const <RecursoEstudo>[];
    return recursosAplicaveis(
      lista.where((r) => r.livro == livro),
      referencia,
      livro: livro,
    );
  }

  Future<void> _abrirEstudosDaReferencia(
    String referencia,
    String livro,
  ) async {
    final recursos = await _recursosDe(referencia, livro);
    if (!mounted) return;
    await _mostrarPainelEstudos(recursos, titulo: referencia);
  }

  Future<void> _abrirRecursoEstudo(RecursoEstudo resumo) async {
    var recurso = resumo;
    final lista = await _cacheEstudos.assegurar(resumo.livro);
    if (lista != null) {
      for (final item in lista) {
        if (item.id == resumo.id) {
          recurso = item;
          break;
        }
      }
    }
    if (!mounted) return;
    final titulo = recurso.titulo.isEmpty
        ? (resumo.referencia.isEmpty
            ? rotuloTipo(recurso.tipo)
            : resumo.referencia)
        : recurso.titulo;
    await _mostrarPainelEstudos([recurso], titulo: titulo);
  }

  Future<void> _mostrarPainelEstudos(
    List<RecursoEstudo> recursos, {
    required String titulo,
  }) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        titulo,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      PainelEstudos(
                        recursos: recursos,
                        favoritos: favoritosEstudos,
                        ttsDisponivel: _ttsDisponivel,
                        onOuvir: _falarRecurso,
                        onAlternarFavorito: (recurso) async {
                          await _toggleFavoritoEstudo(recurso.id);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _falarRecurso(RecursoEstudo recurso) async {
    final titulo =
        recurso.titulo.isEmpty ? rotuloTipo(recurso.tipo) : recurso.titulo;
    final corpo = textoParaLeituraNatural(recurso.corpo);
    await _iniciarLeitura('$titulo. $corpo');
  }

  Future<void> _toggleFavoritoEstudo(String id) async {
    if (!mounted) return;
    setState(() {
      if (!favoritosEstudos.remove(id)) {
        favoritosEstudos.add(id);
      }
    });
    await _persistirFavoritosEstudos();
  }

  Future<void> _persistirFavoritosEstudos() {
    final snapshot = favoritosEstudos.toList();
    _escritaFavEstudos = _escritaFavEstudos.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favoritos_estudos', snapshot);
    });
    return _escritaFavEstudos;
  }

  /// Garante que o livro está no cache; se não, busca e guarda. É chamado
  /// antes de montar/blindar qualquer tela que precise do conteúdo do livro.
  /// Garante que o livro está no cache; se não, busca e guarda (com retry em
  /// falha transiente — caso C5 da matriz de QA).
  Future<Map<String, dynamic>?> _assegurarLivro(String nomeLivro) {
    return _cacheLivros.assegurar(nomeLivro);
  }

  /// Expande/recolhe um livro na aba Bíblia, carregando os capítulos sob
  /// demanda (uma única vez, cacheado via [_assegurarLivro]). O conteúdo é
  /// mantido como linhas planas e LAZY no ListView (ver [_montarTelaLeitura]).
  Future<void> _alternarLivro(String nomeLivro) async {
    if (_livrosExpandidos.remove(nomeLivro)) {
      setState(() {});
      return;
    }
    setState(() => _livrosExpandidos.add(nomeLivro));
    if (_capitulosPorLivro.containsKey(nomeLivro) ||
        _livrosComErro.contains(nomeLivro)) {
      return;
    }
    final livro = await _assegurarLivro(nomeLivro);
    if (!mounted) return;
    setState(() {
      if (livro == null) {
        _livrosComErro.add(nomeLivro);
      } else {
        _capitulosPorLivro[nomeLivro] =
            comoLista(livro['capitulos']) ?? const [];
      }
    });
  }

  Future<void> _configurarTts() async {
    // Em plataformas sem plugin (web, Linux) o TTS não existe: desabilita a
    // feature e evita MissingPluginException (caso C11 da matriz de QA).
    if (!suportaTts) {
      if (mounted) {
        setState(() => _ttsDisponivel = false);
      }
      return;
    }
    try {
      await _configurarTtsInterno();
    } catch (_) {
      // Falha ao configurar o TTS (engine ausente, permissões, etc.): o app
      // segue funcionando, apenas sem leitura em voz alta.
      if (mounted) {
        setState(() => _ttsDisponivel = false);
      }
    }
  }

  /// Velocidade da fala em voz alta.
  ///
  /// 1.0 é a velocidade normal do motor nativo (Google TTS no Android,
  /// AVSpeechSynthesizer no iOS). Para o público sênior (60+), reduzimos para
  /// 0.36 — dentro da faixa recomendada de 0.33 a 0.38 — o que torna a leitura
  /// bíblica bem mais lenta, pausada e fácil de acompanhar, sem soar robotizada.
  static const double _velocidadeFala = 0.36;

  /// Aplica os parâmetros de fala pensados para idosos: velocidade reduzida,
  /// volume máximo e tom neutro. É reaplicado após `setVoice` porque alguns
  /// motores resetam a velocidade ao trocar de voz.
  Future<void> _aplicarParametrosDeFala() async {
    await _tts.setSpeechRate(_velocidadeFala);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  Future<void> _configurarTtsInterno() async {
    // Usa o motor nativo do aparelho (sem custo e offline).
    await _tts.setLanguage('pt-BR');
    await _aplicarParametrosDeFala();

    final prefs = await SharedPreferences.getInstance();
    final vozSalva = prefs.getString('voz_tts_id');
    final voices = await _tts.getVoices;
    if (voices is List) {
      final vozes = <VozTts>[];

      for (final voiceRaw in voices) {
        if (voiceRaw is Map) {
          final locale = '${voiceRaw['locale'] ?? ''}';
          final localeLower = locale.toLowerCase();
          if (!localeLower.startsWith('pt')) {
            continue;
          }

          final name = '${voiceRaw['name'] ?? ''}'.trim();
          if (name.isEmpty) {
            continue;
          }

          final gender = '${voiceRaw['gender'] ?? ''}'.toLowerCase();
          final id = '$name|$locale';
          vozes.add(
            VozTts(
              id: id,
              name: name,
              locale: locale,
              gender: gender,
            ),
          );
        }
      }

      // Pontua cada voz: vozes neurais/naturais ficam no topo da lista,
      // evitando selecionar a voz padrão robotizada do dispositivo.
      int pontuacao(VozTts voz) {
        final nome = voz.name.toLowerCase();
        final loc = voz.locale.toLowerCase();
        var pts = 0;
        if (loc.contains('pt-br')) pts += 100;
        if (loc.contains('pt-pt')) pts += 60;
        // Marcadores comuns de vozes de alta qualidade (Google/Android).
        if (nome.contains('neural') || nome.contains('enhanced')) pts += 80;
        if (nome.contains('online') ||
            nome.contains('wavenet') ||
            nome.contains('high') ||
            nome.contains('quality') ||
            nome.contains('studio')) {
          pts += 50;
        }
        // Preferência por feminina na leitura da Bíblia (mais suave), mas não
        // obrigatório — o usuário pode trocar nos Ajustes.
        if (voz.gender.contains('female')) pts += 10;
        return pts;
      }

      vozes.sort((a, b) {
        final cmp = pontuacao(b).compareTo(pontuacao(a));
        if (cmp != 0) return cmp;
        return a.label.compareTo(b.label);
      });
      VozTts? escolhida;

      if (vozes.isNotEmpty) {
        if (vozSalva != null) {
          for (final voz in vozes) {
            if (voz.id == vozSalva) {
              escolhida = voz;
              break;
            }
          }
        }

        for (final voz in vozes) {
          if (voz.locale.toLowerCase().contains('pt-br') &&
              voz.gender.contains('male')) {
            _vozMasculinaId = voz.id;
            break;
          }
        }

        for (final voz in vozes) {
          if (voz.locale.toLowerCase().contains('pt-br') &&
              voz.gender.contains('female')) {
            _vozFemininaId = voz.id;
            break;
          }
        }

        escolhida ??= vozes.firstWhere(
          (voz) =>
              voz.locale.toLowerCase().contains('pt-br') &&
              voz.gender.contains('female'),
          orElse: () => vozes.firstWhere(
            (voz) =>
                voz.locale.toLowerCase().contains('pt-br') &&
                voz.gender.contains('male'),
            orElse: () => vozes.first,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _vozesDisponiveis = vozes;
          _vozSelecionadaId = escolhida?.id;
        });
      }

      if (escolhida != null) {
        await _tts.setVoice({
          'name': escolhida.name,
          'locale': escolhida.locale,
        });
        // Reaplica a velocidade/tom após trocar de voz (alguns motores resetam).
        await _aplicarParametrosDeFala();
        await prefs.setString('voz_tts_id', escolhida.id);
      }
    }

    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _falando = true;
        _pausado = false;
        _leituraAtiva = true;
      });
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      if (_filaFala.isNotEmpty) {
        // Pausa natural ("respiro") de 450 ms entre segmentos: dá tempo de
        // assimilação e evita o tom robótico. O próximo segmento só é falado se
        // a leitura continuar ativa (não pausada/parada) após o delay.
        Future<void>.delayed(const Duration(milliseconds: 450), () {
          if (!mounted || !_leituraAtiva || _pausado || _filaFala.isEmpty) {
            return;
          }
          final proximo = _filaFala.removeAt(0);
          _tts.speak(proximo).catchError((Object _) {
            if (mounted) {
              setState(() {
                _ttsDisponivel = false;
                _leituraAtiva = false;
                _filaFala.clear();
              });
            }
          });
        });
        return;
      }
      setState(() {
        _falando = false;
        _pausado = false;
        _leituraAtiva = false;
        _textoLeituraAtual = null;
      });
    });
    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() {
        _falando = false;
        _pausado = false;
        _leituraAtiva = false;
        _textoLeituraAtual = null;
      });
    });
    _tts.setPauseHandler(() {
      if (!mounted) return;
      setState(() {
        _falando = false;
        _pausado = true;
        _leituraAtiva = true;
      });
    });
    _tts.setContinueHandler(() {
      if (!mounted) return;
      setState(() {
        _falando = true;
        _pausado = false;
        _leituraAtiva = true;
      });
    });
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _selecionarVozPorId(String? vozId) async {
    if (vozId == null) return;
    VozTts? escolhida;
    for (final voz in _vozesDisponiveis) {
      if (voz.id == vozId) {
        escolhida = voz;
        break;
      }
    }
    if (escolhida == null) return;

    await _tts.setVoice({'name': escolhida.name, 'locale': escolhida.locale});
    // Reaplica a velocidade/tom após trocar de voz (alguns motores resetam).
    await _aplicarParametrosDeFala();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('voz_tts_id', escolhida.id);

    final idSelecionada = escolhida.id;
    if (mounted) {
      setState(() {
        _vozSelecionadaId = idSelecionada;
      });
    }
  }

  Future<void> _selecionarVozPorGenero(String genero) async {
    final alvo = genero == 'male' ? _vozMasculinaId : _vozFemininaId;
    if (alvo == null) return;
    await _selecionarVozPorId(alvo);
  }

  Future<void> _falarVersiculo(String referencia, String texto) async {
    // Garante que apenas este versículo específico será lido.
    // Não há reprodução continuada para o versículo seguinte de forma automática,
    // respeitando a autonomia e o ritmo de leitura do usuário.
    final refAjustada = referenciaParaLeitura(referencia);
    final textoAjustado = textoParaLeituraNatural(texto);
    await _iniciarLeitura('$refAjustada. $textoAjustado');
  }

  Future<void> _falarCapitulo(String chaveCapitulo) async {
    // Garante que apenas este capítulo específico será lido do início ao fim.
    // Ao terminar o último versículo deste capítulo, o som para completamente
    // e não avança de forma alguma para o capítulo seguinte de modo automático.
    final texto = _buscarTextoCapitulo(chaveCapitulo);
    if (texto == null || texto.trim().isEmpty) return;
    final refAjustada = referenciaParaLeitura(chaveCapitulo);
    await _iniciarLeitura('$refAjustada. $texto');
  }

  Future<void> _iniciarLeitura(String textoCompleto) async {
    final texto = textoCompleto.trim();
    if (texto.isEmpty) return;

    try {
      await _tts.stop();
    } catch (_) {
      if (mounted) setState(() => _ttsDisponivel = false);
      return;
    }
    if (!mounted) return;

    // Capítulos gigantes (E12) são divididos em segmentos curtos; o completion
    // handler consome a fila um por vez (fala sequencial, sem truncar).
    final segmentos = dividirTextoParaFala(texto);
    _filaFala
      ..clear()
      ..addAll(segmentos.skip(1));

    setState(() {
      _textoLeituraAtual = texto;
      _falando = false;
      _pausado = false;
      _leituraAtiva = true;
    });

    try {
      await _tts.speak(segmentos.first);
    } catch (_) {
      if (mounted) {
        setState(() {
          _ttsDisponivel = false;
          _leituraAtiva = false;
          _filaFala.clear();
        });
      }
    }
  }

  Future<void> _alternarPlayPause() async {
    if (!_leituraAtiva && !_falando && !_pausado) return;

    // Pausar leitura em andamento.
    if (_falando || (!_pausado && _leituraAtiva)) {
      try {
        await _tts.pause();
      } catch (_) {
        if (mounted) setState(() => _ttsDisponivel = false);
        return;
      }
      if (mounted) {
        setState(() {
          _falando = false;
          _pausado = true;
          _leituraAtiva = true;
        });
      }
      return;
    }

    // Continuar leitura pausada.
    if (_pausado) {
      try {
        await _tts.speak('');
      } catch (_) {
        // Falha de retomada (engine sem suporte a speak vazio): encerra o
        // trecho graciosamente, sem desabilitar o TTS para a sessão inteira
        // (caso C12 da matriz de QA).
        if (mounted) {
          setState(() {
            _falando = false;
            _pausado = false;
            _leituraAtiva = false;
            _textoLeituraAtual = null;
            _filaFala.clear();
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _falando = true;
          _pausado = false;
          _leituraAtiva = true;
        });
      }
      return;
    }

    // Se há texto pendente e o TTS foi interrompido, inicia leitura novamente.
    final texto = _textoLeituraAtual;
    if (texto == null || texto.isEmpty) return;
    try {
      await _tts.speak(texto);
    } catch (_) {
      if (mounted) setState(() => _ttsDisponivel = false);
      return;
    }
    if (mounted) {
      setState(() {
        _falando = true;
        _pausado = false;
        _leituraAtiva = true;
      });
    }
  }

  Widget _botaoPlayPause({bool compacto = false}) {
    final icone = (_falando && !_pausado)
        ? Icons.pause_rounded
        : Icons.play_arrow_rounded;
    final rotulo = (_falando && !_pausado) ? 'Pausar' : 'Continuar';

    if (compacto) {
      return IconButton.filled(
        tooltip: rotulo,
        onPressed: _leituraAtiva ? _alternarPlayPause : null,
        icon: Icon(icone, size: 28),
        style: IconButton.styleFrom(
          minimumSize: const Size(52, 52),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.all(10),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: _leituraAtiva ? _alternarPlayPause : null,
      icon: Icon(icone),
      label: Text(rotulo),
    );
  }

  Future<void> _toggleFavoritoVersiculo(String chave) async {
    if (!mounted) return;
    setState(() {
      if (!favoritosVersiculos.remove(chave)) {
        favoritosVersiculos.add(chave);
      }
    });
    await _persistirFavoritosVersiculos();
  }

  Future<void> _toggleFavoritoCapitulo(String chave) async {
    if (!mounted) return;
    setState(() {
      if (!favoritosCapitulos.remove(chave)) {
        favoritosCapitulos.add(chave);
      }
    });
    await _persistirFavoritosCapitulos();
  }

  /// Persistência serializada de favoritos: encadeia as escritas em uma fila
  /// para que toques concorrentes (duplo-toque, toques em abas diferentes)
  /// respeitem a ordem last-write-wins — memória e disco nunca divergem (C4).
  Future<void> _persistirFavoritosVersiculos() {
    final snapshot = favoritosVersiculos.toList();
    _escritaFavVersiculos = _escritaFavVersiculos.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favoritos_versiculos', snapshot);
    });
    return _escritaFavVersiculos;
  }

  Future<void> _persistirFavoritosCapitulos() {
    final snapshot = favoritosCapitulos.toList();
    _escritaFavCapitulos = _escritaFavCapitulos.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favoritos_capitulos', snapshot);
    });
    return _escritaFavCapitulos;
  }

  String _chaveCapitulo(String livroNome, dynamic numeroCapitulo) {
    return '$livroNome $numeroCapitulo';
  }

  String? _nomeLivroDaChave(String chave) {
    // Usa o índice em vez de separar por espaços, pois vários livros têm nome
    // composto ou começam com número (por exemplo, "1 Coríntios").
    for (final item in _indice.reversed) {
      final nome = '${item['nome']}';
      if (chave.startsWith('$nome ')) return nome;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _assegurarLivroDaChave(String chave) {
    final nome = _nomeLivroDaChave(chave);
    return nome == null ? Future.value() : _assegurarLivro(nome);
  }

  /// Busca de texto de versículo delegada aos guardiões puros (E16): itens
  /// corrompidos dentro das listas não lançam `TypeError`; ausência → null e
  /// a UI exibe "Conteúdo não encontrado." (E14).
  String? _buscarTextoVersiculo(String chave) =>
      textoDeVersiculoEmLivros(_cacheLivros.cache.values, chave);

  /// Busca de texto (falado) de capítulo delegada aos guardiões puros (E16),
  /// com a mesma defensividade de [_buscarTextoVersiculo].
  String? _buscarTextoCapitulo(String chaveCapitulo) =>
      textoDeCapituloEmLivros(_cacheLivros.cache.values, chaveCapitulo);

  Map<String, String> _conteudoDoDia() {
    if (_carregamentoInicial) return {};
    // Recalcula o livro do dia a partir do relógio (injetável): se a data
    // mudou com o app aberto, o conteúdo segue o dia atual (caso B4 de QA).
    final dia = diasDesdeEpoca(_agora);
    final nomeLivro =
        _indice.isEmpty ? null : '${_indice[dia % _indice.length]['nome']}';
    final Map<String, dynamic>? livro =
        nomeLivro == null ? null : _cacheLivros.cache[nomeLivro];
    return selecionarVersiculoDoDia(
      dia: dia,
      mensagens: _mensagens,
      livro: livro,
    );
  }

  Widget _montarTelaInicio(Map<String, String> conteudo, String hoje) {
    final referencia = conteudo['referencia'] ?? '';
    final versiculo = conteudo['versiculo'] ?? '';
    final isFav = favoritosVersiculos.contains(referencia);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      physics: const ClampingScrollPhysics(),
      dragStartBehavior: DragStartBehavior.down,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          Text(
            hoje,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 44,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Versículo do Dia',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  '"$versiculo"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.55,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  referencia,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final botaoOuvir = FilledButton.icon(
                      onPressed: (referencia.isEmpty || !_ttsDisponivel)
                          ? null
                          : () => _falarVersiculo(referencia, versiculo),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Ouvir versículo'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    );
                    final botaoSalvar = OutlinedButton.icon(
                      onPressed: referencia.isEmpty
                          ? null
                          : () => _toggleFavoritoVersiculo(referencia),
                      icon:
                          Icon(isFav ? Icons.favorite : Icons.favorite_border),
                      label: Text(isFav ? 'Salvo' : 'Salvar versículo'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                    );

                    // Em telas muito estreitas, empilha os botões para evitar overflow.
                    if (constraints.maxWidth < 420) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: double.infinity, child: botaoOuvir),
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: botaoSalvar),
                        ],
                      );
                    }

                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [botaoOuvir, botaoSalvar],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: Colors.pink.shade300,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      // Texto flexível: em telas estreitas (320 px) ou com fonte
                      // grande, quebra em vez de estourar o Row (caso B12 de QA).
                      Expanded(
                        child: Text(
                          'Mensagem para você',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    conteudo['mensagem'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const BannerAnuncio(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => setState(() => aba = 1),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Ler a Bíblia'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => aba = 3),
                  icon: const Icon(Icons.bookmarks_outlined),
                  label: const Text('Salvos'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _montarTelaLeitura() {
    // Linhas planas (descrições leves) para o ListView.builder LAZY: um livro
    // expandido vira as linhas de capítulo/versículo, mas cada widget só é
    // construído quando entra na viewport. Antes, um único livro grande
    // (ex.: Salmos, ~2.400 versículos) montava todos os ListTiles de uma vez
    // num frame — o custo de CPU/memória que o caso C6 da matriz expunha.
    final linhas = <Widget Function()>[];
    for (final livro in _indice) {
      final nomeLivro = '${livro['nome']}';
      final numCapitulos = livro['capitulos'] ?? 0;
      final expandido = _livrosExpandidos.contains(nomeLivro);
      linhas.add(() => _cartaoLivro(nomeLivro, numCapitulos, expandido));

      if (!expandido) continue;

      final capitulos = _capitulosPorLivro[nomeLivro];
      if (capitulos == null) {
        if (_livrosComErro.contains(nomeLivro)) {
          linhas.add(() => _linhaLivroComErro());
        } else {
          linhas.add(() => _linhaCarregandoLivro());
        }
        continue;
      }

      for (final capRaw in capitulos.whereType<Map>()) {
        final capitulo = Map<String, dynamic>.from(capRaw);
        final numeroCapitulo = capitulo['numero'];
        final chaveCapitulo = _chaveCapitulo(nomeLivro, numeroCapitulo);
        final versiculos = comoLista(capitulo['versiculos']) ?? const [];
        linhas.add(
          () => _cabecalhoCapitulo(nomeLivro, numeroCapitulo, chaveCapitulo),
        );
        for (final vRaw in versiculos.whereType<Map>()) {
          final versiculo = Map<String, dynamic>.from(vRaw);
          final numeroVersiculo = versiculo['numero'];
          final chaveVersiculo = '$nomeLivro $numeroCapitulo:$numeroVersiculo';
          final texto = '${versiculo['texto']}';
          linhas.add(() => _linhaVersiculo(nomeLivro, chaveVersiculo, texto));
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const ClampingScrollPhysics(),
      dragStartBehavior: DragStartBehavior.down,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: linhas.length,
      itemBuilder: (context, i) => linhas[i](),
    );
  }

  /// Cartão-cabeçalho de um livro (mesmo visual do antigo ExpansionTile), sem
  /// montar o conteúdo — só o chevron gira ao expandir/recolher.
  Widget _cartaoLivro(String nomeLivro, dynamic numCapitulos, bool expandido) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => _alternarLivro(nomeLivro),
        leading: const Icon(Icons.book_outlined),
        title: Text(
          nomeLivro,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('$numCapitulos capítulos'),
        trailing: AnimatedRotation(
          turns: expandido ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.expand_more),
        ),
      ),
    );
  }

  Widget _linhaCarregandoLivro() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _linhaLivroComErro() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Não foi possível carregar este livro.'),
    );
  }

  /// Cabeçalho de capítulo (mesmo visual do bloco antigo).
  Widget _cabecalhoCapitulo(
    String nomeLivro,
    dynamic numeroCapitulo,
    String chaveCapitulo,
  ) {
    final capFav = favoritosCapitulos.contains(chaveCapitulo);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Capítulo $numeroCapitulo',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (_temEstudos(chaveCapitulo, nomeLivro))
            IconButton(
              tooltip: 'Estudos do capítulo',
              icon: const Icon(Icons.auto_stories_outlined),
              onPressed: () =>
                  _abrirEstudosDaReferencia(chaveCapitulo, nomeLivro),
            ),
          IconButton(
            tooltip: 'Ouvir capítulo',
            onPressed:
                _ttsDisponivel ? () => _falarCapitulo(chaveCapitulo) : null,
            icon: const Icon(Icons.volume_up_outlined),
          ),
          IconButton(
            tooltip: capFav ? 'Remover capítulo salvo' : 'Salvar capítulo',
            onPressed: () => _toggleFavoritoCapitulo(chaveCapitulo),
            icon: Icon(capFav ? Icons.bookmark : Icons.bookmark_border),
          ),
        ],
      ),
    );
  }

  /// Linha de versículo (mesmo visual do bloco antigo).
  Widget _linhaVersiculo(
    String nomeLivro,
    String chaveVersiculo,
    String texto,
  ) {
    final isFav = favoritosVersiculos.contains(chaveVersiculo);
    return ListTile(
      minVerticalPadding: 10,
      title: Text(
        chaveVersiculo,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(texto),
      trailing: Wrap(
        spacing: 2,
        children: [
          if (_temEstudos(chaveVersiculo, nomeLivro))
            IconButton(
              tooltip: 'Estudos do versículo',
              icon: const Icon(Icons.auto_stories_outlined),
              onPressed: () =>
                  _abrirEstudosDaReferencia(chaveVersiculo, nomeLivro),
            ),
          IconButton(
            tooltip: 'Ouvir versículo',
            icon: const Icon(Icons.volume_up),
            onPressed: _ttsDisponivel
                ? () => _falarVersiculo(chaveVersiculo, texto)
                : null,
          ),
          IconButton(
            tooltip: isFav ? 'Remover dos salvos' : 'Salvar versículo',
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.redAccent : null,
            ),
            onPressed: () => _toggleFavoritoVersiculo(chaveVersiculo),
          ),
        ],
      ),
    );
  }

  Widget _montarTelaEstudos() {
    if (_indiceEstudos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Nenhum recurso de estudo disponível ainda.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final tipos = tiposDisponiveis(_indiceEstudos);
    final livros = livrosDisponiveis(_indiceEstudos);
    final filtrados = filtrarPorBusca(
      filtrarRecursos(
        _indiceEstudos,
        tipo: _tipoFiltroEstudos,
        livro: _livroFiltroEstudos.isEmpty ? null : _livroFiltroEstudos,
      ),
      _buscaEstudos,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar nos estudos',
              border: OutlineInputBorder(),
            ),
            onChanged: (valor) => setState(() => _buscaEstudos = valor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Todos os tipos'),
                  selected: _tipoFiltroEstudos == null,
                  onSelected: (_) => setState(() => _tipoFiltroEstudos = null),
                ),
                const SizedBox(width: 8),
                ...tipos.map(
                  (tipo) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(rotuloTipo(tipo)),
                      selected: _tipoFiltroEstudos == tipo,
                      onSelected: (sel) => setState(
                        () => _tipoFiltroEstudos = sel ? tipo : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: DropdownButtonFormField<String>(
            initialValue: _livroFiltroEstudos,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Filtrar por livro',
            ),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('Todos os livros'),
              ),
              ...livros.map(
                (livro) => DropdownMenuItem<String>(
                  value: livro,
                  child: Text(livro, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (valor) =>
                setState(() => _livroFiltroEstudos = valor ?? ''),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhum recurso encontrado com esse filtro.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: filtrados.length,
                  itemBuilder: (context, i) {
                    final recurso = filtrados[i];
                    final salvo = favoritosEstudos.contains(recurso.id);
                    final titulo = recurso.titulo.isEmpty
                        ? rotuloTipo(recurso.tipo)
                        : recurso.titulo;
                    final subtitulo = recurso.referencia.isEmpty
                        ? rotuloTipo(recurso.tipo)
                        : '${rotuloTipo(recurso.tipo)} • ${recurso.referencia}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.auto_stories_outlined),
                        title: Text(titulo),
                        subtitle: Text(subtitulo),
                        onTap: () => _abrirRecursoEstudo(recurso),
                        trailing: IconButton(
                          tooltip: salvo ? 'Remover dos salvos' : 'Salvar',
                          icon: Icon(
                            salvo ? Icons.bookmark : Icons.bookmark_border,
                          ),
                          onPressed: () => _toggleFavoritoEstudo(recurso.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _montarTelaSalvos() {
    final listaVersiculos = favoritosVersiculos.toList()..sort();
    final listaCapitulos = favoritosCapitulos.toList()..sort();
    final listaEstudos = favoritosEstudos.toList()..sort();

    if (listaVersiculos.isEmpty &&
        listaCapitulos.isEmpty &&
        listaEstudos.isEmpty) {
      return const Center(
        child: Text('Nenhum versículo, capítulo ou estudo salvo ainda.'),
      );
    }

    final itens = <Widget>[];

    if (listaCapitulos.isNotEmpty) {
      itens.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            'Capítulos salvos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
      itens.addAll(
        listaCapitulos.map((chaveCapitulo) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _assegurarLivroDaChave(chaveCapitulo),
            builder: (context, snapshot) {
              final carregado =
                  snapshot.connectionState == ConnectionState.done &&
                      _buscarTextoCapitulo(chaveCapitulo) != null;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(chaveCapitulo),
                  subtitle: snapshot.connectionState == ConnectionState.waiting
                      ? const Text('Carregando capítulo...')
                      : null,
                  leading: const Icon(Icons.bookmark, color: Colors.amber),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: 'Ouvir capítulo',
                        onPressed: (carregado && _ttsDisponivel)
                            ? () => _falarCapitulo(chaveCapitulo)
                            : null,
                        icon: const Icon(Icons.volume_up),
                      ),
                      IconButton(
                        tooltip: 'Remover capítulo salvo',
                        onPressed: () => _toggleFavoritoCapitulo(chaveCapitulo),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      );
    }

    if (listaVersiculos.isNotEmpty) {
      itens.add(const SizedBox(height: 8));
      itens.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            'Versículos salvos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
      itens.addAll(
        listaVersiculos.map((chaveVersiculo) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: _assegurarLivroDaChave(chaveVersiculo),
            builder: (context, snapshot) {
              final texto = _buscarTextoVersiculo(chaveVersiculo) ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(chaveVersiculo),
                  subtitle: snapshot.connectionState == ConnectionState.waiting
                      ? const Text('Carregando versículo...')
                      : texto.isEmpty
                          ? const Text('Conteúdo não encontrado.')
                          : Text(texto),
                  leading: const Icon(Icons.favorite, color: Colors.redAccent),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: 'Ouvir versículo',
                        onPressed: (texto.isEmpty || !_ttsDisponivel)
                            ? null
                            : () => _falarVersiculo(chaveVersiculo, texto),
                        icon: const Icon(Icons.volume_up),
                      ),
                      IconButton(
                        tooltip: 'Remover versículo salvo',
                        onPressed: () =>
                            _toggleFavoritoVersiculo(chaveVersiculo),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      );
    }

    if (listaEstudos.isNotEmpty) {
      itens.add(const SizedBox(height: 8));
      itens.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            'Recursos de estudo salvos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
      itens.addAll(
        listaEstudos.map((id) {
          RecursoEstudo? resumo;
          for (final recurso in _indiceEstudos) {
            if (recurso.id == id) {
              resumo = recurso;
              break;
            }
          }
          final encontrado = resumo;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(
                Icons.auto_stories_outlined,
                color: Colors.indigo,
              ),
              title: Text(
                encontrado == null
                    ? id
                    : (encontrado.titulo.isEmpty
                        ? rotuloTipo(encontrado.tipo)
                        : encontrado.titulo),
              ),
              subtitle: encontrado == null
                  ? const Text('Conteúdo não encontrado.')
                  : Text(
                      encontrado.referencia.isEmpty
                          ? rotuloTipo(encontrado.tipo)
                          : '${rotuloTipo(encontrado.tipo)} • '
                              '${encontrado.referencia}',
                    ),
              trailing: Wrap(
                spacing: 2,
                children: [
                  IconButton(
                    tooltip: 'Abrir recurso',
                    onPressed: encontrado == null
                        ? null
                        : () => _abrirRecursoEstudo(encontrado),
                    icon: const Icon(Icons.open_in_new),
                  ),
                  IconButton(
                    tooltip: 'Remover recurso salvo',
                    onPressed: () => _toggleFavoritoEstudo(id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          );
        }),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      dragStartBehavior: DragStartBehavior.down,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: itens,
    );
  }

  Future<void> _copiarChavePix() async {
    // A permissão de clipboard pode ser negada (web/desktop): falha de forma
    // graciosa, orientando o usuário a copiar manualmente (caso B2 de QA).
    var copiou = false;
    try {
      await Clipboard.setData(const ClipboardData(text: chavePix));
      copiou = true;
    } catch (_) {
      copiou = false;
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            copiou
                ? 'Chave Pix copiada com sucesso!'
                : 'Não foi possível copiar. Copie manualmente: $chavePix',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    if (copiou) {
      await _mostrarComoDoar(chaveJaCopiada: true);
    }
  }

  Future<void> _mostrarComoDoar({bool chaveJaCopiada = false}) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.pix,
          size: 44,
          color: Theme.of(dialogContext).colorScheme.primary,
        ),
        title: Text(
          chaveJaCopiada ? 'Chave Pix copiada!' : 'Como fazer a doação',
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (chaveJaCopiada)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Agora siga estes passos no Nubank ou no aplicativo do seu banco:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('1')),
                title: Text('Abra o aplicativo do seu banco.'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('2')),
                title: Text('Toque em “Pix” e depois em “Transferir”.'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('3')),
                title:
                    Text('Cole a chave, escolha o valor e confira os dados.'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('4')),
                title:
                    Text('Confirme a doação somente se estiver tudo correto.'),
              ),
              if (!chaveJaCopiada) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      var copiou = false;
                      try {
                        await Clipboard.setData(
                          const ClipboardData(text: chavePix),
                        );
                        copiou = true;
                      } catch (_) {
                        copiou = false;
                      }
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              copiou
                                  ? 'Chave Pix copiada com sucesso!'
                                  : 'Não foi possível copiar. Copie manualmente: $chavePix',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copiar chave Pix'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Widget _montarTelaAjustes() {
    final temVozes = _vozesDisponiveis.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      dragStartBehavior: DragStartBehavior.down,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        SwitchListTile(
          title: const Text('Tema escuro'),
          secondary: const Icon(Icons.dark_mode_outlined),
          value: widget.temaEscuro,
          onChanged: widget.onToggleTema,
        ),
        SwitchListTile(
          title: const Text('Fonte maior (recomendado)'),
          subtitle: const Text('Melhora leitura para pessoas idosas.'),
          secondary: const Icon(Icons.text_fields),
          value: widget.fonteGrande,
          onChanged: widget.onToggleFonteGrande,
        ),
        ListTile(
          leading: Icon(
            _falando
                ? Icons.graphic_eq
                : _pausado
                    ? Icons.pause_circle_outline
                    : Icons.record_voice_over,
          ),
          title: Text(
            _leituraAtiva
                ? (_pausado ? 'Leitura pausada' : 'Leitura em andamento')
                : _ttsDisponivel
                    ? 'Leitura em voz alta'
                    : 'Leitura em voz alta (indisponível)',
          ),
          subtitle: Text(
            _ttsDisponivel
                ? 'Leitura manual, não-continuada. O som para ao final de cada trecho.'
                : 'Não está disponível nesta plataforma/dispositivo.',
          ),
          trailing: _leituraAtiva ? _botaoPlayPause(compacto: true) : null,
        ),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Escolha de voz',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecione manualmente a voz de leitura disponível no seu aparelho.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (temVozes)
                  DropdownButtonFormField<String>(
                    initialValue: _vozSelecionadaId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Voz atual',
                    ),
                    items: _vozesDisponiveis
                        .map(
                          (voz) => DropdownMenuItem<String>(
                            value: voz.id,
                            child: Text(
                              voz.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _selecionarVozPorId,
                  )
                else
                  Text(
                    _ttsDisponivel
                        ? 'Nenhuma voz pt disponível no dispositivo.'
                        : 'Leitura em voz alta não disponível aqui.',
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _vozMasculinaId == null
                          ? null
                          : () => _selecionarVozPorGenero('male'),
                      icon: const Icon(Icons.male),
                      label: const Text('Voz masculina'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _vozFemininaId == null
                          ? null
                          : () => _selecionarVozPorGenero('female'),
                      icon: const Icon(Icons.female),
                      label: const Text('Voz feminina'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.primaryContainer.withValues(
                alpha: 0.6,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Apoiar o projeto via Pix',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Sua contribuição é voluntária e ajuda a manter este '
                  'aplicativo gratuito. A doação será recebida em uma conta Nubank.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: 'Chave Pix por e-mail: $chavePix',
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHAVE PIX — E-MAIL',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 6),
                        SelectableText(
                          chavePix,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _copiarChavePix,
                  icon: const Icon(Icons.copy_rounded, size: 26),
                  label: const Text('Copiar chave Pix'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _mostrarComoDoar,
                  icon: const Icon(Icons.help_outline_rounded),
                  label: const Text('Ver como fazer a doação'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Antes de confirmar, confira no banco o nome de quem receberá.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.accessibility_new),
          title: Text('Uso simples e legível'),
          subtitle: Text(
            'Este app foi ajustado para facilitar leitura e toque para todas as idades.',
          ),
        ),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Sobre o app'),
          subtitle: Text('Bíblia Diária • Offline • Gratuito'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregamentoInicial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Garante que o livro do dia atual esteja carregado mesmo após a virada
    // de data com o app aberto (caso B4 de QA); dispara rebuild ao concluir.
    final nomeLivroAtual = _indice.isEmpty
        ? null
        : '${_indice[diasDesdeEpoca(_agora) % _indice.length]['nome']}';
    if (nomeLivroAtual != null && !_cacheLivros.contem(nomeLivroAtual)) {
      _cacheLivros.assegurar(nomeLivroAtual).then((_) {
        if (mounted) setState(() {});
      });
    }

    final conteudo = _conteudoDoDia();
    final hoje = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_agora);

    final telas = [
      _montarTelaInicio(conteudo, hoje),
      _montarTelaLeitura(),
      _montarTelaEstudos(),
      _montarTelaSalvos(),
      _montarTelaAjustes(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bíblia Diária'),
        centerTitle: true,
      ),
      body: telas[aba],
      floatingActionButton: _leituraAtiva
          ? FloatingActionButton(
              onPressed: _alternarPlayPause,
              tooltip: (_falando && !_pausado) ? 'Pausar' : 'Continuar',
              child: Icon(
                (_falando && !_pausado)
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 32,
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: aba,
        onDestinationSelected: (i) => setState(() => aba = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Bíblia',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Estudos',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks),
            label: 'Salvos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
