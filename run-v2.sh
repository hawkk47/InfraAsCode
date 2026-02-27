#!/bin/bash
set -e

echo "====================================="
echo "  InfraAsCode v2 - Multi-nœuds      "
echo "====================================="

# 1. Charger les credentials OpenStack
echo ""
echo "[1/5] Chargement des credentials OpenStack..."
source openrc-etudiant.sh

# 2. Provisionner l'infrastructure avec OpenTofu
echo ""
echo "[2/5] Provisionnement de l'infrastructure (2 VMs)..."
tofu init -input=false
tofu apply -auto-approve

# 3. Récupérer les IPs
echo ""
echo "[3/5] Récupération des IPs..."
export MANAGER_IP=$(tofu output -raw manager_ip)
export WORKER_IP=$(tofu output -raw worker_ip)
echo "Manager IP : $MANAGER_IP"
echo "Worker  IP : $WORKER_IP"

# 4. Attendre la disponibilité SSH des deux VMs
echo ""
echo "[4/5] Attente du démarrage des VMs..."
for IP in $MANAGER_IP $WORKER_IP; do
  echo "  Attente de $IP..."
  until nc -zvw5 $IP 22 2>/dev/null; do
    sleep 5
  done
  echo "  $IP disponible !"
done

# 5. Déployer avec Ansible (tout est dans le playbook)
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
echo "  whoami   : http://whoami.${MANAGER_IP}.sslip.io"
echo "  etherpad : http://etherpad.${MANAGER_IP}.sslip.io"
echo "  traefik  : http://traefik.${MANAGER_IP}.sslip.io"
echo ""