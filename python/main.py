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
    data = json.loads(request.data.decode('utf8'))

    if data['type'] == 'transaction.created':
        entities_account_id = ynab_client.getaccount(settings.ynab_account).id
        payee_name = ''
        if((data['data']['merchant'] is None) and (data['data']['counterparty'] is not None) and (data['data']['counterparty']['number'] is not None)):
            payee_name = data['data']['counterparty']['number']
        else:
            payee_name = data['data']['merchant']['name']


        # If we are creating the payee, then we need to increase the delta
        if ynab_client.payeeexists(payee_name):
            expected_delta = 1
        else:
            expected_delta = 2

        entities_payee_id = ynab_client.getpayee(payee_name).id

        # Try and get the suggested tags
        try:
            suggested_tags = data['data']['merchant']['metadata']['suggested_tags']
        except (KeyError, TypeError):
            suggested_tags = ''

        # Try and get the emoji
        try:
            emoji = data['data']['merchant']['emoji']
        except (KeyError, TypeError):
            emoji = ''

        transaction = Transaction(
            entities_account_id=entities_account_id,
            amount=Decimal(data['data']['amount']) / 100,
            date=parse(data['data']['created']),
            entities_payee_id=entities_payee_id,
            imported_date=datetime.now().date(),
            imported_payee=payee_name,
            memo="%s %s" % (emoji, suggested_tags),
            source="Imported"
        )

        ynab_client.client.budget.be_transactions.append(transaction)
        ynab_client.client.push(expected_delta)

        return jsonify(data)
    else:
        settings.log.warning('Unsupported webhook type: %s' % data['type'])

    return ''

if __name__ == "__main__":
    app.run(host="0.0.0.0")
