# Publicação (T037 / T038)

Este documento é o passo a passo para gerar o primeiro **App Bundle** de
lançamento. As tarefas T037 e T038 dependem de recursos externos e ficam
**bloqueadas** até que eles existam — este roteiro deixa o caminho pronto.

## Pré-requisitos (bloqueadores externos)

1. **Conta AdMob** com um app registrado → IDs de anúncio de produção
   (`ca-app-pub-...`).
2. **Android SDK** instalado (para `flutter build appbundle`).
3. **Keystore de assinatura** (gerado com `keytool`).

## 1. Trocar os IDs de anúncio de teste (T037)

- `lib/widgets/banner_anuncio.dart` → `_bannerAndroid` / `_bannerIos`
  (substituir os IDs `ca-app-pub-3940256099942544/...` pelos reais).
- `android/app/src/main/AndroidManifest.xml` → `APPLICATION_ID` (App ID AdMob).
- Conferir com `test/config_negocio_test.dart` (B8): os IDs de teste passam a
  ser **bloqueados em release** pela função `erroIdAnuncioEmProducao`.

## 2. Application ID e assinatura (T038)

1. Escolher o **Application ID** definitivo (ex.: `br.com.seuprojeto.bibliadiaria`)
   e trocar em `android/app/build.gradle.kts` (`applicationId`).
2. Gerar o keystore (fora do repositório):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```
3. Criar `android/key.properties` (a partir de `android/key.properties.example`),
   apontando para o keystore. **Nunca commitar** `key.properties` nem o `.jks`.
4. Gerar o App Bundle:
   ```bash
   flutter build appbundle --release
   ```
   O artefato sai em `build/app/outputs/bundle/release/app-release.aab`.
5. Conferir que nenhum ID de teste (`ca-app-pub-3940…`) está no artefato (B8).

> A assinatura de release já está configurada em `android/app/build.gradle.kts`
> para ler `key.properties` (com fallback para a chave de debug quando o arquivo
> não existe — útil no desenvolvimento local).

## 3. iOS (App Store / TestFlight) — requer macOS

O projeto iOS já está gerado e configurado na pasta `ios/`. O código Dart é
multiplataforma e reconhece iOS automaticamente (`lib/platform_support.dart` e
`lib/widgets/banner_anuncio.dart`). O que falta é apenas o **build assinado**,
que **só roda em macOS** (Apple não permite compilar/assinar iOS no Windows).

### Pré-requisitos (bloqueadores externos)

1. **Apple Developer Program** (US$ 99/ano) — necessário para distribuir no
   App Store/TestFlight. Conta gratuita só instala em aparelho próprio por 7 dias.
2. **Um Mac com Xcode** — ou o runner macOS do GitHub Actions (o workflow
   `iOS build` em `.github/workflows/ios.yml` compila sem assinar para validar).

### Configurações já prontas

- **Bundle ID**: `br.com.costamota.bibliaDiaria` (em
  `ios/Runner.xcodeproj/project.pbxproj`). Troque pelo seu domínio definitivo,
  se necessário, e registre esse mesmo ID no Apple Developer Portal.
- **AdMob**: `ios/Runner/Info.plist` já tem `GADApplicationIdentifier` (App ID
  de TESTE `ca-app-pub-3940256099942544~1458002511`), `SKAdNetworkItems`
  (identificador do Google) e `NSUserTrackingUsageDescription`. Troque o App ID
  de teste pelo real antes de publicar.
- **Ícones**: já gerados; para regenerar após trocar a imagem, rode
  `dart run flutter_launcher_icons` (o `pubspec.yaml` já tem `ios: true`).

### Como gerar o IPA assinado (no Mac)

```bash
bash tool/build_ios.sh ipa
# ou diretamente:
flutter build ipa --release --obfuscate --split-debug-info=build/symbols
```

Depois, abra `ios/Runner.xcworkspace` no Xcode, selecione a **Team** de
assinatura, e use **Product > Archive** para enviar ao App Store Connect.

### Validação sem assinatura (CI ou Mac)

```bash
bash tool/build_ios.sh verificar
# ou:
flutter build ios --release --no-codesign
```

Isso compila e linka o app (`build/ios/iphoneos/Runner.app`), provando que o
projeto iOS está íntegro — é o que o workflow `iOS build` do GitHub Actions faz
automaticamente a cada push.

> Antes de submeter à App Store, revise a **privacidade** (questionário de
> dados do App Store Connect e `PrivacyInfo.xcprivacy`) e confirme que os IDs de
> anúncio reais estão em `Info.plist` e `lib/widgets/banner_anuncio.dart`.
