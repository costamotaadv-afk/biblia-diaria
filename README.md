# Bíblia App — Guia para começar (nível zero)

Este é um projeto inicial funcional. Ele já tem: leitura de versículos, favoritos
salvos no aparelho, tema claro/escuro e doações via Pix. Falta ligar os anúncios
de produção.

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

O texto bíblico e as mensagens ficam compactados em `tool/backup/biblia.json.gz`
(a versão .gz existe só para não ocupar ~13 MB no repositório). Para editar e
regenerar os arquivos que o app lê:

1. Descompacte `tool/backup/biblia.json.gz` (ou abra em um editor que leia .gz)
   e ajuste livros, capítulos, versículos e mensagens no mesmo formato.
2. Rode `python tool/dividir_biblia.py` — ele gera `assets/data/indice.json`,
   `assets/data/mensagens.json` e `assets/data/livros/<Livro>.json`.
3. Salve e aperte "Hot Restart" no VS Code (ícone de raio com um R).

Importante: a fonte contém a Bíblia completa em português (66 livros, de
Gênesis a Apocalipse) em domínio público, além das mensagens diárias.

### Como adicionar recursos de estudo

Além dos versículos, o app traz **recursos de estudo** (notas, comentários,
artigos, sermões, palestras e momentos históricos) ligados a um trecho bíblico.
Eles ficam em dois lugares:

- `assets/data/estudos_indice.json` — índice leve: lista cada recurso com `id`,
  `tipo`, `titulo`, `ref` (referência: `"João 3:16"`, `"João 3"` ou `"João"`),
  `livro` e `tema` (opcional), **sem** o texto.
- `assets/data/estudos/<Livro>.json` — detalhe por livro: os mesmos campos do
  índice, mais `corpo` (o texto) e `fonte` (opcional: `autor`, `obra`, `ano`,
  `licenca`).

Regras para editar:

1. Cada recurso precisa de um `id` único e estável (ex.: `"joao-3-16-comentario-1"`).
   Recursos sem `id` são ignorados.
2. O `id` do detalhe deve ser **igual** ao `id` do índice (o índice é a fonte da
   verdade; o detalhe é quem guarda o `corpo`).
3. Tipos válidos: `nota`, `comentario`, `artigo`, `sermao`, `palestra`,
   `momento_historico`. Outros tipos aparecem com um rótulo genérico.
4. Após editar, salve o arquivo e aperte "Hot Restart" no VS Code.

### Como adicionar contexto histórico

Os "momentos históricos" (`tipo: "momento_historico"`) também aceitam dois
campos opcionais que enriquecem a leitura:

- `periodo` — o período histórico/arqueológico (ex.: `"Novo Império Egípcio
  (c. 1550–1069 a.C.)"`).
- `fatos` — lista de fatos arqueológicos/históricos em tópicos.

No índice (`estudos_indice.json`), mantenha apenas `id`, `tipo`, `titulo`, `ref`,
`livro` e `tema` (sem `periodo`/`fatos`/`corpo`). No detalhe
(`estudos/<Livro>.json`), adicione `periodo` e/ou `fatos` junto do `corpo`. O app
exibe esses campos com um selo de período e uma lista de tópicos, e os inclui na
leitura em voz alta ("Ouvir").

Conteúdo histórico exige curadoria e crédito de fonte (`fonte`): não invente
fatos — revise cada afirmação antes de publicar. Para conferir a consistência
dos dados antes de rodar o app:

```powershell
python tool/validar_estudos.py
```

## 5. Próximos passos (nesta ordem sugerida)

1. ~~Substituir biblia_exemplo.json pelo texto bíblico completo.~~ ✔ Concluído
2. Criar conta no Google AdMob e seguir a documentação oficial do pacote
google_mobile_ads para inserir um banner.
   🟡 Em andamento: o banner já foi inserido em código usando os
   identificadores de TESTE do Google (veja a seção 6 abaixo). Falta só criar
   a conta AdMob e trocar pelos IDs reais.
3. Configurar o botão "Apoiar o projeto" para receber doações via Pix.
   ✔ Concluído — a chave Pix da conta Nubank está configurada na aba Ajustes,
   com botão para copiar e instruções acessíveis (veja a seção 7).
4. Criar o ícone do app e ajustar cores/fontes.
   ✔ Concluído — o ícone (livro com coração, fundo índigo) foi gerado para
   Android e o tema recebeu uma paleta com destaque dourado e tipografia mais
   legível. A imagem-base fica em assets/icon/app_icon.png.
5. Gerar o build final (otimizado em tamanho):
   powershell -ExecutionPolicy Bypass -File tool/build_release.ps1
   Isso gera o App Bundle (Google Play/Galaxy Store) e os APKs separados por
   arquitetura (instalação direta), com ofuscação e símbolos em build/symbols/.
   Baixando só a arquitetura certa, o APK cai de ~53 MB para ~21 MB sem perder
   nenhuma funcionalidade. Para iOS, a pasta `ios/` já está preparada: o build
   assinado roda em um Mac (`tool/build_ios.sh ipa`) ou é validado pelo
   workflow `iOS build` do GitHub Actions (compilação sem assinatura).

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

## 7. Configuração da doação via Pix (Etapa 3)

A aba Ajustes apresenta a chave Pix vinculada à conta Nubank. O botão principal
copia a chave e abre instruções grandes e numeradas, facilitando o uso por pessoas
idosas. O doador pode concluir a transferência no Nubank ou em qualquer banco.

A chave está definida na constante `_chavePix`, no arquivo `lib/main.dart`:

    static const String _chavePix = 'costamota@gmail.com';

Para alterar a conta no futuro, substitua somente esse valor e faça Hot Restart.
Antes de publicar, confirme no Nubank que a chave continua ativa e teste uma
transferência de valor baixo. O aplicativo também orienta o usuário a conferir o
nome do recebedor no banco antes de confirmar.

## Se algo der errado

- flutter doctor sempre mostra o que está faltando — leia a mensagem com calma,
  quase sempre ela já diz o comando exato para resolver.
- Erro comum: esquecer de rodar flutter pub get depois de mudar o pubspec.yaml.


