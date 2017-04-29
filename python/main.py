import json
import logging

from flask import Flask, render_template, request, jsonify, redirect
from datetime import datetime
from dateutil.parser import parse
from decimal import Decimal

from pynYNAB.schema.budget import Account, Transaction, Payee

import settings
import ynab_client

app = Flask(__name__, template_folder='../html', static_folder='../static')
app.config['DEBUG'] = settings.flask_debug

if settings.sentry_dsn:
    from raven.contrib.flask import Sentry
    sentry = Sentry(app)

@app.route('/')
def route_index():
    return redirect("https://github.com/scottrobertson/monzo-to-ynab", code=302)

@app.route('/webhook', methods=['POST'])
def route_webhook():
    expected_delta = 0
    data = json.loads(request.data.decode('utf8'))
    settings.log.debug('webhook type received %s' % data['type'])
    entities_payee_id = None
    subcategory_id = None
    if data['type'] == 'transaction.created':

        # Sync the account so we get the latest payees
        ynab_client.sync()

        if data['data']['amount'] == 0:
            return jsonify({'error': 'Amount is 0'} )

        # Does this account exist?
        account = ynab_client.getaccount(settings.ynab_account)
        if account == False:
            return jsonify({'error': 'Account not found'} )

        # Work out the Payee Name
        if data['data'].get('merchant'):
            payee_name = data['data']['merchant']['name']

            # Get the defaults for this payee based on previously imported data
            previous_transaction = ynab_client.findPreviousTransaction(payee_name)
            if not previous_transaction is None:
                settings.log.debug('A previous transaction for the payee %s has been found' % payee_name)
                entities_payee_id = previous_transaction.entities_payee.id
                subcategory = previous_transaction.entities_subcategory

                # Include the category used, as long as it's not a split category
                if not subcategory is None:
                    if not subcategory.name == 'Split (Multiple Categories)...':
                        settings.log.debug('We have identified the following category %s as a good default for this payee' % subcategory.name)
                        subcategory_id = subcategory.id
        else:
            # This is a p2p transaction
            if data['data'].get('counterparty'):
                if data['data']['counterparty'].has_key('name'):
                    payee_name = data['data']['counterparty']['name']
                else:
                    payee_name = data['data']['counterparty']['number']
            elif data['data'].get('metadata', {}).get('is_topup') == 'true':
                payee_name = 'Topup'
            else:
                payee_name = 'Unknown Payee'

        # If we are creating the payee, then we need to increase the delta
        if entities_payee_id is None:
            if not ynab_client.payeeexists(payee_name):
                settings.log.debug('payee does not exist, will create %s' % payee_name)
                expected_delta += 1

        memo = ''
        if settings.include_emoji and data['data']['merchant'] and data['data']['merchant'].get('emoji'):
            memo += ' %s' % data['data']['merchant']['emoji']

        if settings.include_tags and data['data']['merchant'] and data['data']['merchant'].get('metadata', {}).get('suggested_tags'):
            memo += ' %s' % data['data']['merchant']['metadata']['suggested_tags']

        # Show the local currency in the notes if this is not in the accounts currency
        if data['data']['local_currency'] != data['data']['currency']:
            memo += ' (%s %s)' % (data['data']['local_currency'], (abs(data['data']['local_amount']) / 100))

        # Either create or get the payee
        if entities_payee_id is None:
            entities_payee_id = ynab_client.getpayee(payee_name).id

        # Create the Transaction
        expected_delta += 1
        settings.log.debug('Creating transaction object')
        transaction = Transaction(
            check_number=data['data']['id'],
            entities_account_id=account.id,
            amount=Decimal(data['data']['amount']) / 100,
            date=parse(data['data']['created']),
            entities_payee_id=entities_payee_id,
            imported_date=datetime.now().date(),
            imported_payee=payee_name,
            memo=memo,
            source="Imported"
        )

        if not subcategory_id is None:
            transaction.entities_subcategory_id  = subcategory_id

        # If this transaction is in our local currency, then just automatically mark it as cleared.
        # Otherwise, we want to leave it as uncleared as the value may change once it settles
    	if settings.auto_clear and data['data']['local_currency'] == data['data']['currency']:
            settings.log.debug('Setting transaction as cleared')
     	    transaction.cleared='Cleared'

        settings.log.debug('Duplicate detection')
    	if ynab_client.containsDuplicate(transaction):
            settings.log.debug('skipping due to duplicate transaction')
            return jsonify({'error': 'Skipping due to duplicate transaction'} )
        else:
            settings.log.debug('appending and pushing transaction to YNAB. Delta: %s' % expected_delta)
            ynab_client.client.budget.be_transactions.append(transaction)
            ynab_client.client.push(expected_delta)
            return jsonify(data)
    else:
        settings.log.warning('Unsupported webhook type: %s' % data['type'])
        return jsonify({'error': 'Unsupported webhook type'} )
    return ''

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=settings.port)
