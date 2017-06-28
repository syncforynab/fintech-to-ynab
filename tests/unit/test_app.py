import json
from unittest import TestCase
from mock import patch, Mock

from python import settings
from python.main import app
from python.routes import common_view, secret_required

testing_route = '/__testing'

@app.route(testing_route,methods=['POST'])
@secret_required
def view():
    return 'OK called', 200


class TestRoutes(TestCase):
    def setUp(self):
        app.config['TESTING'] = True
        app.config['DEBUG'] = True
        self.app = app.test_client()
        self.app.testing = True
        self.app.debug = True

    @patch('python.settings.url_secret', 'dummy secret')
    def test_secret_errors_ifwrongsecret(self):
        with app.test_request_context(testing_route):
            response = self.app.post(testing_route, query_string=dict(secret='wrong secret'))
            self.assertEqual(response.status_code,403)

    @patch('python.settings.url_secret', 'dummy secret')
    def test_secret_calls_ifvalidsecret(self):
        with app.test_request_context(testing_route):
            response = self.app.post(testing_route, query_string=dict(secret='dummy secret'))
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.data, 'OK called')

    @patch('python.settings.url_secret', None)
    def test_secret_errors_nosettingssecret(self):
        with app.test_request_context(testing_route):
            response = self.app.post(testing_route, query_string=dict(secret='any secret'))
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.data, 'OK called')

            response = self.app.post(testing_route)
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.data, 'OK called')


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
