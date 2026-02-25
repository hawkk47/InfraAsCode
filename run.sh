#!/bin/bash
set -e

echo "====================================="
echo "  InfraAsCode - Déploiement complet  "
echo "====================================="

# 1. Charger les credentials OpenStack
echo ""
echo "[1/6] Chargement des credentials OpenStack..."
source openrc-etudiant.sh

# 2. Provisionner l'infrastructure avec OpenTofu
echo ""
echo "[2/6] Provisionnement de l'infrastructure..."
tofu init -input=false
tofu apply -auto-approve

# 3. Récupérer l'IP et générer l'inventaire
echo ""
echo "[3/6] Génération de l'inventaire Ansible..."
bash inventory.sh
IP=$(tofu output -raw instance_ip)
echo "IP de la VM : $IP"

# 4. Attendre que la VM soit prête
echo ""
echo "[4/6] Attente que la VM soit disponible via SSH..."
until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/id_rsa ubuntu@$IP "echo ok" 2>/dev/null; do
  echo "  VM pas encore prête, nouvelle tentative dans 10s..."
  sleep 10
done
echo "  VM disponible !"

# 5. Configurer la VM avec Ansible
echo ""
echo "[5/6] Configuration de la VM avec Ansible..."
source .venv/bin/activate
ansible-playbook -i inventory.ini playbook.yml

# 6. Déployer Traefik + whoami sur Docker Swarm
echo ""
echo "[6/6] Déploiement des stacks Docker..."
export DOCKER_HOST=ssh://ubuntu@$IP
docker stack deploy -c stacks/traefik.yml traefik
docker stack deploy -c stacks/whoami.yml whoami

# Attendre que le service whoami soit actif
echo ""
echo "Attente du démarrage des services..."
sleep 15

echo ""
echo "====================================="
echo "  Déploiement terminé !"
echo "====================================="
echo ""
echo "  whoami  : https://whoami.${IP}.traefik.me"
echo "  traefik : https://traefik.${IP}.traefik.me"
echo ""