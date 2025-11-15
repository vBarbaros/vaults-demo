#!/bin/bash
# manage-docker-vault.sh

CONTAINER_NAME="openbao-server-demo"

case "$1" in
  start)
    echo "Starting OpenBao container..."
    docker start $CONTAINER_NAME
    sleep 3
    
    # Auto-unseal if keys exist
    if [ -f .vault-keys.json ]; then
      export VAULT_ADDR='http://127.0.0.1:8200'
      UNSEAL_KEY_1=$(jq -r '.unseal_keys_b64[0]' .vault-keys.json)
      UNSEAL_KEY_2=$(jq -r '.unseal_keys_b64[1]' .vault-keys.json)
      UNSEAL_KEY_3=$(jq -r '.unseal_keys_b64[2]' .vault-keys.json)
      
      docker exec $CONTAINER_NAME bao operator unseal $UNSEAL_KEY_1
      docker exec $CONTAINER_NAME bao operator unseal $UNSEAL_KEY_2
      docker exec $CONTAINER_NAME bao operator unseal $UNSEAL_KEY_3
      echo "Vault unsealed and ready!"
    fi
    ;;
  stop)
    echo "Stopping OpenBao container..."
    docker stop $CONTAINER_NAME
    ;;
  status)
    docker ps -f name=$CONTAINER_NAME
    ;;
  logs)
    docker logs $CONTAINER_NAME
    ;;
  *)
    echo "Usage: $0 {start|stop|status|logs}"
    exit 1
    ;;
esac
