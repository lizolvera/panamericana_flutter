import http from 'k6/http';
import { check, sleep } from 'k6';

const base = (__ENV.STAGING_API_URL || '').replace(/\/$/, '');
if (!/^https:\/\/[a-z0-9.-]+(?::\d+)?$/i.test(base) ||
    /^https:\/\/prybinaback\.onrender\.com(?::\d+)?$/i.test(base)) {
  throw new Error('Se requiere origen HTTPS exclusivo de staging');
}
const stress = __ENV.TEST_MODE === 'stress';
const count = Number(__ENV.STRESS_MAX_VUS || '20');
if (!Number.isInteger(count) || count < 1 || count > 50) throw new Error('Máximo manual: 1-50 VUs');
export const options = {
  scenarios: stress ? {
    stress: { executor: 'ramping-vus', startVUs: 1, stages: [
      { duration: '30s', target: Math.max(1, Math.floor(count / 2)) },
      { duration: '60s', target: count }, { duration: '30s', target: 0 },
    ], gracefulRampDown: '10s' },
  } : { normal: { executor: 'constant-vus', vus: 3, duration: '30s' } },
  thresholds: {
    http_req_duration: ['p(95)<1500'],
    http_req_failed: [{ threshold: 'rate<0.01', abortOnFail: true, delayAbortEval: '10s' }],
    checks: ['rate==1'],
  },
};

export function setup() {
  if (!__ENV.STAGING_CLIENT_A_TOKEN) throw new Error('Falta token sintético');
  const profile = http.get(base + '/api/usuarios/perfil', {
    headers: { Authorization: __ENV.STAGING_CLIENT_A_TOKEN }, redirects: 0,
  });
  if (profile.status !== 200 || profile.json('rol') !== 'usuario') throw new Error('Sesión staging inválida');
}

export default function () {
  const token = __ENV.STAGING_CLIENT_A_TOKEN;
  for (const path of ['/api/productos', '/api/usuarios/direcciones', '/api/pedidos']) {
    const response = http.get(base + path, {
      headers: { Authorization: token }, redirects: 0,
      tags: { endpoint: path }, timeout: '10s',
    });
    check(response, { 'respuesta JSON 200': r => r.status === 200 && (r.headers['Content-Type'] || '').includes('application/json') });
    sleep(1);
  }
}

export function handleSummary(data) {
  return { 'reports/k6/summary.json': JSON.stringify(data, null, 2) };
}
