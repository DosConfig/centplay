# CentPlay CI/CD 파이프라인

## GitHub Actions 워크플로우

### PR 검증 (자동)
```yaml
# .github/workflows/pr-check.yml
name: PR Check
on: [pull_request]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.35.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test

  build-android:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --debug

  build-ios:
    runs-on: macos-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build ios --no-codesign
```

### 프로덕션 배포 (수동 트리거)
```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  workflow_dispatch:
    inputs:
      platform:
        type: choice
        options: [android, ios, both]
      track:
        type: choice
        options: [internal, beta, production]

jobs:
  deploy-android:
    if: inputs.platform == 'android' || inputs.platform == 'both'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter build appbundle --release
      - uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_KEY }}
          packageName: com.centplay.centplay
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: ${{ inputs.track }}
```

---

## Codemagic 설정 (대안)

```yaml
# codemagic.yaml
workflows:
  centplay-ios:
    name: iOS Build & Deploy
    environment:
      flutter: 3.35.x
      xcode: latest
      cocoapods: default
      groups:
        - app_store_credentials
    scripts:
      - name: Install dependencies
        script: flutter pub get
      - name: Analyze
        script: flutter analyze
      - name: Test
        script: flutter test
      - name: Build
        script: flutter build ipa --release
    artifacts:
      - build/ios/ipa/*.ipa
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true

  centplay-android:
    name: Android Build & Deploy
    environment:
      flutter: 3.35.x
      java: 17
      groups:
        - play_store_credentials
    scripts:
      - name: Install dependencies
        script: flutter pub get
      - name: Build
        script: flutter build appbundle --release
    artifacts:
      - build/app/outputs/bundle/release/*.aab
    publishing:
      google_play:
        credentials: ${{ secrets.PLAY_STORE_KEY }}
        track: internal
```

---

## 게임 호스팅 자동 배포

```yaml
# .github/workflows/deploy-games.yml
name: Deploy Games
on:
  push:
    paths:
      - 'webgl-games/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: ${{ secrets.GITHUB_TOKEN }}
          firebaseServiceAccount: ${{ secrets.FIREBASE_SA }}
          projectId: centplay-demo
          channelId: live
```

---

## 파이프라인 흐름

```
Feature Branch
    │
    ├─ Push → PR Check (analyze + test + build)
    │
    ├─ PR Merge → main
    │
    ├─ Tag v1.x.x → Deploy workflow (수동 트리거)
    │       ├─ Android: AAB → Play Store (internal → beta → production)
    │       └─ iOS: IPA → TestFlight → App Store
    │
    └─ webgl-games/ 변경 → Firebase Hosting 자동 배포
```

---

## 환경 변수 (Secrets)

| Secret | 용도 |
|--------|------|
| PLAY_STORE_KEY | Play Console 서비스 계정 JSON |
| APP_STORE_CONNECT_KEY | App Store Connect API Key |
| FIREBASE_SA | Firebase 서비스 계정 |
| KEYSTORE_BASE64 | Android 서명 키 (base64) |
| KEYSTORE_PASSWORD | 키스토어 비밀번호 |
