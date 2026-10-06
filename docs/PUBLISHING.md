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
