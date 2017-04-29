import json
import settings
import ynab_client

from flask import Flask, request, jsonify, redirect
from datetime import datetime
from dateutil.parser import parse
from decimal import Decimal

from pynYNAB.schema.budget import Transaction


app = Flask(__name__)
app.config['DEBUG'] = settings.flask_debug


@app.route('/')
def route_index():
    return redirect("https://github.com/scottrobertson/monzo-to-ynab", code=302)


@app.route('/webhook', methods=['POST'])
def route_webhook():
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
        entity_payee_id, subcategory_id = get_payee_details(payee_name)
    else:
        # This is a p2p transaction
        payee_name = get_p2p_transaction_payee_name(data)
        subcategory_id = None

    # If we are creating the payee, then we need to increase the delta
    if not ynab_client.payeeexists(payee_name):
        settings.log.debug('payee does not exist, will create %s' % payee_name)
        expected_delta += 1
        entities_payee_id = ynab_client.getpayee(payee_name).id

    # Suggested Tags
    suggested_tags = ''
    if settings.include_tags and data['merchant'] and data['merchant'].get('metadata', {}).get(
            'suggested_tags'):
        suggested_tags = data['merchant']['metadata']['suggested_tags']

    # Emoji!
    emoji = ''
    if settings.include_emoji and data['merchant'] and data['merchant'].get('emoji'):
        emoji = data['merchant']['emoji']

    # Show the local currency in the notes if this is not in the accounts currency
    local_currency = ''
    if data['local_currency'] != data['currency']:
        local_currency = '(%s %s)' % (data['local_currency'], (abs(data['local_amount']) / 100))

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
        memo="%s %s %s" % (emoji, suggested_tags, local_currency),
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
    Get the defaults for this payee based on previously imported data
    
    :param payee_name: The string name of the payee (normally merchant)
    :return: tuple (payee_id, subcategory_id)
    """
    previous_transaction = ynab_client.findPreviousTransaction(payee_name)
    if previous_transaction:
        settings.log.debug('A previous transaction for the payee %s has been found' % payee_name)
        entities_payee_id = previous_transaction.entities_payee.id
        subcategory = previous_transaction.entities_subcategory

        # Include the category used, as long as it's not a split category
        if subcategory:
            if subcategory.name != 'Split (Multiple Categories)...':
                settings.log.debug(
                    'We have identified the following category %s as a good default for this payee' % subcategory.name)
                subcategory_id = subcategory.id
                return entities_payee_id, subcategory_id
        return entities_payee_id, None
    return None, None


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
