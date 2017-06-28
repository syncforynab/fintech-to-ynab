from unittest import TestCase

from mock import Mock, patch
from pynYNAB.schema.budget import Payee, Account

import python.ynab_client as ynab_client_module
from python.functions import create_transaction_from_starling, create_transaction_from_monzo, get_subcategory_from_payee

mockYnabClient = Mock(ynab_client_module)


create_functions = {'monzo': create_transaction_from_monzo, 'starling': create_transaction_from_starling}

class CreateTests(TestCase):
    def check_notype(self,func_name):
        data = {}
        body, code = create_functions[func_name](data, ynab_client=mockYnabClient)
        self.assertEqual(code, 400)

    def test_notype(self):
        for func_name in create_functions:
            yield self.check_notype,func_name

    def check_wrongtype(self, func_name):
        data = dict(type='Meh')
        body, code = create_functions[func_name](data, ynab_client=mockYnabClient)
        self.assertEqual(code, 400)

    def test_wrongtype(self):
        for func_name in create_functions:
            yield self.check_wrongtype,func_name

    def check_nodata(self, func_name):
        data = {}
        body, code = create_functions[func_name](data, ynab_client=mockYnabClient)
        self.assertEqual(code, 400)

    def test_nodata(self):
        for func_name in create_functions:
            yield self.check_nodata,func_name

class CreateMonzoTests(TestCase):
    def test_typeOK_ynabsynccalled(self):
        data = dict(type='transaction.created')
        try:
            body, code = create_transaction_from_monzo(data, ynab_client=mockYnabClient)
        except KeyError:
            pass
        self.assertTrue(mockYnabClient.sync.called)

    @patch.object(mockYnabClient, 'getaccount',lambda account_name:None)
    def test_typeOK_noaccount(self):
        data = dict(type='transaction.created', data=dict(amount=10))
        def _getacount(accountname):
            return None
        body, code = create_transaction_from_monzo(data, ynab_client=mockYnabClient)
        self.assertEqual(code,400)

    @patch.object(mockYnabClient, 'getaccount', lambda account_name: Mock(Account))
    @patch.object(mockYnabClient, 'getpayee', lambda payee_name: Mock(Payee))
    @patch.object(mockYnabClient, 'containsDuplicate', lambda transaction: False)
    @patch('python.functions.get_subcategory_from_payee', lambda payee_name: Mock(Payee))
    def test_typeOK_payeefound(self):
        data = dict(type='transaction.created',
                    data=dict(
                        id='id',
                        created='2017-05-7',
                        amount=10, merchant=dict(name='merchant_name'),local_currency='',currency=''
                    ))
        def _getacount(accountname):
            return None

        transaction_list=[]

        body, code = create_transaction_from_monzo(data, ynab_client=mockYnabClient)
        self.assertEqual(code, 201)
        transactions_append = mockYnabClient.client.budget.be_transactions.append
        self.assertTrue(transactions_append.called)
        self.assertEqual(transactions_append.call_count, 1)

        tup,dic = transactions_append.call_args
        self.assertEqual({},dic)
        self.assertEqual(len(tup),1)
        appended_transaction = tup[-1]

        self.assertTrue(mockYnabClient.client.push.called)
        tup, dic = mockYnabClient.client.push.call_args
        self.assertEqual({}, dic)
        self.assertEqual(len(tup), 1)
        self.assertEqual(1, tup[-1])
