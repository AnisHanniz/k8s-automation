# k8s-proxmox-automation
# FR
# Script de Déploiement Nginx avec Ingress

Un script interactif simple pour déployer Nginx et Ingress et Kubernetes.

## Aperçu

Ce script automatise le processus de déploiement d'une application Nginx sur un cluster Kubernetes et configure un Ingress pour la rendre accessible. Il offre une interface interactive conviviale qui vous guide tout au long du processus, vous permettant de personnaliser divers paramètres.

## README

```markdown
# Script de Déploiement Nginx avec Ingress

Un script bash interactif pour déployer facilement Nginx avec Ingress sur Kubernetes.

## Fonctionnalités

- Déployer Nginx avec des paramètres personnalisables
- Créer un Service Kubernetes
- Installer le contrôleur Nginx Ingress (optionnel)
- Configurer les règles d'Ingress
- Détecter automatiquement l'adresse IP de l'Ingress
- Ajouter le nom d'hôte au fichier /etc/hosts (optionnel)
- Sortie claire et colorée pour une meilleure lisibilité

## Prérequis

- Cluster Kubernetes opérationnel
- `kubectl` installé et configuré
- `helm` installé
- Accès sudo (pour la modification de /etc/hosts, optionnel)

## Installation

1. Téléchargez le script :
   ```
   curl -O https://raw.githubusercontent.com/AnisHanniz/k8s-proxmox-automation/main/script-fr.sh
   ```

2. Rendez le script exécutable :
   ```
   chmod +x script-fr.sh
   ```

## Utilisation

Exécutez le script :
```
./script-fr.sh
```

Suivez les instructions interactives pour configurer votre déploiement.

## Options de personnalisation

Le script vous permet de personnaliser :
- Nom du déploiement
- Nombre de réplicas
- Image Docker
- Nom et port du service
- Nom, classe et nom d'hôte de l'Ingress

## Après le déploiement

Une fois le déploiement terminé, vous pouvez accéder à votre instance Nginx en :
1. Naviguant vers le nom d'hôte que vous avez configuré dans votre navigateur
2. Utilisant directement l'adresse IP

Utilisez les commandes kubectl fournies pour vérifier l'état de votre déploiement.

## Nettoyage

Pour supprimer le déploiement :
```
kubectl delete ing <nom-ingress>
kubectl delete svc <nom-service>
kubectl delete deploy <nom-deploiement>
```

Si vous avez installé le contrôleur Ingress :
```
helm uninstall nginx-ingress
```

## Licence

MIT
```

## Description (pour documentation ou marketing)

Le Script de Déploiement Nginx avec Ingress simplifie le processus de déploiement d'applications web sur Kubernetes. Cet outil convivial élimine la complexité de la création manuelle de fichiers YAML et de l'exécution de multiples commandes en proposant une interface interactive étape par étape.

Avec ce script, vous pouvez :
- Déployer un serveur web Nginx avec la configuration souhaitée
- Rendre votre application accessible via un nom d'hôte personnalisé
- Configurer un contrôleur Ingress pour gérer l'accès externe aux services
- Automatiser la configuration des règles de routage

Que vous soyez débutant sur Kubernetes cherchant à comprendre le fonctionnement d'Ingress ou un développeur expérimenté souhaitant simplifier votre workflow, ce script offre un moyen pratique de déployer des applications web avec une configuration réseau appropriée en quelques minutes.

La sortie colorée et les invites claires permettent de comprendre facilement ce qui se passe à chaque étape, tandis que la validation intégrée aide à prévenir les erreurs de configuration courantes. Après le déploiement, le script fournit des commandes utiles pour surveiller et gérer votre application.


# ENG
## Overview

This script automates the process of deploying an Nginx application and a Kubernetes cluster and configuring an Ingress to make it accessible. It provides a user-friendly interactive interface that guides you through the entire process, allowing you to customize various parameters.

## README

```markdown
## Features

- Deploy Nginx with customizable parameters
- Create a Kubernetes Service
- Install Nginx Ingress Controller (optional)
- Configure Ingress rules
- Automatically detect the Ingress IP address
- Add hostname to /etc/hosts file (optional)
- Clean, colored output for better readability

## Prerequisites

- Kubernetes cluster running
- `kubectl` installed and configured
- `helm` installed
- Sudo access (for /etc/hosts modification, optional)

## Installation

1. Download the script:
   ```
   curl -O https://raw.githubusercontent.com/AnisHanniz/k8s-proxmox-automation/main/script-eng.sh
   ```

2. Make the script executable:
   ```
   chmod +x script-eng.sh
   ```

## Usage

Run the script:
```
./script-eng.sh
```

Follow the interactive prompts to configure your deployment.

## Customization Options

The script allows you to customize:
- Deployment name
- Number of replicas
- Docker image
- Service name and port
- Ingress name, class, and hostname

## After Deployment

Once deployment is complete, you can access your Nginx instance by:
1. Navigating to the hostname you configured in your browser
2. Using the IP address directly

Use the provided kubectl commands to check the status of your deployment.

## Cleanup

To remove the deployment:
```
kubectl delete ing <ingress-name>
kubectl delete svc <service-name>
kubectl delete deploy <deployment-name>
```

If you installed the Ingress Controller:
```
helm uninstall nginx-ingress
```

## License

MIT
```

## Description (for documentation or marketing)

The Nginx Ingress Deployment Script simplifies the process of deploying web applications on Kubernetes. This user-friendly tool eliminates the complexity of manually creating YAML files and running multiple commands by providing an interactive, step-by-step interface.

With this script, you can:
- Deploy an Nginx web server with your desired configuration
- Make your application accessible via a custom hostname
- Set up an Ingress Controller for managing external access to services
- Automate the configuration of routing rules

Whether you're a Kubernetes beginner looking to learn about Ingress or an experienced developer seeking to streamline your workflow, this script offers a convenient way to deploy web applications with proper network configuration in minutes.

The colored output and clear prompts make it easy to understand what's happening at each step, while the built-in validation helps prevent common configuration errors. After deployment, the script provides useful commands for monitoring and managing your application.
