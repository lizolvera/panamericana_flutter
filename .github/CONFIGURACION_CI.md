# Validación de develop e integración automática a master

Cada push a develop ejecuta análisis estático y pruebas Flutter, SonarQube
(esperando el Quality Gate) y ZAP Baseline sobre la compilación web local.
Si los tres trabajos pasan, se crea o reutiliza un PR develop → master y se
activa auto-merge. El PR vuelve a validar el resultado de la integración.
Si un trabajo falla, master no se actualiza. El commit permanece en develop.
Los conflictos requieren resolución; nunca se fuerza ni se elimina una rama.

## Configuración previa en GitHub

1. Settings → General → Pull Requests: habilitar Allow auto-merge y
   Allow merge commits. Mantener develop después de integrar.
2. Settings → Branches: crear una regla clásica de protección para master.
   - Require a pull request before merging.
   - Desactivar Require approvals si no se desea aprobación humana.
   - Require status checks to pass before merging, con estos checks:
     `Pruebas Flutter`, `SAST con SonarQube`, `DAST con OWASP ZAP`.
   - Require branches to be up to date before merging.
   - Do not allow bypassing the above settings, incluyendo administradores.
   - No conceder bypass al usuario o aplicación de automatización.
   - No exigir historial lineal, porque se utiliza merge commit.
3. Crear el secreto AUTO_MERGE_TOKEN: token de una cuenta de automatización
   con acceso solo a este repositorio. Para un PAT de permisos específicos:
   Contents: Read and write; Pull requests: Read and write;
   Administration: Read-only (para comprobar la protección de master).
   Si develop modifica workflows, puede requerir Workflows: Read and write.
   No pegar el token en archivos. Definir vencimiento y renovarlo al expirar.
   El workflow falla sin la protección clásica indicada; una configuración
   basada solo en rulesets requiere adaptar esa comprobación.

## Configuración previa en SonarQube Cloud

1. Crear/importar el proyecto y desactivar Automatic Analysis para usar CI.
2. Configurar SONAR_TOKEN y SONAR_HOST_URL como secretos del repositorio.
3. Crear sonar-project.properties en la raíz, junto a pubspec.yaml:

   ```properties
   sonar.projectKey=CLAVE_REAL_DEL_PROYECTO
   sonar.organization=aplicacion
   sonar.sources=lib
   sonar.tests=test
   sonar.sourceEncoding=UTF-8
   sonar.exclusions=**/*.g.dart,**/*.freezed.dart
   ```

4. Comprobar que el plan admite análisis de develop y de pull requests.
   El Quality Gate debe estar configurado con los criterios que se desean
   exigir; un análisis ejecutado no equivale por sí solo a una aprobación.

## Primera ejecución

Subir el workflow y la configuración del proyecto a develop. Ejecutar una
primera validación para que GitHub detecte los nombres de checks; configurar
después la protección y repetir la ejecución si falló la etapa de promoción.
No publicar credenciales en commits.

ZAP Baseline revisa la web servida en el runner. No valida por sí solo flujos
autenticados, pagos reales o la seguridad del backend remoto. Actualizar master
tampoco equivale a desplegar: el despliegue depende de su propia configuración.

## Servidor y clasificación del reporte de ZAP

El escaneo usa `.github/scripts/serve_web.py`, con CSP, protección contra
clickjacking, nosniff, política de permisos, caché desactivada y sin versiones
del intérprete. Las cabeceras también se envían en respuestas de error. Los
directorios sin index no se listan. Estas medidas solo se aplican al servidor
temporal; el hosting real necesita su propia configuración equivalente.

ZAP mantiene `fail_action: true`. `-I` permite terminar ante advertencias,
pero inmediatamente después `check_zap.py` revisa el JSON y falla con cualquier
riesgo bajo, medio o alto no contemplado expresamente. Un reporte ausente o
inválido también bloquea. Los informativos se imprimen sin bloquear.

Excepciones limitadas a URLs de `127.0.0.1:8080`:

- `90004-2`, riesgo máximo bajo: no se exige COEP require-corp porque los
  recursos externos deben conceder CORS/CORP; no se declara aislamiento completo.
- `90004-3`, riesgo máximo bajo: se usa COOP same-origin-allow-popups para
  mantener la comunicación del popup de Google sin FedCM.
- `10055-6`, riesgo máximo medio: estilos inline generados por Flutter.
  No se admiten scripts inline ni unsafe-eval. Otras debilidades de CSP bloquean.

Referencias:
https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid
https://www.zaproxy.org/docs/docker/baseline-scan/
https://www.zaproxy.org/docs/alerts/10055-6/

Después de modificar CSP, comprobar en navegador que se rendericen Flutter,
catálogo, imágenes y acceso con Google. La prueba HTTP verifica las cabeceras,
no la ejecución del código Dart ni OAuth. Si se agregan proveedores o dominios,
revisar las directivas necesarias sin recurrir a comodines globales. La versión
actual no está verificada con un navegador ni con ZAP completo localmente;
la siguiente ejecución de GitHub debe confirmar el resultado del escaneo.
