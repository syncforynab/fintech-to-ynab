import os
import logging

from os.path import join, dirname
from dotenv import load_dotenv

dotenv_path = join(dirname(dirname(__file__)), '.env')
if os.path.isfile(dotenv_path):
    load_dotenv(dotenv_path)

log_level = (os.environ.get('LOG_LEVEL') or 'DEBUG').upper()
logging.basicConfig(level=getattr(logging, log_level))
flask_debug = True if log_level == 'debug' else False

port = int(os.environ.get("PORT", 5000))

url_secret = os.environ.get('URL_SECRET')

ynab_account = os.environ.get('YNAB_ACCOUNT')
starling_ynab_account = os.environ.get('STARLING_NAB_ACCOUNT')

ynab_budget = os.environ.get('YNAB_BUDGET')
ynab_username = os.environ.get('YNAB_USERNAME')
ynab_password = os.environ.get('YNAB_PASSWORD')

auto_clear = os.environ.get('SKIP_AUTO_CLEAR') != 'true'
include_tags = os.environ.get('SKIP_TAGS') != 'true'
include_emoji = os.environ.get('SKIP_EMOJI') != 'true'

log = logging.getLogger(__name__)
