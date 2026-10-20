import 'dart:js_interop';

import 'package:flutter/material.dart';

@JS('panamericanaPaypal.open')
external JSString _open();
@JS('panamericanaPaypal.returnUrl')
external JSString _returnUrl(JSString state);
@JS('panamericanaPaypal.authorize')
external JSPromise<JSBoolean> _authorize(
  JSString state,
  JSString url,
  JSString orderId,
);
@JS('panamericanaPaypal.close')
external void _close(JSString state);

class PaypalWindow {
  PaypalWindow._(this._state);
  final JSString _state;
  // Se abre antes de cualquier await para evitar el bloqueo de ventanas.
  static PaypalWindow open(BuildContext context) => PaypalWindow._(_open());
  String get returnUrl => _returnUrl(_state).toDart;
  Future<bool> authorize(String url, String orderId) async =>
      (await _authorize(_state, url.toJS, orderId.toJS).toDart).toDart;
  void close() => _close(_state);
}
