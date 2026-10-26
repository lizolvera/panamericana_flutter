#!/usr/bin/env bash
set -euo pipefail
mkdir -p reports/android reports/maestro
# El APK publicado se compila solo con URL; nunca contiene el token del test.
adb install -r build/app/outputs/flutter-apk/app-debug.apk
if ! "$HOME/.maestro/bin/maestro" test --format junit --output reports/maestro/results.xml .maestro/guest.yaml; then
  # Diagnóstico solo del flujo invitado, antes de cargar credenciales en la app.
  adb exec-out screencap -p > reports/maestro/failure-screen.png || true
  adb shell uiautomator dump /sdcard/guest-window.xml || true
  adb pull /sdcard/guest-window.xml reports/maestro/guest-window.xml || true
  adb logcat -d -s flutter:E AndroidRuntime:E > reports/maestro/guest-errors.log || true
  if [ -d "$HOME/.maestro/tests" ]; then
    cp -R "$HOME/.maestro/tests" reports/maestro/debug
  fi
  exit 1
fi
# Test instrumentado: archivo efímero de defines; no publicar sus binarios.
flutter test integration_test/staging_test.dart -d emulator-5554 --dart-define-from-file="$RUNNER_TEMP/staging-inputs.json"
printf '{"maestro":"passed","integration_test":"passed"}\n' > reports/android/result.json
