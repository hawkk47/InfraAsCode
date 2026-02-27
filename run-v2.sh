#!/bin/bash
set -e

echo "====================================="
echo "  InfraAsCode - Déploiement          "
echo "====================================="

# 1. Charger les credentials OpenStack
echo ""
echo "[1/5] Chargement des credentials OpenStack..."
source openrc-etudiant.sh

# 2. Provisionner l'infrastructure avec OpenTofu
echo ""
echo "[2/5] Provisionnement de l'infrastructure..."
tofu init -input=false
tofu apply -auto-approve

# 3. Récupérer l'IP
echo ""
echo "[3/5] Récupération de l'IP..."
export NODE_IP=$(tofu output -raw instance_ip)
echo "IP de la VM : $NODE_IP"

# 4. Attendre la disponibilité SSH
echo ""
echo "[4/5] Attente du démarrage de la VM..."
echo "  Attente de $NODE_IP..."
until nc -zvw5 $NODE_IP 22 2>/dev/null; do
  sleep 5
done
echo "  $NODE_IP disponible !"

# 5. Déployer avec Ansible
echo ""
echo "[5/5] Configuration et déploiement avec Ansible..."
source .venv/bin/activate
export ANSIBLE_HOST_KEY_CHECKING=False
bash inventory.sh
ansible-playbook -i inventory.yml playbook.yml

echo ""
echo "====================================="
echo "  Déploiement terminé !"
echo "====================================="
echo ""
echo "  whoami   : http://whoami.${NODE_IP}.sslip.io"
echo "  etherpad : http://etherpad.${NODE_IP}.sslip.io"
echo "  traefik  : http://traefik.${NODE_IP}.sslip.io"
echo ""