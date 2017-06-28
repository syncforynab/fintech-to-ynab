from flask import Flask

import settings
import ynab_client
from routes import main_blueprints

app = Flask('Fintech to YNAB')
app.config['DEBUG'] = settings.flask_debug
app.register_blueprint(main_blueprints)

if __name__ == "__main__":
    ynab_client.init()
    ynab_client.sync()
    app.run(host='0.0.0.0', port=settings.port)
