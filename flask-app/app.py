from flask import Flask, jsonify
from vault_client import VaultClient

app = Flask(__name__)
vault_client = VaultClient()

@app.route('/')
def home():
    return jsonify({'message': 'Flask OpenBao Demo', 'status': 'running'})

@app.route('/db-credentials')
def get_db_credentials():
    secrets = vault_client.get_secret('database/demo')
    return jsonify(secrets)

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
