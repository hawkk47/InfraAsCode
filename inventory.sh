#!/bin/bash

IP=$(tofu output -raw instance_ip 2>/dev/null)

cat > inventory.ini <<EOF
[webservers]
${IP} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF

echo "Inventaire généré pour IP : ${IP}"