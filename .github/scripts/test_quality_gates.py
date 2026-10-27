import os
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

from check_coverage import coverage
from staging_api import config, run


class QualityGateTests(unittest.TestCase):
    def test_lcov_deduplicates_lines_and_normalizes_paths(self):
        with TemporaryDirectory() as directory:
            path = Path(directory, 'lcov.info')
            path.write_text('SF:lib\\file.dart\nDA:1,0\nDA:2,1\nend_of_record\nSF:lib/file.dart\nDA:1,1\n')
            self.assertEqual(coverage(path), {'lib/file.dart': {1: 1, 2: 1}})

    def test_rejects_missing_production_and_redirectable_credentials(self):
        for url in ['', 'http://staging.example', 'https://prybinaback.onrender.com',
                    'https://prybinaback.onrender.com.', 'https://user:password@staging.example',
                    'https://staging.example/api', 'https://staging.example?token=x']:
            with patch.dict(os.environ, {'STAGING_API_URL': url,
                                        'STAGING_CLIENT_A_TOKEN': 'a', 'STAGING_CLIENT_B_TOKEN': 'b'}):
                with self.assertRaises(ValueError):
                    config()

    def test_contract_detects_cross_client_data_leak(self):
        def response(base, path, token=None):
            if path == '/api/productos':
                return 200, []
            if not token or token == 'invalid-ci-token':
                return 401, {}
            if path.endswith('/admin/usuarios'):
                return 403, {}
            if path.endswith('/perfil'):
                return 200, {'_id': token, 'rol': 'usuario'}
            if path.endswith('/direcciones'):
                return 200, []
            if path == '/api/pedidos':
                return 200, [{'_id': 'a' * 24, 'usuario': token}]
            return 403, {}
        env = {'STAGING_API_URL': 'https://staging.example',
               'STAGING_CLIENT_A_TOKEN': 'a', 'STAGING_CLIENT_B_TOKEN': 'b'}
        with patch.dict(os.environ, env), patch('staging_api.get', side_effect=response):
            self.assertTrue(all(c['passed'] for c in run()))
        def leaking_response(base, path, token=None):
            if path == '/api/pedidos/' + 'a' * 24:
                return 200, {'usuario': 'another-client'}
            return response(base, path, token)
        with patch.dict(os.environ, env), patch('staging_api.get', side_effect=leaking_response):
            with self.assertRaises(AssertionError):
                run()


if __name__ == '__main__':
    unittest.main()
