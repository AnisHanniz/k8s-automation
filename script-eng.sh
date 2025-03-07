#!/bin/bash

# Styles for display
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display section titles
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Function to display success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to display question prompts
print_question() {
    echo -e "${YELLOW}? $1${NC}"
}

# Function to display errors
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install it before continuing."
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed. Please install it before continuing."
    exit 1
fi

print_section "Welcome to the Nginx with Ingress deployment script"

# User configuration of variables
print_question "Deployment name [nginx]: "
read deployment_name
deployment_name=${deployment_name:-nginx}

print_question "Number of replicas [2]: "
read replicas
replicas=${replicas:-2}

print_question "Docker image [nginx:latest]: "
read image
image=${image:-nginx:latest}

print_question "Service name [${deployment_name}-service]: "
read service_name
service_name=${service_name:-${deployment_name}-service}

print_question "Service port [80]: "
read service_port
service_port=${service_port:-80}

print_question "Ingress name [${deployment_name}-ingress]: "
read ingress_name
ingress_name=${ingress_name:-${deployment_name}-ingress}

print_question "Ingress class name [nginx]: "
read ingress_class
ingress_class=${ingress_class:-nginx}

print_question "Hostname for Ingress [example.local]: "
read host_name
host_name=${host_name:-example.local}

# Ask for confirmation
echo -e "\n${YELLOW}Configuration summary:${NC}"
echo "Deployment: $deployment_name with $replicas replicas using image $image"
echo "Service: $service_name on port $service_port"
echo "Ingress: $ingress_name with class $ingress_class for host $host_name"

print_question "Do you want to continue? (y/n): "
read confirmation
if [[ ! $confirmation =~ ^[yY]$ ]]; then
    print_error "Installation canceled."
    exit 1
fi

# 1. Create the deployment
print_section "Creating Deployment"
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
    print_success "Deployment created successfully"
else
    print_error "Error creating deployment"
    exit 1
fi

# 2. Create the Service
print_section "Creating Service"
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
    print_success "Service created successfully"
else
    print_error "Error creating service"
    exit 1
fi

# 3. Install the Ingress Controller if needed
print_section "Installing Ingress Controller"
print_question "Do you want to install the Nginx Ingress Controller? (y/n): "
read install_ingress_controller
if [[ $install_ingress_controller =~ ^[yY]$ ]]; then
    echo "Installing Nginx Ingress Controller..."
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update
    helm install nginx-ingress ingress-nginx/ingress-nginx
    if [ $? -eq 0 ]; then
        print_success "Ingress Controller installed successfully"
    else
        print_error "Error installing Ingress Controller"
        exit 1
    fi
else
    print_success "Skipping Ingress Controller installation"
fi

# Wait for the Ingress Controller to be ready
print_section "Waiting for Ingress Controller to be ready"
echo "Please wait..."
kubectl wait --namespace default --for=condition=ready pod --selector=app.kubernetes.io/name=ingress-nginx --timeout=90s
if [ $? -eq 0 ]; then
    print_success "Ingress Controller is ready"
else
    print_error "Ingress Controller is not available, but we'll continue..."
fi

# 4. Create the Ingress
print_section "Creating Ingress"
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
    print_success "Ingress created successfully"
else
    print_error "Error creating Ingress"
    exit 1
fi

# 5. Get the Ingress IP address
print_section "Final configuration"
echo "Waiting for Ingress to be assigned an IP address (this may take a moment)..."
sleep 10

ip=""
attempt=0
while [ -z "$ip" ] && [ $attempt -lt 12 ]; do
    ip=$(kubectl get ing $ingress_name -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -z "$ip" ]; then
        ip=$(kubectl get svc nginx-ingress-ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    fi
    
    if [ -z "$ip" ]; then
        echo "Waiting for IP address... (attempt $attempt/12)"
        sleep 10
        attempt=$((attempt+1))
    fi
done

if [ -z "$ip" ]; then
    print_error "Could not obtain Ingress IP address after multiple attempts."
    echo "You can get it by running: kubectl get ing $ingress_name"
    echo "or: kubectl get svc nginx-ingress-ingress-nginx-controller"
else
    print_success "Ingress IP address: $ip"
    echo -e "${YELLOW}Add the following line to your /etc/hosts file:${NC}"
    echo "$ip $host_name"
    
    print_question "Would you like to add this entry automatically to /etc/hosts? (y/n): "
    read add_hosts
    if [[ $add_hosts =~ ^[yY]$ ]]; then
        echo "Trying to add to /etc/hosts (may require sudo)..."
        echo "$ip $host_name" | sudo tee -a /etc/hosts > /dev/null
        if [ $? -eq 0 ]; then
            print_success "Entry added to /etc/hosts"
        else
            print_error "Error adding to /etc/hosts. Please add it manually."
        fi
    fi
fi

# Final summary
print_section "Deployment completed!"
echo "Deployment: $deployment_name"
echo "Service: $service_name"
echo "Ingress: $ingress_name"
echo "Hostname: $host_name"

if [ ! -z "$ip" ]; then
    echo -e "\n${GREEN}To access your application, open: http://$host_name${NC}"
fi

print_section "Useful commands"
echo "kubectl get pods                   # View pods"
echo "kubectl get svc                    # View services"
echo "kubectl get ing                    # View ingresses"
echo "kubectl describe ing $ingress_name # View ingress details"

# Ask if the user wants to clean up YAML files
print_question "Would you like to delete the generated YAML files? (y/n): "
read clean_files
if [[ $clean_files =~ ^[yY]$ ]]; then
    rm -f ${deployment_name}-deploy.yaml ${service_name}.yaml ${ingress_name}.yaml
    print_success "YAML files deleted"
fi

print_success "Script completed!"
