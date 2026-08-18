import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
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
    final generoLegivel =
        gender.contains('male') ? 'Masculina' : gender.contains('female') ? 'Feminina' : 'Neutra';
    return '$name ($locale, $generoLegivel)';
  }
}

class BibliaApp extends StatefulWidget {
  const BibliaApp({super.key});

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bíblia Diária',
      debugShowCheckedModeBanner: false,
      themeMode: temaEscuro ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3F51B5),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3F51B5),
        brightness: Brightness.dark,
      ),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final escala = fonteGrande ? 1.18 : 1.0;
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(escala)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: TelaPrincipal(
        temaEscuro: temaEscuro,
        onToggleTema: _atualizarTema,
        fonteGrande: fonteGrande,
        onToggleFonteGrande: _atualizarFonteGrande,
      ),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  final bool temaEscuro;
  final ValueChanged<bool> onToggleTema;
  final bool fonteGrande;
  final ValueChanged<bool> onToggleFonteGrande;

  const TelaPrincipal({
    super.key,
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
  Map<String, dynamic>? dados;
  Set<String> favoritosVersiculos = {};
  Set<String> favoritosCapitulos = {};
  final FlutterTts _tts = FlutterTts();
  bool _falando = false;
  bool _pausado = false;
  bool _leituraAtiva = false;
  String? _textoLeituraAtual;
  List<VozTts> _vozesDisponiveis = [];
  String? _vozSelecionadaId;
  String? _vozMasculinaId;
  String? _vozFemininaId;

  @override
  void initState() {
    super.initState();
    _carregar();
    _configurarTts();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _carregar() async {
    final jsonStr = await rootBundle.loadString('assets/data/biblia.json');

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      dados = json.decode(jsonStr) as Map<String, dynamic>;
      favoritosVersiculos =
          (prefs.getStringList('favoritos_versiculos') ?? []).toSet();
      favoritosCapitulos =
          (prefs.getStringList('favoritos_capitulos') ?? []).toSet();
    });
  }

  Future<void> _configurarTts() async {
    await _tts.setLanguage('pt-BR');
    await _tts.setSpeechRate(0.50);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

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

      vozes.sort((a, b) => a.label.compareTo(b.label));
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
          if (voz.locale.toLowerCase().contains('pt-br') && voz.gender.contains('male')) {
            _vozMasculinaId = voz.id;
            break;
          }
        }

        for (final voz in vozes) {
          if (voz.locale.toLowerCase().contains('pt-br') && voz.gender.contains('female')) {
            _vozFemininaId = voz.id;
            break;
          }
        }

        escolhida ??= vozes.firstWhere(
          (voz) => voz.locale.toLowerCase().contains('pt-br') && voz.gender.contains('male'),
          orElse: () => vozes.first,
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
    final textoAjustado = _textoParaLeituraNatural(texto);
    await _iniciarLeitura('$referencia. $textoAjustado');
  }

  Future<void> _falarCapitulo(String chaveCapitulo) async {
    // Garante que apenas este capítulo específico será lido do início ao fim.
    // Ao terminar o último versículo deste capítulo, o som para completamente
    // e não avança de forma alguma para o capítulo seguinte de modo automático.
    final texto = _buscarTextoCapitulo(chaveCapitulo);
    if (texto == null || texto.trim().isEmpty) return;
    final textoAjustado = _textoParaLeituraNatural(texto);
    await _iniciarLeitura('$chaveCapitulo. $textoAjustado');
  }

  Future<void> _iniciarLeitura(String textoCompleto) async {
    final texto = textoCompleto.trim();
    if (texto.isEmpty) return;

    await _tts.stop();
    if (!mounted) return;

    setState(() {
      _textoLeituraAtual = texto;
      _falando = false;
      _pausado = false;
      _leituraAtiva = true;
    });

    await _tts.speak(texto);
  }

  Future<void> _alternarPlayPause() async {
    if (!_leituraAtiva && !_falando && !_pausado) return;

    // Pausar leitura em andamento.
    if (_falando || (!_pausado && _leituraAtiva)) {
      await _tts.pause();
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
      await _tts.speak('');
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
    await _tts.speak(texto);
    if (mounted) {
      setState(() {
        _falando = true;
        _pausado = false;
        _leituraAtiva = true;
      });
    }
  }

  Widget _botaoPlayPause({bool compacto = false}) {
    final icone =
        (_falando && !_pausado) ? Icons.pause_rounded : Icons.play_arrow_rounded;
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

  String _textoParaLeituraNatural(String texto) {
    return texto
        .replaceAll(' - ', ', ')
        .replaceAll(';', ', ')
        .replaceAll(':', ': ')
        .replaceAll('"', '')
        .replaceAllMapped(RegExp(r'\b(\d+)\.'), (m) => '${m.group(1)}. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _toggleFavoritoVersiculo(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (favoritosVersiculos.contains(chave)) {
        favoritosVersiculos.remove(chave);
      } else {
        favoritosVersiculos.add(chave);
      }
    });
    await prefs.setStringList(
      'favoritos_versiculos',
      favoritosVersiculos.toList(),
    );
  }

  Future<void> _toggleFavoritoCapitulo(String chave) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (favoritosCapitulos.contains(chave)) {
        favoritosCapitulos.remove(chave);
      } else {
        favoritosCapitulos.add(chave);
      }
    });
    await prefs.setStringList(
      'favoritos_capitulos',
      favoritosCapitulos.toList(),
    );
  }

  String _chaveCapitulo(String livroNome, dynamic numeroCapitulo) {
    return '$livroNome $numeroCapitulo';
  }

  String? _buscarTextoVersiculo(String chave) {
    if (dados == null) return null;
    final livros = (dados!['livros'] as List?) ?? [];
    for (final livroRaw in livros) {
      final livro = livroRaw as Map<String, dynamic>;
      final capitulos = (livro['capitulos'] as List?) ?? [];
      for (final capRaw in capitulos) {
        final cap = capRaw as Map<String, dynamic>;
        final versiculos = (cap['versiculos'] as List?) ?? [];
        for (final vRaw in versiculos) {
          final v = vRaw as Map<String, dynamic>;
          final ref = '${livro['nome']} ${cap['numero']}:${v['numero']}';
          if (ref == chave) {
            return '${v['texto']}';
          }
        }
      }
    }
    return null;
  }

  String? _buscarTextoCapitulo(String chaveCapitulo) {
    if (dados == null) return null;
    final livros = (dados!['livros'] as List?) ?? [];
    for (final livroRaw in livros) {
      final livro = livroRaw as Map<String, dynamic>;
      final capitulos = (livro['capitulos'] as List?) ?? [];
      for (final capRaw in capitulos) {
        final cap = capRaw as Map<String, dynamic>;
        final chave = _chaveCapitulo('${livro['nome']}', cap['numero']);
        if (chave == chaveCapitulo) {
          final versiculos = (cap['versiculos'] as List?) ?? [];
          final textos = versiculos
              .map((v) {
                final item = v as Map<String, dynamic>;
                return '${item['numero']}. ${item['texto']}';
              })
               .toList();
          return textos.join(' ');
        }
      }
    }
    return null;
  }

  Map<String, String> _conteudoDoDia() {
    if (dados == null) return {};

    final dia = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final mensagens = extrairMensagens(dados!);
    final mensagem =
        mensagens.isEmpty ? 'Deus te fortaleça neste dia.' : mensagens[dia % mensagens.length];

    final livros = (dados!['livros'] as List?) ?? [];
    if (livros.isEmpty) {
      return {
        'versiculo': 'Sem conteúdo bíblico disponível.',
        'referencia': '',
        'mensagem': mensagem,
      };
    }

    final livro = livros[dia % livros.length] as Map<String, dynamic>;
    final capitulos = (livro['capitulos'] as List?) ?? [];
    if (capitulos.isEmpty) {
      return {
        'versiculo': 'Sem conteúdo bíblico disponível.',
        'referencia': '',
        'mensagem': mensagem,
      };
    }

    final cap = capitulos.first as Map<String, dynamic>;
    final versiculos = (cap['versiculos'] as List?) ?? [];
    if (versiculos.isEmpty) {
      return {
        'versiculo': 'Sem conteúdo bíblico disponível.',
        'referencia': '',
        'mensagem': mensagem,
      };
    }

    final vers = versiculos.first as Map<String, dynamic>;
    return {
      'versiculo': '${vers['texto']}',
      'referencia': '${livro['nome']} ${cap['numero']}:${vers['numero']}',
      'mensagem': mensagem,
    };
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
                      onPressed: referencia.isEmpty
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
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
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
                      Text(
                        'Mensagem para você',
                        style: Theme.of(context).textTheme.titleMedium,
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
          const SizedBox(height: 28),
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
                  onPressed: () => setState(() => aba = 2),
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
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      physics: const ClampingScrollPhysics(),
      dragStartBehavior: DragStartBehavior.down,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: (dados!['livros'] as List?)?.length ?? 0,
      itemBuilder: (context, i) {
        final livro = dados!['livros'][i] as Map<String, dynamic>;
        final nomeLivro = '${livro['nome']}';
        final capitulos = (livro['capitulos'] as List?) ?? const [];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ExpansionTile(
            key: PageStorageKey<String>('livro_$nomeLivro'),
            maintainState: true,
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: const Icon(Icons.book_outlined),
            title: Text(
              nomeLivro,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: capitulos.whereType<Map>().expand<Widget>((capRaw) {
              final capitulo = Map<String, dynamic>.from(capRaw);
              final numeroCapitulo = capitulo['numero'];
              final chaveCapitulo = _chaveCapitulo(nomeLivro, numeroCapitulo);
              final capFav = favoritosCapitulos.contains(chaveCapitulo);
              final versiculos = (capitulo['versiculos'] as List?) ?? [];

              final blocos = <Widget>[
                Container(
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
                      IconButton(
                        tooltip: 'Ouvir capítulo',
                        onPressed: () => _falarCapitulo(chaveCapitulo),
                        icon: const Icon(Icons.volume_up_outlined),
                      ),
                      IconButton(
                        tooltip: capFav ? 'Remover capítulo salvo' : 'Salvar capítulo',
                        onPressed: () => _toggleFavoritoCapitulo(chaveCapitulo),
                        icon: Icon(capFav ? Icons.bookmark : Icons.bookmark_border),
                      ),
                    ],
                  ),
                ),
              ];

              blocos.addAll(versiculos.whereType<Map>().map((vRaw) {
                final versiculo = Map<String, dynamic>.from(vRaw);
                final chaveVersiculo =
                    '$nomeLivro $numeroCapitulo:${versiculo['numero']}';
                final isFav = favoritosVersiculos.contains(chaveVersiculo);
                final texto = '${versiculo['texto']}';

                return ListTile(
                  minVerticalPadding: 10,
                  title: Text(
                    chaveVersiculo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(texto),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: 'Ouvir versículo',
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => _falarVersiculo(chaveVersiculo, texto),
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
              }));

              return blocos;
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _montarTelaSalvos() {
    final listaVersiculos = favoritosVersiculos.toList()..sort();
    final listaCapitulos = favoritosCapitulos.toList()..sort();

    if (listaVersiculos.isEmpty && listaCapitulos.isEmpty) {
      return const Center(
        child: Text('Nenhum versículo ou capítulo salvo ainda.'),
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
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(chaveCapitulo),
              leading: const Icon(Icons.bookmark, color: Colors.amber),
              trailing: Wrap(
                spacing: 2,
                children: [
                  IconButton(
                    tooltip: 'Ouvir capítulo',
                    onPressed: () => _falarCapitulo(chaveCapitulo),
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
          final texto = _buscarTextoVersiculo(chaveVersiculo) ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(chaveVersiculo),
              subtitle: texto.isEmpty ? null : Text(texto),
              leading: const Icon(Icons.favorite, color: Colors.redAccent),
              trailing: Wrap(
                spacing: 2,
                children: [
                  IconButton(
                    tooltip: 'Ouvir versículo',
                    onPressed: texto.isEmpty
                        ? null
                        : () => _falarVersiculo(chaveVersiculo, texto),
                    icon: const Icon(Icons.volume_up),
                  ),
                  IconButton(
                    tooltip: 'Remover versículo salvo',
                    onPressed: () => _toggleFavoritoVersiculo(chaveVersiculo),
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
                : 'Leitura em voz alta',
          ),
          subtitle: const Text(
            'Leitura manual, não-continuada. O som para ao final de cada trecho.',
          ),
          trailing: _leituraAtiva
              ? _botaoPlayPause(compacto: true)
              : null,
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  const Text('Nenhuma voz pt disponível no dispositivo.'),
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
    if (dados == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final conteudo = _conteudoDoDia();
    final hoje = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(DateTime.now());

    final telas = [
      _montarTelaInicio(conteudo, hoje),
      _montarTelaLeitura(),
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

List<String> extrairMensagens(Map<String, dynamic> dados) {
  final mensagens =
      (dados['mensagens'] as List?) ?? (dados['mensagens_dia'] as List?) ?? [];
  return mensagens
      .map((m) => '$m')
      .where((m) => m.trim().isNotEmpty)
      .toList();
}
