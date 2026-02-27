#!/bin/bash

NODE_IP=$(tofu output -raw instance_ip 2>/dev/null)

cat > inventory.yml <<EOF
all:
  children:
    swarm:
      children:
        managers:
          hosts:
            ${NODE_IP}:
              ansible_user: ubuntu
              ansible_ssh_private_key_file: ~/.ssh/id_rsa
EOF

echo "Inventaire généré : IP=$NODE_IP"