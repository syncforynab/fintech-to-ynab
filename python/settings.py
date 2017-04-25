import os
import logging

from os.path import join, dirname
from dotenv import load_dotenv

dotenv_path = join(dirname(dirname(__file__)), '.env')
if os.path.isfile(dotenv_path):
    load_dotenv(dotenv_path)

log_level = os.environ.get('LOG_LEVEL').upper()
logging.basicConfig(level=getattr(logging, log_level))
flask_debug = True if log_level == 'debug' else False

ynab_account = os.environ.get('YNAB_ACCOUNT')
ynab_budget = os.environ.get('YNAB_BUDGET')
ynab_username = os.environ.get('YNAB_USERNAME')
ynab_password = os.environ.get('YNAB_PASSWORD')
auto_clear = os.environ.get('SKIP_AUTO_CLEAR') != 'true'

sentry_dsn = os.environ.get('SENTRY_DSN')

log = logging.getLogger(__name__)
