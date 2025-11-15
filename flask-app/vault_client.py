import hvac
import os

class VaultClient:
    def __init__(self):
        self.vault_url = os.getenv('VAULT_ADDR', 'http://127.0.0.1:8200')
        self.role_id = os.getenv('ROLE_ID')
        self.secret_id = os.getenv('SECRET_ID')
        self.client = hvac.Client(url=self.vault_url)
        self._authenticate()
    
    def _authenticate(self):
        if self.role_id and self.secret_id:
            response = self.client.auth.approle.login(
                role_id=self.role_id,
                secret_id=self.secret_id
            )
            self.client.token = response['auth']['client_token']
    
    def get_secret(self, path):
        try:
            response = self.client.secrets.kv.v2.read_secret_version(path=path)
            return response['data']['data']
        except Exception as e:
            return {'error': str(e)}
