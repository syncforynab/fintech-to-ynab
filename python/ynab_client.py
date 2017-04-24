import settings

from pynYNAB.Client import nYnabClient, nYnabConnection
from pynYNAB.schema.Entity import Entity, ComplexEncoder, Base, AccountTypes
from pynYNAB.schema.budget import Account, Transaction, Payee
from pynYNAB.schema.roots import Budget
from pynYNAB.schema.types import AmountType

from sqlalchemy.sql.expression import select, exists, func

connection = nYnabConnection(settings.ynab_username, settings.ynab_password)
client = nYnabClient(nynabconnection=connection, budgetname=settings.ynab_budget, logger=settings.log)
client.sync()

accounts = {x.account_name: x for x in client.budget.be_accounts}
payees = {p.name: p for p in client.budget.be_payees}

def getaccount(accountname):
    try:
        settings.log.debug('searching for account %s' % accountname)
        return accounts[accountname]
    except KeyError:
        settings.log.error('Couldn''t find this account: %s' % accountname)
        exit(-1)

def payeeexists(payeename):
    try:
        return True
    except KeyError:
        return False

def getpayee(payeename):
    try:
        settings.log.debug('searching for payee %s' % payeename)
        return payees[payeename]
    except KeyError:
        settings.log.debug('Couldn''t find this payee: %s' % payeename)
        payee=Payee(name=payeename)
        client.budget.be_payees.append(payee)
        return payee

def containsDuplicate(transaction):
    return client.session.query(exists()\
   	.where(Transaction.amount==transaction.amount)\
      	.where(Transaction.entities_account_id==transaction.entities_account_id)\
      	.where(Transaction.date==transaction.date.date())\
        .where(Transaction.imported_payee==transaction.imported_payee)\
        .where(Transaction.source==transaction.source)\
        ).scalar()
