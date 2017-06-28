from unittest import TestCase
from python.functions import get_subcategory_id_for_transaction, get_p2p_transaction_payee_name


class Stub(object):
    pass


class TestMain(TestCase):
    def test_get_subcategory_id_for_transaction(self):
        transaction_stub = Stub()
        subcategory_stub = Stub()

        subcategory_stub.id = '234'
        subcategory_stub.name = 'Test'
        transaction_stub.entities_subcategory = subcategory_stub

        self.assertEqual(get_subcategory_id_for_transaction(transaction_stub, 'Test Payee Name'), '234')

    def test_get_p2p_transaction_payee_name_counterparty_name(self):
        data = {
            'counterparty': {
                'name': 'test'
            }
        }

        self.assertEqual(get_p2p_transaction_payee_name(data), 'test')

    def test_get_p2p_transaction_payee_name_counterparty_number(self):
        data = {
            'counterparty': {
                'number': '123'
            }
        }

        self.assertEqual(get_p2p_transaction_payee_name(data), '123')

    def test_get_p2p_transaction_payee_name_counterparty(self):
        data = {
            'counterparty': {
                'name': 'test',
                'number': '123'
            }
        }

        self.assertEqual(get_p2p_transaction_payee_name(data), 'test')

    def test_get_p2p_transaction_payee_name_counterparty_topup(self):
        data = {
            'metadata': {
                'is_topup': 'true'
            }
        }

        self.assertEqual(get_p2p_transaction_payee_name(data), 'Topup')

    def test_get_p2p_transaction_payee_name_counterparty_unknown(self):
        data = dict()

        self.assertEqual(get_p2p_transaction_payee_name(data), 'Unknown Payee')
