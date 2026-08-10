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

Abra o arquivo assets/data/biblia_exemplo.json. Ele é só texto — você pode
adicionar livros, capítulos e versículos seguindo o mesmo formato que já está lá.
Depois de editar, salve o arquivo e rode flutter pub get de novo (ou aperte
"Hot Restart" no VS Code, ícone de raio com um R).

Importante: este arquivo de exemplo tem só 2 livros. Você vai precisar do
texto completo da Bíblia em português (domínio público, como Almeida Corrigida
Fiel ou João Ferreira de Almeida) organizado nesse mesmo formato JSON antes de
publicar de verdade.

## 5. Próximos passos (nesta ordem sugerida)

1. Substituir biblia_exemplo.json pelo texto bíblico completo.
2. Criar conta no Google AdMob e seguir a documentação oficial do pacote
google_mobile_ads para inserir um banner.
3. Adicionar o pacote url_launcher para o botão "Apoiar o projeto" abrir seu
link de doação de verdade (Pix, PayPal, Buy Me a Coffee etc.).
4. Criar o ícone do app e ajustar cores/fontes.
5. Gerar o build final:
   flutter build appbundle   (para Google Play e Galaxy Store)
   flutter build ipa         (para App Store — precisa de Mac)

## Se algo der errado

- flutter doctor sempre mostra o que está faltando — leia a mensagem com calma,
  quase sempre ela já diz o comando exato para resolver.
- Erro comum: esquecer de rodar flutter pub get depois de mudar o pubspec.yaml.
