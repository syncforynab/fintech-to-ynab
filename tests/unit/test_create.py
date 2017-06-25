import unittest
from mock import Mock

import python.ynab_client as ynab_client_module
from python.main import create_transaction_from_bankin, create_transaction_from_monzo, create_transaction_from_starling

mockYnabClient= Mock(ynab_client_module)


class create_transaction_from_monzo_tests(unittest.TestCase):
    def test_notype(self):
        data = {}
        body, code = create_transaction_from_monzo(data,ynab_client=mockYnabClient)
        self.assertEqual(code,400)

    def test_wrongtype(self):
        data = {'type':'Meh'}
        body, code = create_transaction_from_monzo(data,ynab_client=mockYnabClient)
        self.assertEqual(code,400)

    def test(self):
        data = {}
        body, code = create_transaction_from_monzo(data,ynab_client=mockYnabClient)
        self.assertEqual(code,400)



