# Pruebas automatizadas de Flutter

Ejecutar desde la raíz del proyecto:

```sh
flutter analyze --fatal-infos
flutter test --coverage --machine > test-results.json
python .github/scripts/check_coverage.py coverage/lcov.info
```

El control de cobertura conserva el mínimo de 80 % y no excluye pantallas para
alcanzarlo. La cobertura de líneas indica código ejecutado por las pruebas; no
garantiza que todos los escenarios o combinaciones estén comprobados.

La batería incluye pruebas de modelos, repositorios, estados de autenticación y
catálogo, formularios de perfil, recuperación de cuenta, direcciones, navegación,
cantidades del carrito, detalle de productos, checkout y comparaciones visuales.
Los escenarios verifican tanto resultados correctos como rechazos, campos
obligatorios, estados vacíos y recuperación ante errores.

`support/fixture_api.dart` intercepta las solicitudes de Dio en memoria y devuelve
datos sintéticos. Así se prueban los repositorios y las interacciones de pantalla
sin contactar Atlas, Render ni enviar correos o pagos. El adaptador original se
restaura después de cada prueba. Estas pruebas complementan las comprobaciones
de API y autenticación contra staging; no las sustituyen.

Las pruebas visuales mantienen referencias separadas para Linux y Windows debido
a sus diferencias de rasterización. No se actualizan imágenes automáticamente
durante la validación.

Resultado local del 26 de octubre de 2026: 72 pruebas aprobadas y cobertura de
2,874 de 3,377 líneas instrumentadas (85.11 %). El resultado vigente de cada
commit debe consultarse en los artefactos de GitHub Actions.
