# Publicación Android: Panamericana Clientes

Paquete: `com.panamericana.panamericana_flutter`.
API de producción confirmada: `https://prybinaback.onrender.com`.

## Activación

Integrar feature/disparador → develop → release → master por los PR habituales.
Git no permite tener develop y develop/disparador a la vez; usar feature/disparador.
El workflow publicar-android.yml espera una ejecución exitosa del workflow
Seguridad Flutter (SAST y DAST) por push a master. Compila exactamente ese commit.
No fusiona ramas ni sube archivos a Play Console. Conserva el AAB de staging existente.

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

## Descarga y primera prueba

Tras completar el workflow, descargar el artefacto google-play-… desde Actions.
Subir app-release.aab a la pista de pruebas internas de Google Play y completar
Play App Signing. Guardar permanentemente los símbolos Dart, mapping.txt de R8
y compilacion.txt de cada versión distribuida (el artefacto expira en 30 días).
Verificar catálogo, sesión, pedidos y acceso con Google en una instalación desde
Play. Si se utiliza Google Sign-In, revisar la configuración OAuth Android para
el paquete y el certificado de firma que Google usa para distribuir la app.

El versionCode usa github.run_number de este workflow. Cada ejecución nueva lo
incrementa; reintentar una ejecución conserva el mismo código. No subir dos AAB
con el mismo código. Si ya existe una entrega con un código igual o mayor, ajustar
la estrategia de versionado antes de subir. versionName permanece en pubspec.yaml.

Referencias:
- https://docs.flutter.dev/deployment/android
- https://support.google.com/googleplay/android-developer/answer/9842756
