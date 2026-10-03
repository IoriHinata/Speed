# Обитель скорости / Speed Haven

Offline-first MVP мобильной игры с коллекцией автомобилей. Интерфейс написан на HTML/CSS/ES modules и упаковывается в нативный Android `WebView` shell без облачных runtime-зависимостей.

## Локальный запуск веб-версии

```bash
npm run dev
# http://localhost:4173
```

## Сборка APK локально

Требования: Node.js 24+, JDK 17, Android SDK Platform 35 и Gradle 8.9+.

```bash
npm test
npm run check
npm run android:apk
```

APK появится по пути:

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

`android:apk` перед Gradle-сборкой копирует `index.html` и `src/` в Android assets. Это гарантирует, что APK содержит тот же offline bundle, что и веб-версия.

## Сборка APK на GitHub

Workflow [Build Android APK](.github/workflows/android-apk.yml) запускается на каждом push, pull request и вручную через **Actions → Build Android APK → Run workflow**. Он:

1. запускает unit-тесты и проверку JS;
2. подготавливает Android assets;
3. использует Node.js 24 и актуальные Node 24-compatible actions, устанавливает JDK 17, Android Platform 35 и Gradle 8.9;
4. собирает `:app:assembleDebug`;
5. публикует файл в **Artifacts** с именем `speed-haven-debug-apk`.

Скачайте artifact после успешного запуска workflow и установите `app-debug.apk` на Android-устройство. Для установки неизвестных приложений может потребоваться разрешение в настройках устройства.

## Android shell

Нативный слой расположен в [`android/app`](android/app): `MainActivity` включает JavaScript и DOM storage, открывает offline bundle по `file:///android_asset/index.html` и предоставляет системный выбор фотографии для camera/import flow. Игровая бизнес-логика остаётся в `src/` и не дублируется в Java.
