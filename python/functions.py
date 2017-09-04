from datetime import datetime
from decimal import Decimal

from dateutil.parser import parse
from pynYNAB.schema.budget import Transaction

import ynab_client as ynab_client_module, settings as settings_module


def create_transaction_from_starling(data, settings=settings_module, ynab_client = ynab_client_module):
    settings.log.debug('received data %s'%data)
    expected_delta = 0
    if not data.get('content') or not data['content'].get('type'):
        return {'error': 'No webhook content type provided'}, 400
    if not data.get('content') or not data['content'].get('type') or not data['content']['type'] in ['TRANSACTION_CARD', 'TRANSACTION_FASTER_PAYMENT_IN', 'TRANSACTION_FASTER_PAYMENT_OUT',
                                'TRANSACTION_DIRECT_DEBIT']:
        return {'error': 'Unsupported webhook type: %s' % data.get('content')['type']}, 400
    # Sync the account so we get the latest payees
    ynab_client.sync()

    if data['content']['amount'] == 0:
        return {'error': 'Transaction amount is 0.'}, 200

    # Does this account exist?
    account = ynab_client.getaccount(settings.starling_ynab_account)
    if not account:
        return {'error': 'Account {} was not found'.format(settings.starling_ynab_account)}, 400


    payee_name = data['content']['counterParty']
    subcategory_id = None
    flag = None
    cleared = None
    memo = ''

    # If we are creating the payee, then we need to increase the delta
    if ynab_client.payeeexists(payee_name):
        settings.log.debug('payee exists, using %s', payee_name)
        subcategory_id = get_subcategory_from_payee(payee_name)
    else:
        settings.log.debug('payee does not exist, will create %s', payee_name)
        expected_delta += 1

    entities_payee_id = ynab_client.getpayee(payee_name).id

    if data['content']['sourceCurrency'] != 'GBP':
        memo += ' (%s %s)' % (data['content']['sourceCurrency'], abs(data['content']['sourceAmount']))
        flag = 'Orange'
    else:
        cleared = 'Cleared'

    # Create the Transaction
    expected_delta += 1
    settings.log.debug('Creating transaction object')
    transaction = Transaction(
        check_number=data['content'].get('transactionUid'),
        entities_account_id=account.id,
        amount=data['content']['amount'],
        date=parse(data['timestamp']),
        entities_payee_id=entities_payee_id,
        imported_date=datetime.now().date(),
        imported_payee=payee_name,
        source="Imported",
        flag=flag,
        cleared=cleared,
        memo=memo
    )

    if subcategory_id is not None:
        transaction.entities_subcategory_id = subcategory_id

    settings.log.debug('Duplicate detection')
    if ynab_client.containsDuplicate(transaction):
        settings.log.debug('skipping due to duplicate transaction')
        return {'error': 'Tried to add a duplicate transaction.'}, 200
    else:
        settings.log.debug('appending and pushing transaction to YNAB. Delta: %s', expected_delta)
        ynab_client.client.budget.be_transactions.append(transaction)
        ynab_client.client.push(expected_delta)
        return {'message': 'Transaction created in YNAB successfully.'}, 201


def create_transaction_from_monzo(data, settings=settings_module, ynab_client = ynab_client_module):
    settings.log.debug('received data %s' % data)
    expected_delta = 0
    data_type = data.get('type')
    settings.log.debug('webhook type received %s', data_type)
    if data_type != 'transaction.created':
        return {'error': 'Unsupported webhook type: %s' % data_type}, 400

    # the actual monzo data is in the data['data]' value
    data = data['data']

    if 'decline_reason' in data:
        return {'message': 'Ignoring declined transaction ({})'.format(data['decline_reason'])}, 200

    # Sync the account so we get the latest payees
    ynab_client.sync()

    if data['amount'] == 0:
        return {'error': 'Transaction amount is 0.'}, 200

    # Does this account exist?
    account = ynab_client.getaccount(settings.monzo_ynab_account)
    if not account:
        return {'error': 'Account {} was not found'.format(settings.monzo_ynab_account)}, 400

    # Work out the Payee Name
    if data.get('merchant'):
        payee_name = data['merchant']['name']
        subcategory_id = get_subcategory_from_payee(payee_name)
    else:
        # This is a p2p transaction
        payee_name = get_p2p_transaction_payee_name(data)
        subcategory_id = None

    # If we are creating the payee, then we need to increase the delta
    if not ynab_client.payeeexists(payee_name):
        settings.log.debug('payee does not exist, will create %s', payee_name)
        expected_delta += 1

    # Get the payee ID. This will append a new one if needed
    entities_payee_id = ynab_client.getpayee(payee_name).id

    memo = ''
    if settings.include_emoji and data['merchant'] and data['merchant'].get('emoji'):
        memo += ' %s' % data['merchant']['emoji']

    if settings.include_tags and data['merchant'] and data['merchant'].get('metadata', {}).get('suggested_tags'):
        memo += ' %s' % data['merchant']['metadata']['suggested_tags']

    # Show the local currency in the notes if this is not in the accounts currency
    flag = None
    cleared = None
    if data['local_currency'] != data['currency']:
        memo += ' (%s %s)' % (data['local_currency'], (abs(Decimal(data['local_amount'])) / 100))
        flag = 'Orange'
    else:
        cleared = 'Cleared'

    # Create the Transaction
    expected_delta += 1
    settings.log.debug('Creating transaction object')
    transaction = Transaction(
        check_number=data['id'],
        entities_account_id=account.id,
        amount=Decimal(data['amount']) / 100,
        date=parse(data['created']),
        entities_payee_id=entities_payee_id,
        imported_date=datetime.now().date(),
        imported_payee=payee_name,
        memo=memo,
        flag=flag,
        cleared=cleared
    )

    if subcategory_id is not None:
        transaction.entities_subcategory_id = subcategory_id

    settings.log.debug('Duplicate detection')
    if ynab_client.containsDuplicate(transaction):
        settings.log.debug('skipping due to duplicate transaction')
        return {'error': 'Tried to add a duplicate transaction.'}, 200
    else:
        settings.log.debug('appending and pushing transaction to YNAB. Delta: %s', expected_delta)
        ynab_client.client.budget.be_transactions.append(transaction)
        ynab_client.client.push(expected_delta)
        return {'message': 'Transaction created in YNAB successfully.'}, 201


def get_subcategory_from_payee(payee_name, settings = settings_module, ynab_client = ynab_client_module):
    """
    Get payee details for a previous transaction in YNAB.
    If a payee with payee_name has been used in the past, we can get their ID and
    pre-populate category.

    :param payee_name: The name of the Payee as coming from the bank.
    :return: (payee_id, subcategory_id)
    """
    previous_transaction = ynab_client.findPreviousTransaction(payee_name)
    if previous_transaction is not None and previous_transaction.entities_payee is not None:
        settings.log.debug('A previous transaction for the payee %s has been found', payee_name)
        return get_subcategory_id_for_transaction(previous_transaction, payee_name)
    else:
        settings.log.debug('A previous transaction for the payee %s has not been found', payee_name)
    return None


def get_subcategory_id_for_transaction(transaction, payee_name, settings = settings_module):
    """
    Gets the subcategory ID for a transaction.
    Filters out transactions that have multiple categories.

    :param transaction: The transaction to get subcategory ID from.
    :return: The subcategory ID, or None if it is a multiple-category transaction.
    """
    subcategory = transaction.entities_subcategory

    if subcategory is not None:
        if subcategory.name != 'Split (Multiple Categories)...':
            settings.log.debug('We have identified the "%s" category as a good default for this payee', subcategory.name)
            return subcategory.id
        else:
            settings.log.debug('Split category found, so we will not use that category for %s', payee_name)
    else:
        settings.log.debug('A subcategory was not found for the previous transaction for %s', payee_name)


def get_p2p_transaction_payee_name(data):
    """
    Get the payee name for a p2p transaction, based on webook transaction data.

    :param data: The 'data' key of the transaction data.
    :return: The string name of the payee.
    """
    if data.get('counterparty'):
        if data['counterparty'].has_key('name'):
            payee_name = data['counterparty']['name']
        else:
            payee_name = data['counterparty']['number']
    elif data.get('metadata', {}).get('is_topup') == 'true':
        payee_name = 'Topup'
    else:
        payee_name = data.get('description')

    return payee_name
