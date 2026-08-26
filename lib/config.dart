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
