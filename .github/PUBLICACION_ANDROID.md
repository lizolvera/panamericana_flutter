# Publicación Android: Panamericana Clientes

Paquete: `com.panamericana.panamericana_flutter`.
API de producción confirmada: `https://prybinaback.onrender.com`.

## Activación

Integrar feature/disparador → develop → release → master por los PR habituales.
Git no permite tener develop y develop/disparador a la vez; usar feature/disparador.
El workflow publicar-android.yml espera una ejecución exitosa del workflow
Seguridad Flutter (SAST y DAST) por push a master. Compila exactamente ese commit.
Publica automáticamente el AAB firmado en la pista internal (prueba interna) de Play Console.
No fusiona ramas. Conserva el AAB de staging existente y el respaldo de publicación.

También permite Actions → Preparar AAB para Google Play → Run workflow → master.
El botón aparece cuando el archivo llega a la rama predeterminada; la ejecución
manual exige una validación exitosa por push a master del mismo commit.

## Clave y secretos (responsable del repositorio)

Antes de generar otra clave, comprobar si la app ya tiene una clave de carga.
Si existe, utilizar esa. Si no existe, crearla fuera del repositorio, por ejemplo:

```bash
keytool -genkeypair -v -keystore "$HOME/panamericana-upload.jks" \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

El comando solicita las contraseñas de forma interactiva. Respaldar el archivo,
el alias y las contraseñas en almacenamiento privado de la empresa.
No adjuntarlos a commits, PR, capturas ni mensajes.

En GitHub → Settings → Secrets and variables → Actions → Repository secrets:

| Secreto | Contenido |
| --- | --- |
| ANDROID_KEYSTORE_BASE64 | Contenido completo del JKS codificado en base64, sin saltos |
| ANDROID_KEYSTORE_PASSWORD | Contraseña del almacén JKS |
| ANDROID_KEY_ALIAS | Alias de la clave, por ejemplo upload |
| ANDROID_KEY_PASSWORD | Contraseña de esa clave |

Para generar el archivo base64 local en Linux:

```bash
umask 077
base64 -w 0 "$HOME/panamericana-upload.jks" > "$HOME/panamericana-upload.base64"
```

Copiar su contenido únicamente al secreto correspondiente. Base64 no cifra la
clave: proteger también ese archivo. No se crea ninguna clave automáticamente.
La compilación de producción falla si faltan secretos; Gradle exige la firma de
carga cuando REQUIRE_UPLOAD_SIGNING=true. Sin esas variables, staging conserva
su firma debug. No configurar secretos de publicación en el workflow de PR.

## Credencial de publicación automática

Configurar el secreto GOOGLE_PLAY_SERVICE_ACCOUNT_JSON con el JSON completo de
la cuenta de servicio. Habilitar androidpublisher.googleapis.com en su proyecto.
En Play Console, dar a esa cuenta acceso solo a Panamericana Clientes con lectura
de información de la app y lanzamiento a segmentos de pruebas. No requiere rol
IAM de editor/administrador ni permisos de producción o financieros.
La primera versión ya debe existir en Play Console (se subió manualmente).
La credencial se valida antes de compilar y se elimina del runner al terminar.
Nunca se incluye en artefactos. Una subida fallida deja el workflow en rojo, pero
el AAB y símbolos ya se habrán guardado para diagnóstico.

## Publicación y respaldo

Tras completar el workflow, descargar el artefacto google-play-… desde Actions.
La subida y lanzamiento en prueba interna son automáticos; revisar el resultado
del paso de publicación y la nueva versión en Play Console. No descargar ni subir
el AAB manualmente en el flujo normal. Play puede aplicar procesamiento/revisión. Guardar permanentemente los símbolos Dart, mapping.txt de R8
y compilacion.txt de cada versión distribuida (el artefacto expira en 30 días).
Verificar catálogo, sesión, pedidos y acceso con Google en una instalación desde
Play. Si se utiliza Google Sign-In, revisar la configuración OAuth Android para
el paquete y el certificado de firma que Google usa para distribuir la app.

El versionCode usa github.run_number * 1000 + github.run_attempt (primer intento
de la ejecución 2: 2001), superior a la primera versión manual con código 1.
Cada intento recibe un código nuevo. No reiniciar la numeración del workflow ni
subir manualmente códigos superiores sin actualizar esta estrategia. versionName
permanece en pubspec.yaml; aumentarlo cuando cambie la versión comercial.
Las notas de versión están en distribution/whatsnew/whatsnew-es-419.
El destino está fijado a internal: no publica en producción ni en prueba cerrada.
Un reintento de una ejecución exitosa puede publicar otra versión del mismo código
fuente; utilizar reintentos solo para recuperar fallos.

Referencias:
- https://docs.flutter.dev/deployment/android
- https://support.google.com/googleplay/android-developer/answer/9842756
