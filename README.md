# panamericana_flutter

Aplicación Flutter de Distribuidora Panamericana.

## Pipeline de seguridad

El workflow `.github/workflows/security.yml` ejecuta únicamente SAST con
SonarQube y DAST con OWASP ZAP. Se activa con pushes y pull requests hacia
`main` o `master`, y manualmente desde GitHub Actions. No incluye Snyk ni SCA.

### Configuración de SonarQube

1. Crear en SonarQube el proyecto con clave `panamericana-flutter`, o ajustar
   `sonar.projectKey` en `sonar-project.properties` a la clave existente.
2. En GitHub, ir a **Settings > Secrets and variables > Actions** y crear:
   - `SONAR_TOKEN`: token con permiso de análisis para ese proyecto.
   - `SONAR_HOST_URL`: URL del servidor SonarQube accesible desde el runner.
     `localhost` apuntaría al runner de GitHub, no al equipo donde corre SonarQube.
3. Verificar que la versión y edición de SonarQube tengan soporte para Dart
   compatible con el SDK 3.13.4 del proyecto. El análisis de ramas y pull requests
   también requiere soporte en la edición instalada.

El pipeline usa Flutter 3.47.5 stable (Dart 3.13.4), instala las dependencias
respetando `pubspec.lock` y compila web antes de analizar `lib/` y `web/`.
Clasifica `test/` como código de pruebas; no ejecuta pruebas unitarias ni publica
cobertura en esta etapa. Espera el Quality Gate: si no se aprueba, falla el job.
Los pull requests desde forks omiten SonarQube porque no reciben los secretos;
ZAP se ejecuta de todos modos. No guardar tokens en archivos versionados.

### Alcance de OWASP ZAP

El job DAST compila la versión web y la sirve temporalmente en
`http://127.0.0.1:8080/` dentro del runner. ZAP Baseline rastrea ese sitio y realiza
análisis pasivo, sin credenciales ni escaneo activo. No requiere una URL pública
ni despliega la aplicación. Se ejecuta independientemente del resultado SAST.

Este análisis cubre los recursos web accesibles al rastreador; su cobertura de
pantallas Flutter renderizadas mediante JavaScript/canvas es limitada. No analiza
el binario Android/iOS ni los flujos autenticados ni sustituye un escaneo de la
API. Los encabezados y hallazgos corresponden al servidor HTTP temporal, no a un
hosting de producción.

Las alertas de ZAP (incluidas las advertencias) y los errores del escaneo hacen
fallar el job para que puedan revisarse. No se silencian reglas inicialmente.
Descargar los reportes HTML, JSON y Markdown desde **Actions > ejecución >
Artifacts**, en `zap-flutter-reports` (conservados 14 días). La acción de ZAP
también adjunta su propio artefacto `zap-flutter-web` cuando completa el proceso.
No se crean issues automáticamente.

Referencias: [SonarQube para Dart](https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/languages/dart)
y [ZAP Baseline](https://www.zaproxy.org/docs/docker/baseline-scan/).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
