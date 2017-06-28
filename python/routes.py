from flask import Blueprint

import settings
import ynab_client
from functions import create_transaction_from_monzo,create_transaction_from_starling, create_transaction_from_bankin

main_blueprints = Blueprint('main',__name__)

from functools import wraps

from flask import request, jsonify
from werkzeug.utils import redirect

@main_blueprints.route('/')
def route_index():
    return redirect("https://github.com/scottrobertson/fintech-to-ynab", code=302)

@main_blueprints.route('/ping')
def route_ping():
    return 'pong'

def secret_required(func):
    """
    :param func: The view function to decorate.
    :type func: function
    """
    @wraps(func)
    def decorated_view(*args, **kwargs):
        if settings.url_secret is not None and settings.url_secret != request.args.get('secret'):
            return jsonify({'error': 'Invalid secret'}), 403
        return func(*args, **kwargs)
    return decorated_view


def common_view(create_transaction_func):
    data = request.get_json(force=True)
    settings.log.debug('received data json: %s' % data)

    ynab_client.init()

    body, code = create_transaction_func(data, settings)
    return jsonify(body), code

@main_blueprints.route('/starling', methods=['POST'])
@secret_required
def route_starling():
    return common_view(create_transaction_from_starling)

@main_blueprints.route('/monzo', methods=['POST'])
@secret_required
def route_monzo():
    return common_view(create_transaction_from_monzo)

@main_blueprints.route('/bankin', methods=['POST'])
@secret_required
def route_bankin():
    return common_view(create_transaction_from_bankin)
