# Pipeline de pruebas de Panamericana

## Estado y alcance

El pipeline incorpora las herramientas del documento académico. Tener los jobs
configurados no acredita que las pruebas externas ya hayan sido ejecutadas.

- Se ejecutan flutter analyze, pruebas unitarias y de widgets con mocktail,
  Golden Tests del carrito y navegación, y cobertura LCOV.
- SonarQube consume el LCOV de la misma revisión y espera su Quality Gate.
- Un job independiente exige cobertura de líneas del 80% en el reporte global.
  No se han excluido vistas ni archivos de negocio para inflar la medición.
- ZAP web conserva su gate y sus excepciones documentadas abajo.
- Android, integración, Maestro, API autenticada, ZAP API y carga k6 están
  conectados a la validación completa. Requieren staging y datos sintéticos.
- Esfuerzo y perfilado en dispositivo físico tienen un workflow manual separado.

**La cobertura medida localmente tras ampliar la suite es 25.42%, por debajo del
80%. El nuevo gate bloqueará la integración. No reducir el umbral ni declarar
aprobadas las etapas sin ejecutarlas.**

## Orden de ejecución

1. Push o PR: análisis Flutter, unitarias, widgets, Golden Tests, LCOV.
2. En paralelo: gate de cobertura y SonarQube con el LCOV.
3. Tras los controles: contrato y autorización API; APK debug sin credenciales;
   emulador Android API 35; Maestro; integration_test.
4. ZAP API autenticada, con OpenAPI limitado a cuatro GET propios.
5. Carga k6 de 3 usuarios por 30 segundos.
6. Validación completa exige éxito de todos los jobs, incluidos ZAP web y staging.
7. Solo un push a develop aprobado crea/reutiliza el PR a release y activa auto-merge.
   El PR vuelve a validar el resultado. No hay despliegue a producción.

## 1. Crear un entorno de pruebas de pryBinaBack

La carpeta pryBinaBack contiene el código del backend. No es, por sí misma, un
entorno de staging. Hace falta desplegar una copia separada con URL HTTPS propia
(o proporcionar un servicio de CI equivalente) y una base MongoDB de pruebas.

- Configurar MONGO_URI de una base aislada; nunca usar la conexión de producción.
- Configurar PRIVATE_KEY y PUBLIC_KEY propios de pruebas (RS256) y el servicio
  de correo de prueba que requiera el backend. No copiar credenciales reales.
- Desactivar integraciones externas reales y usar sandbox cuando corresponda.
- Crear dos clientes sintéticos A/B con rol usuario; cada uno debe tener al menos
  un pedido propio, y A debe tener una dirección. Para perfilado se requieren
  al menos 20 productos. No copiar datos personales de clientes reales.
- La fixture de CI verifica por bcrypt la contraseña de las dos cuentas sintéticas,
  coloca códigos aleatorios de dos minutos exclusivamente en esas cuentas y llama
  al endpoint real /api/usuarios/verify-2fa. El backend firma sus sesiones normales.
- No se cambia producción, no se necesitan claves privadas en GitHub y no se
  envían correos. Esto NO prueba la entrega SMTP ni el login completo con correo.
- Cada job obtiene tokens nuevos, los enmascara y los usa por GITHUB_ENV. Al
  terminar los revoca; si el runner se pierde, caducan en una hora.
- Los workflows comparten concurrencia para no competir por los códigos A/B.

## 2. Valores de GitHub

En Settings → Secrets and variables → Actions del repo panamericana_flutter:

Repository variable:
- STAGING_API_URL: https://prybina-staging.onrender.com (sin /api).
  El workflow también incluye esta URL como valor predeterminado y el autenticador
  rechaza otros orígenes para evitar enviar credenciales a otro servicio.

Repository secrets:
- STAGING_MONGO_URI: conexión completa del clúster panamericana-staging, con la
  base /panamericana_staging. No guardarla en el repositorio. Conviene un usuario
  dedicado limitado a esa base; no usar credenciales con acceso a producción.
- STAGING_TEST_PASSWORD: contraseña vigente de cliente.a@example.test y
  cliente.b@example.test, tal como se configuró durante la carga sintética.
- SONAR_TOKEN, SONAR_HOST_URL y AUTO_MERGE_TOKEN conservan su configuración.
  Los antiguos STAGING_CLIENT_A_TOKEN/B_TOKEN ya no se utilizan.

No hace falta cambiar Render ni Atlas para este mecanismo: se usa la API y base
ya desplegadas. Los secretos deben configurarse antes de ejecutar el workflow.
Primero ejecutar manualmente Verificar autenticación de staging; el resultado
staging-auth-contract debe mostrar los 22 casos aprobados. La cadena completa
Android/ZAP/k6 sigue siendo independiente de este ensayo y puede detectar fallas.

Los archivos deben publicarse en GitHub antes de que aparezca la configuración.
Un workflow manual nuevo requiere estar en la rama predeterminada para aparecer
con su botón de ejecución. Mantener la revisión y protección de master.

## 3. Promoción develop → release → master

- develop: cambios de desarrollo y pruebas. No publica la aplicación.
- develop → release: el pipeline crea/reutiliza un PR y activa auto merge solo
  después de aprobar Validación completa. También se valida el PR.
- release → master: PR revisado y fusionado manualmente por el equipo, después
  de aprobar los checks. Ningún trabajo activa auto merge hacia master.
- El control Flujo de ramas rechaza PR directos de develop a master y PR a
  release que no procedan de develop del mismo repositorio.

Proteger release y master: PR obligatorio, rama actualizada, sin bypass para
administradores, sin force push ni eliminación. Exigir Pruebas Flutter,
SAST con SonarQube, DAST con OWASP ZAP, Validación completa y Flujo de ramas.
La cobertura de 80% sigue siendo obligatoria; un fallo impide promover.
Mantener Allow merge commits y Allow auto-merge a nivel repositorio para release.
No habilitar auto merge en los PR hacia master. La rama master no se renombra.

La prueba Android/API se puede ejecutar independientemente mientras se mejora la
cobertura; su aprobación no elimina el gate ni autoriza promover código fallido.
El entorno Render del backend sigue su propia rama master y repositorio: este
flujo corresponde al repositorio Flutter y no cambia su despliegue.

## 4. Evidencias

Artifacts: flutter-tests (LCOV, salida machine), coverage-summary, APK de pruebas
sin JWT, staging-api-contract, android-test-results, zap-api-staging, k6-normal.
Los manifiestos registran commit, fecha, intento, runner y versiones disponibles.
Los reportes API publican nombres de casos y estados; ZAP API publica metadatos
sin cuerpos, cabeceras ni tokens. Sus respuestas completas no se suben.

Registrar el caso, resultado, commit/PR y evidencia en Notion como pide el
 documento. No se publica automáticamente en Notion ni se necesita un token de
Notion para ejecutar las pruebas. Una falla de infraestructura se registra como
inconclusa y bloquea; no se convierte en prueba aprobada.

## 5. Qué prueban Android y Maestro

- Maestro: navegación de invitado al login y errores de formulario vacío/correo
  inválido; reporte JUnit y captura. Los selectores deben verificarse en el piloto.
- integration_test: API real de catálogo/perfil/direcciones/pedidos; restauración
  de una sesión cliente sintética; navegación a perfil e historial.
- Mocktail: flujo 2FA de dos pasos y rechazo de admin, almacenista, gerente y
  roles desconocidos, sin peticiones reales ni correos.
- Golden Tests: tres referencias con fuentes versionadas; carrito y navegación
  en anchos de 390 y 800 px. Nunca usar --update-goldens en CI para aprobar cambios.

La restauración de sesión no equivale a probar la entrega real del código 2FA.
Falta un adaptador al correo de staging para automatizar login positivo completo.
No hay compras reales, registros masivos, cambios de contraseñas ni pagos en vivo.
Las pruebas de compra de extremo a extremo necesitan proveedores sandbox y
fixtures adicionales antes de poder afirmar cobertura funcional completa.

## 6. ZAP API y k6

ZAP API usa la definición OpenAPI generada desde las rutas de pryBinaBack:
GET /api/productos, /api/usuarios/perfil, /api/usuarios/direcciones, /api/pedidos.
Ejecuta escaneo activo solo sobre esas consultas en staging; excluye endpoints
mutantes, login, PayPal y servicios externos. Verifica mediante historial de ZAP
que las tres rutas privadas respondieron 200. Expiración de sesión, cobertura de
rutas incompleta o reporte ausente bloquean. Cualquier riesgo bajo/medio/alto
bloquea: no hereda las excepciones del servidor web.

El contrato API adicional verifica 401 sin sesión o con token inválido, 403 al
acceder a administración, aislamiento de listas y rechazo del detalle de pedido
ajeno entre A y B. No escribe ni elimina datos.

k6 normal: 3 VUs, 30 s, p95 <1500 ms, errores <1%, checks 100%; ajustar los
objetivos mediante una decisión documentada tras medir staging.
Esfuerzo: workflow manual extended-tests.yml, 1-50 VUs (20 por defecto), subida,
mantenimiento y bajada, corte anticipado por errores y comprobación posterior
de recuperación. CPU, memoria y MongoDB requieren métricas del servidor aparte.

## 7. Rendimiento Android físico

Preparar un runner Linux dedicado con etiqueta android-physical, SDK Android,
Java y un único teléfono físico conectado por adb. El job falla si detecta
emulador. Ejecutar extended-tests.yml con suite android-profile.

flutter drive --profile captura el desplazamiento real del catálogo; guarda
Timeline y resumen. Exige p90 de build/raster <=16.67 ms. Un emulador no sirve
como evidencia de rendimiento físico. Esta etapa manual no se ejecuta en cada PR.

## 8. Comprobación local

flutter pub get
flutter analyze
flutter test --coverage
python .github/scripts/check_coverage.py coverage/lcov.info
python -m unittest discover -s .github/scripts -p "test_*.py"

El gate de cobertura debe fallar si el resultado es inferior al mínimo.
Para revisar cambios visuales intencionales, generar referencias localmente con
flutter test --update-goldens test/goldens y revisar las imágenes antes de subir.
No actualizar referencias automáticamente para ocultar diferencias inesperadas.

## Servidor web y excepciones históricas

serve_web.py configura CSP, protección de frames, nosniff, permisos, caché,
CORP y COOP con popups. Solo afecta al servidor de CI; el hosting necesita su
propia configuración. check_zap.py permite informativos y estas excepciones
únicamente en 127.0.0.1:8080, con riesgo máximo delimitado:
- 90004-2 (bajo): no exige aislamiento COEP completo de recursos externos.
- 90004-3 (bajo): same-origin-allow-popups para Google sin FedCM.
- 10055-6 (medio): estilos inline de Flutter, nunca scripts inline/unsafe-eval.
Todas las demás alertas bloquean. ZAP API no aplica estas excepciones.

## Referencias técnicas

https://docs.sonarsource.com/sonarqube-cloud/analyzing-source-code/test-coverage/dart-test-coverage
https://docs.flutter.dev/testing/integration-tests
https://docs.flutter.dev/cookbook/testing/integration/profiling
https://docs.maestro.dev/get-started/supported-platform/flutter
https://grafana.com/docs/k6/latest/using-k6/thresholds/
https://www.zaproxy.org/docs/docker/api-scan/
https://www.zaproxy.org/docs/docker/scan-hooks/
https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid

## 9. AAB Android con ofuscación

La rama feature/ofuscacion parte de develop. Su PR hacia develop ejecuta el
workflow security.yml, incluido el job «AAB Android ofuscado» tras Pruebas Flutter.
También se ejecuta en los push de las ramas configuradas y por ejecución manual.
Validación completa exige que este job termine correctamente, incluida la carga
de ambos artefactos. No cambia los gates de cobertura, seguridad ni staging.

El job ejecuta:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define="API_BASE_URL=$STAGING_API_URL"
```

Genera build/app/outputs/bundle/release/app-release.aab y build/symbols/*.symbols.
Comprueba que el AAB y al menos un archivo de símbolos no estén vacíos. Esto
valida la compilación ofuscada; no prueba su comportamiento en un dispositivo.
Las pruebas Android existentes siguen ejecutándose sobre su APK debug.

Los resultados se descargan desde Actions → ejecución → Artifacts, por separado:
android-aab-obfuscated-<sha>-<run_id>-<intento> y
android-symbols-<sha>-<run_id>-<intento>. Se conservan 30 días. No subir los
binarios ni símbolos a Git. Respaldar los símbolos de toda versión distribuida
en almacenamiento privado duradero antes de su expiración; deben corresponder
exactamente a esa compilación y arquitectura para interpretar sus errores.

Este AAB apunta a staging y usa la firma debug que actualmente configura
android/app/build.gradle.kts. Es un artefacto de validación, no una entrega para
Google Play. Antes de distribuir se debe configurar la clave de carga de
producción mediante secretos, elegir la API de destino y generar un nuevo AAB
con sus propios símbolos desde la revisión aprobada. Este job no publica ni
fusiona ramas; se mantiene el flujo develop → release → master existente.
# Diagnóstico de respuestas 421 del intermediario

La ejecución de diagnóstico `Diagnóstico ZAP API (sin promoción)` no reemplaza
la validación completa ni puede integrar ramas. Permite investigar la API sin
esperar la compilación del emulador. Usa las mismas sesiones sintéticas y las
revoca al terminar.

En staging se comprobó que ZAP altera el encabezado Host en ciertas sondas:
Cloudflare las rechaza con HTTP 421 y una página HTML. Al repetir el mismo GET
con el Host canónico, el backend devuelve 404 JSON. No es una respuesta HTML de
un endpoint válido de la API.

La política conserva la alerta 100001 en el reporte y únicamente considera
revisadas sus instancias de riesgo bajo si **todas** cumplen, en la misma
ejecución: origen exacto de staging, GET fuera de las rutas API declaradas,
Host diferente, respuesta 421 HTML de Cloudflare sin cabeceras del backend,
página explícita de solicitud mal dirigida y contraste con Host correcto que
responde 404 application/json. Se correlacionan por SHA-256 de la URI completa.
Si falta evidencia, una instancia no coincide, la severidad aumenta o aparece
otra alerta, el pipeline sigue bloqueando. El límite de repeticiones es diez
URI distintas y no se copian cookies, cuerpos ni cabeceras de autenticación.

`zap-api-staging` incluye `routing.json` y `policy.json` para auditar la decisión,
sin cuerpos ni direcciones sensibles. No se desactiva la regla en ZAP ni se
retira ninguna ruta protegida del escaneo.

### Arranque Android y versión de caché Flutter

El flujo invitado limpia los datos e inicia MainActivity con el ADB del SDK.
El inicio es asíncrono: Maestro exige que aparezca Panamericana en 60 segundos
y conserva todas las comprobaciones del carrito y de validación del formulario.
Un error al limpiar o iniciar, o una pantalla que no aparece, bloquea la etapa.

La alerta web 10096 se conserva en el reporte. Solo se acepta como falso positivo
de riesgo y confianza bajos cuando cada instancia es GET sin parámetro al archivo
local `/flutter_bootstrap.js` y su evidencia coincide exactamente con el valor
`serviceWorkerVersion` del archivo generado en esa misma compilación. Flutter
genera ese valor aleatorio para la caché; no es una fecha de usuario ni del servidor.
Sin el archivo, con otra ruta, valor, confianza o riesgo, la alerta sigue bloqueando.

