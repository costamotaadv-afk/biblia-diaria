/// Configurações de negócio do app (Pix, AdMob) e validações associadas.
///
/// Extraídas para permitir testes de regressão dos casos B3 (chave Pix) e B8
/// (IDs de anúncio de teste em release) da matriz de QA.
library;

/// Chave Pix (e-mail) que recebe as doações do projeto.
const String chavePix = 'costamota@gmail.com';

/// True se [chave] tem formato de e-mail (formato exigido pelo Pix).
///
/// Caso B3 da matriz: a chave fixa no código não pode ser trocada por um
/// valor inválido em manutenção futura sem que um teste acuse imediatamente.
bool chavePixValida(String chave) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(chave);
}

/// Mensagem de erro caso um ID de anúncio de TESTE do Google esteja
/// configurado em um build de release (caso B8 da matriz de QA).
///
/// `ca-app-pub-3940256099942544...` são os IDs de teste oficiais do Google;
/// publicá-los em produção viola a política do AdMob e zera a receita.
String? erroIdAnuncioEmProducao({
  required bool isRelease,
  required String id,
}) {
  if (!isRelease) return null;
  if (id.startsWith('ca-app-pub-3940256099942544')) {
    return 'ID de anúncio é o TESTE do Google (ca-app-pub-3940256099942544). '
        'Substitua pelo ID real do AdMob antes de publicar.';
  }
  return null;
}

/// Link público de download/uso do app, usado na mensagem de compartilhamento
/// (caso SH1 da matriz de QA).
///
/// Deixe vazio até publicar o site ou a loja: com o link vazio, o botão de
/// compartilhar fica oculto — nunca enviamos o usuário para um endereço morto.
const String linkDownloadApp = '';

/// True se [link] é um URL absoluto http/https com domínio (caso SH1).
bool linkCompartilhamentoValido(String link) {
  final uri = Uri.tryParse(link.trim());
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

/// Mensagem pronta para o WhatsApp (ou qualquer rede escolhida na folha de
/// compartilhamento). Função pura, testável sem widget/plugin.
String mensagemCompartilhamento({String link = linkDownloadApp}) {
  return '📖 *Bíblia Diária* — a Bíblia completa, gratuita e offline, '
      'com leitura em voz alta.\n\nAcesse: $link';
}

/// Rodapé opcional de divulgação (link do app) usado nas mensagens de
/// compartilhamento de versículo/capítulo/Salmo. Vazio enquanto o link não
/// foi publicado ainda — nunca envia endereço morto (caso SH3 da matriz).
String rodapeCompartilhamento(String link) {
  return linkCompartilhamentoValido(link) ? '\n\n📲 Baixe grátis: $link' : '';
}

/// Mensagem para compartilhar um versículo (caso SV1): referência + texto.
String mensagemCompartilharVersiculo({
  required String referencia,
  required String texto,
  String link = linkDownloadApp,
}) {
  return '📖 *$referencia*\n\n“$texto”${rodapeCompartilhamento(link)}';
}

/// Mensagem para compartilhar um capítulo inteiro (caso SC1). A referência
/// pode ser natural ("Salmo 23") ou padrão ("Gênesis 1") — quem chama decide.
String mensagemCompartilharCapitulo({
  required String referencia,
  required String texto,
  String link = linkDownloadApp,
}) {
  return '📖 *$referencia*\n\n$texto${rodapeCompartilhamento(link)}';
}

/// Mensagem para compartilhar a contextualização histórica de um Salmo
/// (caso SS1): cabeçalho "Salmo N — título" + explicação + rodapé.
String mensagemCompartilharSalmo({
  required int numero,
  required String titulo,
  required String explicacao,
  String link = linkDownloadApp,
}) {
  final cabecalho =
      titulo.trim().isEmpty ? 'Salmo $numero' : 'Salmo $numero — $titulo';
  final buffer = StringBuffer('📖 *$cabecalho*');
  final explic = explicacao.trim();
  if (explic.isNotEmpty) buffer.write('\n\n$explic');
  buffer.write(rodapeCompartilhamento(link));
  return buffer.toString();
}
