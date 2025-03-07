#!/bin/bash

# Styles pour l'affichage
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher les titres
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Fonction pour afficher les succès
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Fonction pour afficher les questions
print_question() {
    echo -e "${YELLOW}? $1${NC}"
}

# Fonction pour afficher les erreurs
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Vérifier si kubectl est installé
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

# Vérifier si helm est installé
if ! command -v helm &> /dev/null; then
    print_error "helm n'est pas installé. Veuillez l'installer avant de continuer."
    exit 1
fi

print_section "Bienvenue dans le script de déploiement d'une application Nginx avec Ingress"

# Configuration des variables par l'utilisateur
print_question "Nom du déploiement [nginx]: "
read deployment_name
deployment_name=${deployment_name:-nginx}

print_question "Nombre de réplicas [2]: "
read replicas
replicas=${replicas:-2}

print_question "Image Docker [nginx:latest]: "
read image
image=${image:-nginx:latest}

print_question "Nom du service [${deployment_name}-service]: "
read service_name
service_name=${service_name:-${deployment_name}-service}

print_question "Port du service [80]: "
read service_port
service_port=${service_port:-80}

print_question "Nom de l'Ingress [${deployment_name}-ingress]: "
read ingress_name
ingress_name=${ingress_name:-${deployment_name}-ingress}

print_question "Nom de la classe d'Ingress [nginx]: "
read ingress_class
ingress_class=${ingress_class:-nginx}

print_question "Nom d'hôte pour l'Ingress [example.local]: "
read host_name
host_name=${host_name:-example.local}

# Demander confirmation
echo -e "\n${YELLOW}Résumé de la configuration:${NC}"
echo "Déploiement: $deployment_name avec $replicas réplicas et image $image"
echo "Service: $service_name sur le port $service_port"
echo "Ingress: $ingress_name de classe $ingress_class pour l'hôte $host_name"

print_question "Voulez-vous continuer? (o/n): "
read confirmation
if [[ ! $confirmation =~ ^[oO]$ ]]; then
    print_error "Installation annulée."
    exit 1
fi

# 1. Créer le déploiement
print_section "Création du déploiement"
cat > ${deployment_name}-deploy.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $deployment_name
spec:
  replicas: $replicas
  selector:
    matchLabels:
      app: $deployment_name
  template:
    metadata:
      labels:
        app: $deployment_name
    spec:
      containers:
      - name: $deployment_name
        image: $image
        ports:
        - containerPort: 80
EOF

kubectl apply -f ${deployment_name}-deploy.yaml
if [ $? -eq 0 ]; then
    print_success "Déploiement créé avec succès"
else
    print_error "Erreur lors de la création du déploiement"
    exit 1
fi

# 2. Créer le Service
print_section "Création du service"
cat > ${service_name}.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: $service_name
spec:
  selector:
    app: $deployment_name
  ports:
  - port: $service_port
    targetPort: 80
EOF

kubectl apply -f ${service_name}.yaml
if [ $? -eq 0 ]; then
    print_success "Service créé avec succès"
else
    print_error "Erreur lors de la création du service"
    exit 1
fi

# 3. Installer l'Ingress Controller si nécessaire
print_section "Installation de l'Ingress Controller"
print_question "Souhaitez-vous installer l'Ingress Controller Nginx? (o/n): "
read install_ingress_controller
if [[ $install_ingress_controller =~ ^[oO]$ ]]; then
    echo "Installation de l'Ingress Controller Nginx..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm install nginx-ingress ingress-nginx/ingress-nginx
    if [ $? -eq 0 ]; then
        print_success "Ingress Controller installé avec succès"
    else
        print_error "Erreur lors de l'installation de l'Ingress Controller"
        exit 1
    fi
else
    print_success "Installation de l'Ingress Controller ignorée"
fi

# Attendre que l'Ingress Controller soit prêt
print_section "Attente de la disponibilité de l'Ingress Controller"
echo "Veuillez patienter..."
kubectl wait --namespace default --for=condition=ready pod --selector=app.kubernetes.io/name=ingress-nginx --timeout=90s
if [ $? -eq 0 ]; then
    print_success "L'Ingress Controller est prêt"
else
    print_error "L'Ingress Controller n'est pas disponible, mais nous continuons..."
fi

# 4. Créer l'Ingress
print_section "Création de l'Ingress"
cat > ${ingress_name}.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $ingress_name
spec:
  ingressClassName: $ingress_class
  rules:
  - host: $host_name
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: $service_name
            port:
              number: $service_port
EOF

kubectl apply -f ${ingress_name}.yaml
if [ $? -eq 0 ]; then
    print_success "Ingress créé avec succès"
else
    print_error "Erreur lors de la création de l'Ingress"
    exit 1
fi

# 5. Obtenir l'adresse IP de l'Ingress
print_section "Configuration finale"
echo "Attente de l'attribution d'une adresse IP à l'Ingress (cela peut prendre quelques instants)..."
sleep 10

ip=""
attempt=0
while [ -z "$ip" ] && [ $attempt -lt 12 ]; do
    ip=$(kubectl get ing $ingress_name -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -z "$ip" ]; then
        ip=$(kubectl get svc nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    fi
    
    if [ -z "$ip" ]; then
        echo "En attente de l'adresse IP... (tentative $attempt/12)"
        sleep 10
        attempt=$((attempt+1))
    fi
done

if [ -z "$ip" ]; then
    print_error "Impossible d'obtenir l'adresse IP de l'Ingress après plusieurs tentatives."
    echo "Vous pouvez l'obtenir en exécutant: kubectl get ing $ingress_name"
    echo "ou: kubectl get svc nginx-ingress-ingress-nginx-controller"
else
    print_success "Adresse IP de l'Ingress: $ip"
    echo -e "${YELLOW}Ajoutez la ligne suivante à votre fichier /etc/hosts:${NC}"
    echo "$ip $host_name"
    
    print_question "Voulez-vous ajouter cette entrée automatiquement à /etc/hosts? (o/n): "
    read add_hosts
    if [[ $add_hosts =~ ^[oO]$ ]]; then
        echo "Essai d'ajout à /etc/hosts (peut nécessiter sudo)..."
        echo "$ip $host_name" | sudo tee -a /etc/hosts > /dev/null
        if [ $? -eq 0 ]; then
            print_success "Entrée ajoutée à /etc/hosts"
        else
            print_error "Erreur lors de l'ajout à /etc/hosts. Veuillez l'ajouter manuellement."
        fi
    fi
fi

# Résumé final
print_section "Déploiement terminé!"
echo "Déploiement: $deployment_name"
echo "Service: $service_name"
echo "Ingress: $ingress_name"
echo "Nom d'hôte: $host_name"

if [ ! -z "$ip" ]; then
    echo -e "\n${GREEN}Pour accéder à votre application, ouvrez: http://$host_name${NC}"
fi

print_section "Commandes utiles"
echo "kubectl get pods                   # Voir les pods"
echo "kubectl get svc                    # Voir les services"
echo "kubectl get ing                    # Voir les ingress"
echo "kubectl describe ing $ingress_name # Détails de l'ingress"

# Demander si l'utilisateur veut nettoyer les fichiers YAML
print_question "Voulez-vous supprimer les fichiers YAML générés? (o/n): "
read clean_files
if [[ $clean_files =~ ^[oO]$ ]]; then
    rm -f ${deployment_name}-deploy.yaml ${service_name}.yaml ${ingress_name}.yaml
    print_success "Fichiers YAML supprimés"
fi

print_success "Script terminé!"
