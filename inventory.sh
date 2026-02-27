#!/bin/bash

MANAGER_IP=$(tofu output -raw manager_ip 2>/dev/null)
WORKER_IP=$(tofu output -raw worker_ip 2>/dev/null)

cat > inventory.yml <<EOF
all:
  children:
    swarm:
      children:
        managers:
          hosts:
            ${MANAGER_IP}:
              ansible_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
        workers:
          hosts:
            ${WORKER_IP}:
              ansible_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
EOF

echo "Inventaire généré : Manager=$MANAGER_IP  Worker=$WORKER_IP"