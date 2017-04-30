import json
import settings
import ynab_client

from flask import Flask, request, jsonify, redirect
from datetime import datetime
from dateutil.parser import parse
from decimal import Decimal

from pynYNAB.schema.budget import Transaction

app = Flask('Monzo to YNAB')
app.config['DEBUG'] = settings.flask_debug


@app.route('/')
def route_index():
    return redirect("https://github.com/scottrobertson/monzo-to-ynab", code=302)


@app.route('/webhook', methods=['POST'])
def route_webhook():
    ynab_client.init()
    data = json.loads(request.data.decode('utf8'))
    settings.log.debug('webhook type received %s' % data['type'])
    if data.get('type') == 'transaction.created':
        create_transaction(data['data'], settings, 0)
    else:
        settings.log.warning('Unsupported webhook type: %s' % data['type'])
        return jsonify({'error': 'Unsupported webhook type'} )


def create_transaction(data, settings, expected_delta):
    # Sync the account so we get the latest payees
    ynab_client.sync()

    if data['amount'] == 0:
        return jsonify({'error': 'Amount is 0'})

    # Does this account exist?
    account = ynab_client.getaccount(settings.ynab_account)
    if not account:
        return jsonify({'error': 'Account not found'})

    # Work out the Payee Name
    if data.get('merchant'):
        payee_name = data['merchant']['name']
        entities_payee_id, subcategory_id = get_payee_details(payee_name)
    else:
        # This is a p2p transaction
        payee_name = get_p2p_transaction_payee_name(data)
        subcategory_id = None

    # If we are creating the payee, then we need to increase the delta
    if not ynab_client.payeeexists(payee_name):
        settings.log.debug('payee does not exist, will create %s' % payee_name)
        expected_delta += 1
        entities_payee_id = ynab_client.getpayee(payee_name).id

    memo = ''
    if settings.include_emoji and data['merchant'] and data['merchant'].get('emoji'):
        memo += ' %s' % data['merchant']['emoji']

    if settings.include_tags and data['merchant'] and data['merchant'].get('metadata', {}).get(
            'suggested_tags'):
        memo += ' %s' % data['merchant']['metadata']['suggested_tags']

    # Show the local currency in the notes if this is not in the accounts currency
    if data['data']['local_currency'] != data['data']['currency']:
        memo += ' (%s %s)' % (data['data']['local_currency'], (abs(data['data']['local_amount']) / 100))

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
        source="Imported"
    )

    if subcategory_id is not None:
        transaction.entities_subcategory_id = subcategory_id

    # If this transaction is in our local currency, then just automatically mark it as cleared.
    # Otherwise, we want to leave it as uncleared as the value may change once it settles
    if settings.auto_clear and data['local_currency'] == data['currency']:
        settings.log.debug('Setting transaction as cleared')
        transaction.cleared = 'Cleared'

    settings.log.debug('Duplicate detection')
    if ynab_client.containsDuplicate(transaction):
        settings.log.debug('skipping due to duplicate transaction')
        return jsonify({'error': 'Skipping due to duplicate transaction'})
    else:
        settings.log.debug('appending and pushing transaction to YNAB. Delta: %s' % expected_delta)
        ynab_client.client.budget.be_transactions.append(transaction)
        ynab_client.client.push(expected_delta)
        return jsonify(data)


def get_payee_details(payee_name):
    """
    Get payee details for a previous transaction in YNAB.
    If a payee with payee_name has been used in the past, we can get their ID and
    pre-populate category.
    
    :param payee_name: The name of the Payee as coming from Monzo.
    :return: (payee_id, subcategory_id)
    """
    previous_transaction = ynab_client.findPreviousTransaction(payee_name)
    if previous_transaction is not None:
        settings.log.debug('A previous transaction for the payee %s has been found' % payee_name)
        return get_payee_details_for_transaction(previous_transaction)
    else:
        settings.log.debug('A previous transaction for the payee %s has not been found' % payee_name)
    return None, None


def get_payee_details_for_transaction(transaction, payee_name):
    """
    Get the defaults for this payee based on YNAB data
    
    :param transaction: The transaction that we want to get payee details from.
    :return: tuple (payee_id, subcategory_id)
    """
    return transaction.entities_payee.id, get_subcategory_id_for_transaction(transaction, payee_name)


def get_subcategory_id_for_transaction(transaction, payee_name):
    """
    Gets the subcategory ID for a transaction. Filters out transactions that have multiple categories.
    
    :param transaction: The transaction to get subcategory ID from.
    :return: The subcategory ID, or None if it is a multiple-category transaction.
    """
    subcategory = transaction.entities_subcategory

    if subcategory is not None:
        if subcategory.name != 'Split (Multiple Categories)...':
            settings.log.debug(
                'We have identified the "%s" category as a good default for this payee' % subcategory.name)
            return subcategory.id
        else:
            settings.log.debug('Split category found, so we will not use that category for %s' % payee_name)
    else:
        settings.log.debug('A subcategory was not found for the previous transaction for %s' % payee_name)


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
        payee_name = 'Unknown Payee'

    return payee_name


if __name__ == "__main__":
    app.run(host='0.0.0.0', port=settings.port)
