import unittest

from python.main import app

class TestRoutes(unittest.TestCase):
    def setUp(self):
        app.config['TESTING'] = True
        app.config['DEBUG'] = True
        self.app = app.test_client()
        self.app.testing = True
        self.app.debug = True

    def test_secret(self):
        response = self.app.post('/bankin')
        self.assertEqual(response.status_code,403)