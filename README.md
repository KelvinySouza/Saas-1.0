# Overall Management

Um sistema CRM SaaS multi-tenant construído com Flutter para suporte multiplataforma (iOS, Android, Web, macOS, Windows).

## Downloads

### Aplicativos Móveis
Para instalar sem Play Store/App Store, construa os APKs/IPAs localmente:

- **Android APK**: Execute `flutter build apk` e instale o arquivo `build/app/outputs/flutter-apk/app-release.apk` no dispositivo.
- **iOS IPA**: Execute `flutter build ipa` (requer Xcode e conta Apple Developer) e instale via TestFlight ou sideloading.

### Aplicativos Desktop
Construa executáveis para instalação direta:

- **macOS**: Execute `flutter build macos` e distribua a pasta `build/macos/Build/Products/Release/Overall Management.app`.
- **Windows**: Execute `flutter build windows` e distribua a pasta `build/windows/runner/Release`.

### Aplicativo Web
Acesse a versão web em https://kelvinysouza.github.io/Saas-1.0/ (ative GitHub Pages no repositório para /web).

**Para funcionar completamente:**
- Hospede o backend (server.js) em Vercel/Heroku/etc.
- Configure `OPENAI_KEY` nas variáveis de ambiente do host.
- Atualize `ai_assistant_screen.dart` com a URL do backend hospedado (linha `_apiBaseUrl`).

## Assistente de IA

- O app inclui um assistente IA integrado (dashboard > configurações > Assistente IA).
- O backend consome OpenAI via endpoint `POST /api/ai`.
- Configure `OPENAI_KEY` no `.env` (veja SETUP.md).
- Para web, hospede o backend e atualize a URL em `ai_assistant_screen.dart`.

## Deploy do Backend

Para hospedar o backend Node.js:

### Vercel (Recomendado para web)
1. Instale Vercel CLI: `npm i -g vercel`
2. `vercel login`
3. Na raiz do projeto: `vercel`
4. Configure variáveis: SUPABASE_URL, SUPABASE_SERVICE_KEY, JWT_SECRET, OPENAI_KEY
5. Deploy: `vercel --prod`
6. Copie a URL gerada e atualize no Flutter (linha `_apiBaseUrl` em `ai_assistant_screen.dart`)

### Heroku
1. Crie app no Heroku Dashboard
2. `heroku git:remote -a seu-app-name`
3. Configure vars: `heroku config:set SUPABASE_URL=...` etc.
4. `git push heroku main`

## Documentação

- [Guia de Configuração](SETUP.md)
- [Guia de Build](BUILD_GUIDE.md)
- [Plano de Desenvolvimento](PLANO_DESENVOLVIMENTO.md)
- [Esquema do Banco de Dados](schema.sql)

## Começando

Consulte [SETUP.md](SETUP.md) para instruções de configuração.

Para desenvolvimento Flutter, veja a [documentação oficial](https://docs.flutter.dev/).

## Recursos

- [Aprenda Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Escreva seu primeiro app Flutter](https://docs.flutter.dev/get-started/codelab)
- [Recursos de aprendizado Flutter](https://docs.flutter.dev/reference/learning-resources)
