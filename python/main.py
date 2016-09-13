import json
import logging

from flask import Flask, render_template, request, jsonify
from datetime import datetime
from dateutil.parser import parse
from decimal import Decimal

import settings

from pynYNAB.Client import nYnabConnection, nYnabClient, BudgetNotFound
from pynYNAB.budget import Payee, Transaction
from pynYNAB.config import get_logger, test_common_args

app = Flask(__name__, template_folder='../html', static_folder='../static')
app.config['DEBUG'] = settings.flask_debug

log = logging.getLogger(__name__)

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
        ynab_connection = nYnabConnection(settings.ynab_username, settings.ynab_password)
        try:
            ynab_client = nYnabClient(ynab_connection, budget_name=settings.ynab_budget)
        except BudgetNotFound:
            print('No budget by this name found in nYNAB')
            exit(-1)

        accounts = {x.account_name: x for x in ynab_client.budget.be_accounts}
        payees = {p.name: p for p in ynab_client.budget.be_payees}

        def getaccount(accountname):
            try:
                log.debug('searching for account %s' % accountname)
                return accounts[accountname]
            except KeyError:
                log.error('Couldn''t find this account: %s' % accountname)
                exit(-1)

        def getpayee(payeename):
            try:
                log.debug('searching for payee %s' % payeename)
                return payees[payeename]
            except KeyError:
                log.debug('Couldn''t find this payee: %s' % payeename)
                payee=Payee(name=payeename)
                ynab_client.budget.be_payees.append(payee)
                return payee

        entities_account_id = getaccount('Mondo').id
        entities_payee_id = getpayee(data['data']['merchant']['name']).id

        # Try and get the suggested tags
        try:
            suggested_tags = data['data']['merchant']['metadata']['suggested_tags']
        except KeyError:
            suggested_tags = ''

        # Try and get the emoji
        try:
            emoji = data['data']['merchant']['emoji']
        except KeyError:
            emoji = ''

        transactions = []
        transaction = Transaction(
            entities_account_id=entities_account_id,
            amount=Decimal(data['data']['amount']) / 100,
            date=parse(data['data']['created']),
            entities_payee_id=entities_payee_id,
            imported_date=datetime.now().date(),
            imported_payee=data['data']['merchant']['name'],
            memo="%s %s" % (emoji, suggested_tags),
            source="Imported"
        )

        if not ynab_client.budget.be_transactions.containsduplicate(transaction):
            log.debug('Appending transaction %s '%transaction.getdict())
            transactions.append(transaction)
        else:
            log.debug('Duplicate transaction found %s '%transaction.getdict())

        ynab_client.add_transactions(transactions)

        return jsonify(data)
    else:
        log.warning('Unsupported webhook type: %s' % data['type'])

    return ''

if __name__ == "__main__":
    app.run()
