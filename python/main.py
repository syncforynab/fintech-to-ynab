import json
import logging

from flask import Flask, render_template, request, jsonify
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
    return 'hello world'

@app.route('/webhook', methods=['POST'])
def route_webhook():
    expected_delta = 0
    data = json.loads(request.data.decode('utf8'))
    settings.log.debug('webhook type received %s' % data['type'])

    if data['type'] == 'transaction.created':

        # Sync the account so we get the latest payees
        ynab_client.sync()

        # Does this account exist?
        account = ynab_client.getaccount(settings.ynab_account)
        if account == False:
            return jsonify({'error': 'Account not found'} )

        # Work out the Payee Name
        if data['data'].get('merchant'):
            payee_name = data['data']['merchant']['name']
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
        if not ynab_client.payeeexists(payee_name):
            settings.log.debug('payee does not exist, will create %s' % payee_name)
            expected_delta += 1

        # Suggested Tags
        suggested_tags = ''
        if data['data']['merchant'] and data['data']['merchant'].get('metadata', {}).get('suggested_tags'):
            suggested_tags = data['data']['merchant']['metadata']['suggested_tags']

        # Emoji!
        emoji = ''
        if data['data']['merchant'] and data['data']['merchant'].get('emoji'):
            emoji = data['data']['merchant']['emoji']

        # Either create or get the payee
        entities_payee_id = ynab_client.getpayee(payee_name).id

        # Create the Transaction
        expected_delta += 1
        settings.log.debug('Creating transaction object')
        transaction = Transaction(
            entities_account_id=account.id,
            amount=Decimal(data['data']['amount']) / 100,
            date=parse(data['data']['created']),
            entities_payee_id=entities_payee_id,
            imported_date=datetime.now().date(),
            imported_payee=payee_name,
            memo="%s %s" % (emoji, suggested_tags),
            source="Imported"
        )

    	if settings.clear_on_import:
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
    app.run(host="0.0.0.0")
