#!/bin/bash
set -e

echo "====================================="
echo "  InfraAsCode - Cluster 2 nœuds     "
echo "====================================="

# 1. Charger les credentials OpenStack
echo ""
echo "[1/6] Chargement des credentials OpenStack..."
source openrc-etudiant.sh
export AWS_ACCESS_KEY_ID=ee1b599fe4054f1c87254b2ea1126724
export AWS_SECRET_ACCESS_KEY=86a09bc6ce3f43829b0c149e5f929aa5

# 2. Provisionner l'infrastructure avec OpenTofu
echo ""
echo "[2/6] Provisionnement de l'infrastructure (2 VMs)..."
tofu init -input=false
tofu apply -auto-approve

# 3. Rendre le backend S3 publi
echo ""
echo "[3/6] Rendre le backend S3 public..."
aws s3api put-bucket-acl --bucket iac-axel-dln --acl public-read --endpoint-url https://s3.sbg.perf.cloud.ovh.net || true
aws s3api put-object-acl --bucket iac-axel-dln --key terraform.tfstate --acl public-read --endpoint-url https://s3.sbg.perf.cloud.ovh.net || true

# 4. Récupérer les IPs
echo ""
echo "[4/6] Récupération des IPs..."
export MANAGER_IP=$(tofu output -raw manager_ip)
export WORKER_IP=$(tofu output -raw worker_ip)
echo "Manager IP : $MANAGER_IP (axel-dln-iac-1)"
echo "Worker  IP : $WORKER_IP (axel-dln-iac-2)"

# 5. Attendre la disponibilité SSH des deux VMs
echo ""
echo "[5/6] Attente du démarrage des VMs..."
for IP in $MANAGER_IP $WORKER_IP; do
  echo "  Attente de $IP..."
  until nc -zvw5 $IP 22 2>/dev/null; do
    sleep 5
  done
  echo "  $IP disponible !"
done

# 6. Déployer avec Ansible
echo ""
echo "[6/6] Configuration et déploiement avec Ansible..."
source .venv/bin/activate
export ANSIBLE_HOST_KEY_CHECKING=False
bash inventory.sh
ansible-playbook -i inventory.yml playbook.yml

echo ""
echo "====================================="
echo "  Déploiement terminé !"
echo "====================================="
echo ""
echo "  📊 Services déployés :"
echo "  - Traefik   : http://traefik.${MANAGER_IP}.sslip.io"
echo "  - Whoami    : http://whoami.${MANAGER_IP}.sslip.io (6 replicas - load balancing)"
echo "  - Etherpad  : http://etherpad.${MANAGER_IP}.sslip.io (stockage NFS persistant)"
echo ""
echo "  🔗 Backend S3 : https://iac-axel-dln.s3.sbg.perf.cloud.ovh.net/terraform.tfstate"
echo ""