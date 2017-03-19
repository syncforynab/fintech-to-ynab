import json
import logging

from flask import Flask, render_template, request, jsonify
from datetime import datetime
from dateutil.parser import parse
from decimal import Decimal

import settings


from pynYNAB.Client import nYnabClient, nYnabConnection
from pynYNAB.schema.Entity import Entity, ComplexEncoder, Base, AccountTypes
from pynYNAB.schema.budget import Account, Transaction, Payee
from pynYNAB.schema.roots import Budget
from pynYNAB.schema.types import AmountType

app = Flask(__name__, template_folder='../html', static_folder='../static')
app.config['DEBUG'] = settings.flask_debug

log = logging.getLogger(__name__)
logging.basicConfig(level=logging.DEBUG)



if settings.sentry_dsn:
    from raven.contrib.flask import Sentry
    sentry = Sentry(app)

@app.route('/')
def route_index():
    return 'hello world'

@app.route('/webhook', methods=['POST'])
def route_webhook():
    global expectedDelta
    data = json.loads(request.data.decode('utf8'))

    expectedDelta = 1

    if data['type'] == 'transaction.created':
        ynab_connection = nYnabConnection(settings.ynab_username, settings.ynab_password)
        try:
            ynab_client = nYnabClient(nynabconnection=ynab_connection, budgetname=settings.ynab_budget, logger=log)
            ynab_client.sync()
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
                global expectedDelta
                log.debug('Couldn''t find this payee: %s' % payeename)
                payee=Payee(name=payeename)
                ynab_client.budget.be_payees.append(payee)
                expectedDelta=2
                return payee

        entities_account_id = getaccount(settings.ynab_account).id
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

#        log.debug(ynab_client.catalog.get_changed_apidict())
#        log.debug(ynab_client.budget.get_changed_apidict())

#        ynab_client.add_transaction(transaction)
        ynab_client.budget.be_transactions.append(transaction)
        log.debug('HERE!')
        log.debug(expectedDelta)
        ynab_client.push(expectedDelta)

        return jsonify(data)
    else:
        log.warning('Unsupported webhook type: %s' % data['type'])

    return ''

if __name__ == "__main__":
    app.run(host="0.0.0.0")
