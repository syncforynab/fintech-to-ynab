import settings

from pynYNAB.Client import nYnabClient, nYnabConnection

connection = nYnabConnection(settings.ynab_username, settings.ynab_password)
client = nYnabClient(nynabconnection=connection, budgetname=settings.ynab_budget, logger=settings.log)
client.sync()
