# InfraAsCode

## Prérequis

- macOS ou Linux
- [OpenTofu](https://opentofu.org/docs/intro/install/) installé (`brew install opentofu`)
- [Ansible](https://docs.ansible.com/) installé via pip
- [Docker CLI](https://docs.docker.com/engine/install/) installé (`brew install docker`)
- [AWS CLI](https://aws.amazon.com/cli/) installé (`brew install awscli`) — pour la création du bucket S3
- Un compte OVH avec accès à un projet OpenStack
- Un fichier `openrc-etudiant.sh` fourni par OVH (non versionné)
- Une paire de clés SSH dans `~/.ssh/id_rsa` / `~/.ssh/id_rsa.pub`
  - Si absente : `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""`

---

## Getting Started

### 1. Cloner le projet
```bash
git clone https://github.com/hawkk47/InfraAsCode.git
cd InfraAsCode
```

### 2. Créer l'environnement Python
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install community.docker
```

### 3. Configurer le backend S3 (Remote State)

Créer les identifiants S3 (EC2 Credentials) :
```bash
source openrc-etudiant.sh
openstack ec2 credentials create
```

Exporter les identifiants S3 :
```bash
export AWS_ACCESS_KEY_ID="votre_access_key"
export AWS_SECRET_ACCESS_KEY="votre_secret_key"
```

Créer le bucket :
```bash
aws s3 mb s3://my-ovh-tfstate-bucket --endpoint-url https://s3.gra.perf.cloud.ovh.net
```

### 4. Initialiser OpenTofu
```bash
source openrc-etudiant.sh
tofu init -reconfigure
```

### 5. Déploiement One-Shot (v1 — Single Node)
```bash
bash run.sh
```

### 6. Déploiement complet (v2 — Multi-nœuds avec Swarm, Traefik, NFS, Etherpad)
```bash
bash run-v2.sh
```

Ce script va automatiquement :
1. Provisionner 2 VMs sur OVH
2. Attendre leur disponibilité SSH
3. Installer fail2ban + Docker sur les 2 nœuds
4. Initialiser un cluster Docker Swarm (manager + worker)
5. Configurer NFS pour la persistance des données
6. Déployer Traefik, Whoami et Etherpad via templates Jinja2

### 7. Accès aux services
```
whoami   : http://whoami.<MANAGER_IP>.sslip.io
etherpad : http://etherpad.<MANAGER_IP>.sslip.io
traefik  : http://traefik.<MANAGER_IP>.sslip.io
```

### 8. Détruire l'infrastructure
```bash
source openrc-etudiant.sh
tofu destroy
```

---

## Structure du projet
```
.
├── main.tf                       # Infrastructure OpenTofu (2 VMs, backend S3)
├── playbook.yml                  # Playbook Ansible multi-nœuds
├── inventory.sh                  # Inventaire dynamique (managers/workers)
├── run.sh                        # Déploiement v1 (single node)
├── run-v2.sh                     # Déploiement v2 (multi-nœuds)
├── requirements.txt              # Dépendances Python
├── templates/
│   ├── traefik-stack.yml.j2      # Stack Traefik (template Jinja2)
│   ├── app-whoami-stack.yml.j2   # Stack Whoami (template Jinja2)
│   └── app-etherpad-stack.yml.j2 # Stack Etherpad + NFS (template Jinja2)
├── .github/workflows/
│   └── deploy.yml                # CI/CD GitHub Actions
└── .gitignore
```

---

## GitHub Actions (CI/CD)
Configurez les secrets suivants dans votre dépôt GitHub :
- `OS_AUTH_URL`, `OS_TENANT_ID`, `OS_TENANT_NAME`, `OS_USERNAME`, `OS_PASSWORD`, `OS_REGION_NAME`, `OS_USER_DOMAIN_NAME`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `SSH_PRIVATE_KEY`, `SSH_PUBLIC_KEY`

Le workflow se déclenche automatiquement à chaque push sur `main`.