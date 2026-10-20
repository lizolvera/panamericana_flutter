# PayPal en Flutter

El carrito permite seleccionar una dirección guardada y preparar el pago. El servidor calcula el total y reserva inventario. Después se abre el enlace de autorización de PayPal en el navegador externo (otra pestaña en Flutter Web). Al terminar, el cliente vuelve a la aplicación y pulsa **Confirmar pago**. Solo la respuesta autenticada del backend marca el pedido como pagado y permite vaciar el carrito.

**Perfil → Mis compras** muestra los pedidos del usuario y permite retomar o cancelar pedidos pendientes. La cancelación libera la reserva de inventario en el servidor. Retomar un pedido no vacía el carrito actual, que podría contener productos distintos.

## Despliegue

1. Desplegar también los cambios de `pryBinaBack`: `approvalUrl` en creación/reintento y las páginas `/api/pagos/paypal/retorno` y `/api/pagos/paypal/cancelado`.
2. Mantener `PAYPAL_CLIENT_ID`, `PAYPAL_CLIENT_SECRET` y `PAYPAL_MODE` en el backend. Flutter no necesita secretos de PayPal.
3. Si cambia el dominio del backend, configurar `PUBLIC_API_URL` con su origen HTTPS sin ruta (por defecto `https://prybinaback.onrender.com`) y actualizar la base del `ApiClient` de Flutter.
4. Ejecutar `flutter pub get` y recompilar la app para incluir `url_launcher`.

El canal `flutter` añade URLs de retorno a las órdenes; las llamadas de Angular conservan su flujo con el SDK JavaScript.

## Validación manual en Sandbox

- Iniciar sesión como cliente, agregar productos, elegir una dirección y preparar el pago.
- Comprobar que el total mostrado es el devuelto por el servidor.
- Abrir PayPal, autorizar con una cuenta compradora Sandbox, regresar a la app y confirmar. Verificar pedido pagado y carrito vacío.
- Intentar confirmar antes de autorizar: debe mostrarse el error del servidor sin vaciar el carrito.
- Cerrar la app antes de pagar y recuperar el pedido desde Mis compras.
- Cancelar un pedido y verificar que se libera el inventario; comprobar también el vencimiento.
- Comprobar creación y reintento desde Angular después de desplegar el backend.

Las pruebas automatizadas no realizan cobros ni sustituyen una transacción Sandbox de extremo a extremo.

Referencias: [aprobación de órdenes PayPal](https://developer.paypal.com/sdk/orders/v2/definitions/order/), [url_launcher](https://pub.dev/packages/url_launcher).
