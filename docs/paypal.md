# PayPal en Flutter

Después de revisar la dirección y el total, el botón **Confirmar pago** abre PayPal y confirma el cobro automáticamente al terminar la autorización. No hay un botón separado para abrir PayPal ni es necesario regresar y confirmar manualmente.

En Flutter Web se abre una ventana emergente desde el clic del usuario. PayPal regresa a `paypal_return.html`, un archivo estático del mismo sitio de Flutter. Esa página avisa a la aplicación, que cierra la ventana y llama al endpoint autenticado de captura. Se validan el origen, la ventana emisora, un estado aleatorio y el identificador de la orden. Solo el backend puede confirmar que el cobro fue aprobado.

En Android/iOS se muestra una ventana de pago dentro de la app. Se intercepta la navegación de retorno antes de cargar Render y se confirma el cobro. El flujo de ventana está implementado para web, Android e iOS.

**Perfil → Mis compras** permite retomar o cancelar pedidos pendientes. La cancelación libera la reserva de inventario en el servidor. Retomar un pedido no vacía el carrito actual, que podría contener productos distintos. Si falla la captura después de la autorización, el mismo botón vuelve a intentar confirmar esa orden sin abrir otro pago mientras la vista siga abierta.

## Despliegue

1. Desplegar los cambios de `pryBinaBack`, incluidos `paypalRetornoService.js`, el controlador y el servicio de PayPal.
2. Para Flutter Web en producción, configurar en el backend los orígenes HTTPS permitidos, separados por comas:

   ```env
   PAYPAL_FLUTTER_ORIGINS=https://tu-sitio-flutter.example
   ```

   Usar el dominio donde se abre Flutter, sin ruta ni barra final. Se admite desarrollo en `localhost` y `127.0.0.1` con cualquier puerto. Si el origen no está permitido, el servidor muestra un error antes de crear una nueva orden PayPal.
3. Mantener `PAYPAL_CLIENT_ID`, `PAYPAL_CLIENT_SECRET` y `PAYPAL_MODE` en el backend. Flutter no necesita secretos de PayPal.
4. Para móvil, `PUBLIC_API_URL` es el origen HTTPS del backend, por defecto `https://prybinaback.onrender.com`. Si cambia, actualizar también `ApiClient`.
5. Ejecutar `flutter pub get`, recompilar y publicar Flutter junto con `web/paypal_popup.js` y `web/paypal_return.html`. El hosting debe servir estos archivos como archivos estáticos, también si la app se publica en una subruta. No deben redirigirse al backend.

El flujo SDK de Angular conserva su comportamiento. Las páginas de retorno antiguas de la API permanecen por compatibilidad con versiones anteriores.

## Validación en Sandbox

- Iniciar sesión, agregar productos, seleccionar dirección y revisar el total devuelto por el servidor.
- Pulsar **Confirmar pago** y autorizar con una cuenta compradora Sandbox: debe cerrarse la ventana, confirmarse el pedido y vaciarse el carrito del pedido nuevo.
- Cerrar o cancelar la ventana: el pedido debe permanecer pendiente, sin captura ni vaciado del carrito.
- Bloquear ventanas emergentes: se debe indicar que hay que permitirlas y debe ser posible reintentar.
- Desconectar la red al confirmar: el pago no se muestra como exitoso sin respuesta aprobada del backend.
- Recuperar un pedido desde Mis compras, cancelar y comprobar la liberación de inventario.
- Validar Android/iOS en dispositivo y comprobar Angular después del despliegue.

Pruebas locales: `flutter analyze`, `flutter test`, `flutter build web`; para validar los retornos del backend: `node --test tests/paypalRetornoService.test.js` desde `pryBinaBack`.

Las pruebas automatizadas no realizan cobros ni sustituyen una transacción Sandbox de extremo a extremo.

Referencia: [flujo de aprobación y captura de PayPal](https://developer.paypal.com/api/rest/integration/orders-api).
