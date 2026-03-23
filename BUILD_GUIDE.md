# Guia de Build Multi-Platform

Seu projeto VendaFlow CRM agora suporta **iOS**, **Android**, **macOS**, **Windows**, e **Web**.

## Pré-requisitos

```bash
# Verificar ambiente
flutter doctor

# Instalar dependências
flutter pub get
```

## 🍎 iOS & iPad

### Requirements
- macOS com Xcode 14+
- CocoaPods
- Apple Developer Account (para deploy na App Store)

### Build & Run
```bash
# Executar em simulador iOS
flutter run -d "iPhone 15 Pro"

# Build para produção
flutter build ipa --release

# Build para simulador
flutter build ios --simulator --release
```

### Configurações importantes (ios/Runner/Info.plist)
- Bundle Identifier: `com.example.crmsaas`
- Deployment Target: iOS 12.0+
- iPad suporto: Já configurado (universal app)

---

## 🤖 Android

### Requirements
- Android Studio / SDK 
- SDK Level 21+ (min)SDK Level 33+ (target)
- JDK 11+

### Build & Run
```bash
# Executar em emulador/dispositivo
flutter run

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle --release
```

### Configurações importantes (android/app/build.gradle.kts)
- Min SDK Level: 21
- Target SDK Level: 33
- Package: `com.example.crm_saas`

---

## 🖥️ macOS

### Requirements
- macOS 10.15+
- Xcode 14+

### Build & Run
```bash
# Executar na máquina local
flutter run -d macos

# Build executável .app
flutter build macos --release

# Localização do app compilado
build/macos/Build/Products/Release/crm_saas.app
```

---

## 🪟 Windows

### Requirements
- Windows 10+ (build 19041+)
- Visual Studio 2022 (C++ build tools)
- CMake 3.20+

### Build & Run
```bash
# Executar na máquina local
flutter run -d windows

# Build executável .exe
flutter build windows --release

# Localização do app compilado
build\windows\runner\Release\crm_saas.exe
```

---

## 🌐 Web

### Build & Run
```bash
# Executar em navegador (localhost:3000)
flutter run -d chrome

# Build para produção (HTML + JS)
flutter build web --release

# Arquivos compilados em
build/web/
```
Serve como PWA - funciona offline!

---

## 📱 Certificação & Distribuição

### iOS App Store
1. Crie um App ID no [Apple Developer Portal](https://developer.apple.com)
2. Configure Signing Certificates
3. Build IPA:
```bash
flutter build ipa --release
```
4. Upload via Transporter

### Google Play
1. Crie uma chave de assinatura:
```bash
keytool -genkey -v -keystore ~/key.jwks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload-key
```
2. Configure em `android/app/build.gradle.kts`
3. Build App Bundle:
```bash
flutter build appbundle --release
```
4. Upload via Google Play Console

---

## 📊 Teste Multi-Plataforma

```bash
# Testes unitários
flutter test

# Testes widget
flutter test test/widget_test.dart

# Coverage
flutter test --coverage
```

---

## CI/CD Setup (GitHub Actions - em desenvolvimento)

1. Criar `.github/workflows/flutter.yml`
2. Build automático para todas plataformas
3. Deploy para stores (App Store, Play Store)

---

## Troubleshooting

**iOS: Codesign errors**
```bash
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
```

**Android: Gradle sync fails**
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd ..
```

**Windows: CMake error**
```bash
flutter clean && flutter pub get
```

**Web: CORS issues**
Configure backend CORS headers em `server.js`

---

## Próximos Passos
- [ ] Adicionar Firebase Analytics (todas plataformas)
- [ ] Implementar CI/CD com GitHub Actions
- [ ] Configurar App Signing para iOS/Android
- [ ] Otimizar performance para Web
