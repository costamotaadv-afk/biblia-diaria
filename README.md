# Bíblia App — Guia para começar (nível zero)

Este é um projeto inicial funcional. Ele já tem: leitura de versículos, favoritos
salvos no aparelho, e tema claro/escuro. Falta ligar anúncios e doações de verdade.

## 1. Instalar o essencial (uma vez só)

1. Baixe e instale o Flutter SDK: https://docs.flutter.dev/get-started/install
   (siga o instalador para o seu sistema — Windows, Mac ou Linux).
2. Abra o VS Code e instale duas extensões (ícone de blocos na lateral esquerda,
   busque e clique em "Install"):
   - Flutter (da equipe Dart Code)
   - Dart (geralmente instala junto)
3. Abra um terminal (Terminal > New Terminal no VS Code) e rode:
   flutter doctor
   Isso mostra o que ainda falta instalar (ex: Android Studio, licenças do Android).
   Resolva os itens marcados com "✗" seguindo as instruções que aparecerem na tela.

## 2. Abrir este projeto

1. No VS Code: File > Open Folder > selecione a pasta do projeto.
2. No terminal, dentro da pasta do projeto, rode:
   flutter pub get
   Isso baixa as bibliotecas (dependências) listadas em pubspec.yaml.

## 3. Rodar o app pela primeira vez

1. Conecte um celular Android por USB (com "Depuração USB" ativada nas opções de
desenvolvedor) OU abra um emulador pelo Android Studio.
2. No VS Code, aperte F5 (ou vá em Run > Start Debugging).
3. O app deve abrir no celular/emulador em alguns segundos.

## 4. Como editar o conteúdo (versículos e mensagens)

Abra o arquivo assets/data/biblia.json. Ele é só texto — você pode adicionar,
remover ou ajustar livros, capítulos, versículos e mensagens seguindo o mesmo
formato que já está lá. Depois de editar, salve o arquivo e aperte "Hot Restart"
no VS Code (ícone de raio com um R).

Importante: este arquivo já contém a Bíblia completa em português (66 livros,
de Gênesis a Apocalipse) em domínio público, além das mensagens diárias.

## 5. Próximos passos (nesta ordem sugerida)

1. ~~Substituir biblia_exemplo.json pelo texto bíblico completo.~~ ✔ Concluído
2. Criar conta no Google AdMob e seguir a documentação oficial do pacote
google_mobile_ads para inserir um banner.
   🟡 Em andamento: o banner já foi inserido em código usando os
   identificadores de TESTE do Google (veja a seção 6 abaixo). Falta só criar
   a conta AdMob e trocar pelos IDs reais.
3. Adicionar o pacote url_launcher para o botão "Apoiar o projeto" abrir seu
link de doação de verdade (Pix, PayPal, Buy Me a Coffee etc.).
   ✔ Concluído — o botão "Apoiar o projeto" já existe na aba Ajustes e usa o
   url_launcher. Falta apenas trocar o link (veja a seção 7).
4. Criar o ícone do app e ajustar cores/fontes.
   ✔ Concluído — o ícone (livro com coração, fundo índigo) foi gerado para
   Android e o tema recebeu uma paleta com destaque dourado e tipografia mais
   legível. A imagem-base fica em assets/icon/app_icon.png.
5. Gerar o build final:
   flutter build appbundle   (para Google Play e Galaxy Store)
   flutter build ipa         (para App Store — precisa de Mac)
   ⏸️ Aguardando: ainda não foi gerado porque o Android SDK não está instalado
   nesta máquina. Instale o Android Studio (https://developer.android.com/studio)
   e ele instalará o Android SDK no primeiro uso. Depois, na pasta do projeto,
   rode: flutter build appbundle

## 6. Configuração do AdMob (Etapa 2)

O app já traz o banner de anúncio configurado, mas com os IDs de TESTE do
Google. Para publicar de verdade, você precisa:

1. Em https://admob.google.com , crie sua conta e registre o aplicativo.
2. No console, anote dois valores:
   - App ID (formato: ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY)
   - ID do bloco de anúncios de banner (formato: ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY)
   (crie um bloco de banner nas configurações do app, se ainda não existir).
3. Localize e troque os IDs de teste pelos seus IDs reais em DOIUS lugares:

   a) AndroidManifest.xml:
      O App ID está no arquivo android/app/src/main/AndroidManifest.xml, na
      linha <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID">.

   b) lib/widgets/banner_anuncio.dart:
      O ID do banner está na constante _bannerAdUnitId no topo desse arquivo.

4. (Opcional, recomendado para teste) Adicione o seu aparelho como "Dispositivo
de teste" no console do AdMob, para ver anúncios de teste em vez dos reais.
5. Item 2 será marcado como concluído quando os IDs reais forem colocados.

> Importante: a plataforma Android foi adicionada ao projeto apenas para viabilizar
> o AdMob. Se preferir manter só web/windows, o banner ficará invisível nesses alvos
> (anúncios do AdMob não rodam em navegador ou desktop).

## 7. Configuração do link de doação (Etapa 3)

O botão "Apoiar o projeto" (na aba Ajustes) abre um link de doação. Por enquanto
ele aponta para um endereço de exemplo. Para configurar o seu link real:

1. Crie seu link de doação em um serviço de sua preferência:
   (Pix com chave copia-e-cola é comum no Brasil; também existem PayPal e
   Buy Me a Coffee).
2. No arquivo lib/main.dart, localize a constante _urlDoacao (logo acima do
   método que monta a aba Ajustes) e troque o endereço pelo seu link real:
   static const String _urlDoacao = 'SEU_LINK_AQUI';
3. Salve e faça Hot Restart. O botão passará a abrir o seu link.

> Em produção, evite usar link de exemplo. Links de Pix, PayPal ou Buy Me a
> Coffee costumam abrir no navegador ou no próprio aplicativo de pagamento.

## Se algo der errado

- flutter doctor sempre mostra o que está faltando — leia a mensagem com calma,
  quase sempre ela já diz o comando exato para resolver.
- Erro comum: esquecer de rodar flutter pub get depois de mudar o pubspec.yaml.


