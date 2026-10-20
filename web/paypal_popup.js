(() => {
  'use strict';
  const sessions = new Map();
  window.panamericanaPaypal = {
    open() {
      const state = crypto.randomUUID();
      const popup = window.open('about:blank', `paypal-${state}`,
        'popup=yes,width=500,height=720,resizable=yes,scrollbars=yes');
      if (!popup) throw new Error('Permite las ventanas emergentes para pagar con PayPal.');
      popup.document.title = 'PayPal';
      popup.document.body.textContent = 'Preparando pago seguro con PayPal…';
      sessions.set(state, { popup });
      return state;
    },
    returnUrl(state) {
      if (!sessions.has(state)) throw new Error('Ventana de pago no disponible.');
      const url = new URL('paypal_return.html', document.baseURI);
      url.searchParams.set('state', state);
      return url.href;
    },
    authorize(state, approvalUrl, orderId) {
      const session = sessions.get(state);
      if (!session) return Promise.reject(new Error('Ventana de pago cerrada.'));
      const url = new URL(approvalUrl);
      if (url.protocol !== 'https:' || !['www.paypal.com', 'www.sandbox.paypal.com'].includes(url.hostname)) {
        return Promise.reject(new Error('Enlace de PayPal inválido.'));
      }
      return new Promise((resolve, reject) => {
        let timer;
        const finish = (approved, error) => {
          clearInterval(timer);
          window.removeEventListener('message', receive);
          session.finish = null;
          if (error) reject(error); else resolve(approved);
        };
        const receive = event => {
          if (event.origin !== location.origin || event.source !== session.popup) return;
          const data = event.data;
          if (!data || data.type !== 'panamericana-paypal' || data.state !== state) return;
          if (data.cancelled) return finish(false);
          if (data.orderId !== orderId) return;
          finish(true);
        };
        session.finish = () => finish(false);
        window.addEventListener('message', receive);
        const started = Date.now();
        timer = setInterval(() => {
          if (session.popup.closed) finish(false);
          else if (Date.now() - started > 10 * 60 * 1000) {
            finish(false, new Error('El tiempo de autorización de PayPal terminó.'));
          }
        }, 500);
        session.popup.location.href = url.href;
        session.popup.focus();
      });
    },
    close(state) {
      const session = sessions.get(state);
      if (!session) return;
      session.finish?.();
      session.popup.close();
      sessions.delete(state);
    }
  };
})();
