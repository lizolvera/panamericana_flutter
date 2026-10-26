#!/usr/bin/env bash
set -euo pipefail
mkdir -p reports/android reports/maestro
# El APK publicado se compila solo con URL; nunca contiene el token del test.
adb install -r build/app/outputs/flutter-apk/app-debug.apk
"$HOME/.maestro/bin/maestro" test --format junit --output reports/maestro/results.xml .maestro/guest.yaml
# Test instrumentado: archivo efímero de defines; no publicar sus binarios.
flutter test integration_test/staging_test.dart -d emulator-5554 --dart-define-from-file="$RUNNER_TEMP/staging-inputs.json"
printf '{"maestro":"passed","integration_test":"passed"}\n' > reports/android/result.json
