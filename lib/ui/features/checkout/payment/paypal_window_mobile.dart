import 'payment_window.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../data/network/api_client.dart';

class PaypalWindow implements PaymentWindow {
  PaypalWindow._(this._context);
  final BuildContext _context;
  VoidCallback? _dismiss;
  static PaypalWindow open(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw StateError(
        'El pago está disponible en Android, iOS y la versión web.',
      );
    }
    return PaypalWindow._(context);
  }

  @override
  String? get returnUrl => null;

  @override
  Future<bool> authorize(String url, String orderId) async {
    final approval = Uri.parse(url);
    if (approval.scheme != 'https' ||
        !['www.paypal.com', 'www.sandbox.paypal.com'].contains(approval.host)) {
      throw StateError('Enlace de PayPal inválido.');
    }
    if (!_context.mounted) return false;
    final api = Uri.parse(ApiClient.instance.dio.options.baseUrl);
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    final result = await showDialog<bool>(
      context: _context,
      barrierDismissible: false,
      builder: (ctx) {
        void finish(bool approved) {
          _dismiss = null;
          if (ctx.mounted) Navigator.of(ctx).pop(approved);
        }

        _dismiss = () => finish(false);
        controller.setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              final uri = Uri.tryParse(request.url);
              if (uri != null &&
                  uri.scheme == api.scheme &&
                  uri.host == api.host &&
                  uri.port == api.port) {
                if (uri.path == '/api/pagos/paypal/retorno') {
                  finish(uri.queryParameters['token'] == orderId);
                  return NavigationDecision.prevent;
                }
                if (uri.path == '/api/pagos/paypal/cancelado') {
                  finish(false);
                  return NavigationDecision.prevent;
                }
              }
              return NavigationDecision.navigate;
            },
          ),
        );
        controller.loadRequest(approval);
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Pago seguro con PayPal'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => finish(false),
              ),
            ),
            body: WebViewWidget(controller: controller),
          ),
        );
      },
    );
    _dismiss = null;
    return result == true;
  }

  @override
  void close() => _dismiss?.call();
}
