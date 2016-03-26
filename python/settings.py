import os
import logging

def get_env():
    # Load the settings from the .env file if no environment has been selected
    if not os.environ.get('ENV'):
        a = os.path.join(os.path.dirname(__file__), '../.env')
        with open(a) as f:
            defaults = dict(tuple(x.strip().split('=')) for x in f.readlines() if x != '\n')
            os.environ.update(defaults)

    return os.environ

env = get_env()

log_level = env.get('LOG_LEVEL').upper()
logging.basicConfig(level=getattr(logging, log_level))
flask_debug = True if log_level == 'debug' else False

ynab_account = env.get('YNAB_ACCOUNT')
ynab_budget = env.get('YNAB_BUDGET')
ynab_username = env.get('YNAB_USERNAME')
ynab_password = env.get('YNAB_PASSWORD')
