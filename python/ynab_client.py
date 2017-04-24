import settings

from pynYNAB.Client import nYnabClient, nYnabConnection
from pynYNAB.schema.Entity import Entity, ComplexEncoder, Base, AccountTypes
from pynYNAB.schema.budget import Account, Transaction, Payee
from pynYNAB.schema.roots import Budget
from pynYNAB.schema.types import AmountType

connection = nYnabConnection(settings.ynab_username, settings.ynab_password)
client = nYnabClient(nynabconnection=connection, budgetname=settings.ynab_budget, logger=settings.log)
client.sync()

accounts = {x.account_name: x for x in ynab_client.client.budget.be_accounts}
payees = {p.name: p for p in ynab_client.client.budget.be_payees}

def getaccount(accountname):
    try:
        settings.log.debug('searching for account %s' % accountname)
        return accounts[accountname]
    except KeyError:
        settings.log.error('Couldn''t find this account: %s' % accountname)
        exit(-1)

def getpayee(payeename):
    try:
        settings.log.debug('searching for payee %s' % payeename)
        return payees[payeename]
    except KeyError:
        global expectedDelta
        settings.log.debug('Couldn''t find this payee: %s' % payeename)
        payee=Payee(name=payeename)
        client.budget.be_payees.append(payee)
        expectedDelta=2
        return payee
