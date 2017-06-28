import json
from unittest import TestCase
from mock import patch

from python import settings
from python.main import app
from python.routes import common_view

class TestRoutes(TestCase):
    def setUp(self):
        app.config['TESTING'] = True
        app.config['DEBUG'] = True
        self.app = app.test_client()
        self.app.testing = True
        self.app.debug = True

    def test_secret(self):
        if settings.url_secret is not None:
            response = self.app.post('/monzo')
            self.assertEqual(response.status_code,403)

    def test_common_view_decorator(self):
        d = {'data':'data'}
        def create_func(data, settings):
            return d,123

        with app.test_request_context(data='{}'),\
             patch('python.ynab_client.init') as ynab_client_patch:
            body,code = common_view(create_func)
            self.assertEqual(code,123)
            self.assertEqual(json.loads(body.data),d)
            self.assertTrue(ynab_client_patch.called)
            self.assertEqual(1, ynab_client_patch.call_count)
