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
