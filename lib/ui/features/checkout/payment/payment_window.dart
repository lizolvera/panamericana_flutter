/// Autorización de PayPal antes de solicitar la captura al servidor.
abstract interface class PaymentWindow {
  String? get returnUrl;
  Future<bool> authorize(String url, String orderId);
  void close();
}
