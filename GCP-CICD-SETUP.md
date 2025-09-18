# GCP CI/CD Pipeline Setup for Campus Connect

## Project Overview
- **Project ID**: `devops-cc-472518`
- **Zone**: `asia-south1-a` (Mumbai)
- **Application**: Campus Connect (Frontend + Backend)
- **Flow**: GitHub Commit → Jenkins Test → Build → GCR → GKE → Live App

## Prerequisites
1. GCP Project created: `devops-cc-472518`
2. GitHub repository with Campus Connect code
3. Local machine with gcloud CLI installed

## Phase 1: Initial GCP Setup

### 1.1 Install and Configure gcloud CLI
```bash
# Install gcloud CLI (if not already installed)
# Follow: https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth login

# Set project
gcloud config set project devops-cc-472518

# Set default zone
gcloud config set compute/zone asia-south1-a

# Set default region
gcloud config set compute/region asia-south1

# Verify configuration
gcloud config list
```

### 1.2 Enable Required APIs
```bash
# Enable necessary APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable storage-api.googleapis.com
gcloud services enable storage-component.googleapis.com

# Verify enabled services
gcloud services list --enabled
```

## Phase 2: Infrastructure Setup

### 2.1 Create Jenkins VM
```bash
# Create Jenkins VM instance
gcloud compute instances create jenkins-server \
    --zone=asia-south1-a \
    --machine-type=e2-medium \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account=jenkins-sa@devops-cc-472518.iam.gserviceaccount.com \
    --scopes=https://www.googleapis.com/auth/cloud-platform \
    --tags=jenkins-server,http-server,https-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=jenkins-server,image=projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20231213,mode=rw,size=20,type=projects/devops-cc-472518/zones/asia-south1-a/diskTypes/pd-standard \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels=environment=production,role=jenkins \
    --reservation-affinity=any

# Create firewall rules for Jenkins
gcloud compute firewall-rules create allow-jenkins \
    --allow tcp:8080,tcp:22 \
    --source-ranges 0.0.0.0/0 \
    --target-tags jenkins-server \
    --description="Allow Jenkins and SSH access"

# Get Jenkins VM external IP
gcloud compute instances describe jenkins-server --zone=asia-south1-a --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

### 2.2 Create Service Account for Jenkins
```bash
# Create Jenkins service account
gcloud iam service-accounts create jenkins-sa \
    --description="Service account for Jenkins" \
    --display-name="Jenkins Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding devops-cc-472518 \
    --member="serviceAccount:jenkins-sa@devops-cc-472518.iam.gserviceaccount.com" \
    --role="roles/container.developer"

gcloud projects add-iam-policy-binding devops-cc-472518 \
    --member="serviceAccount:jenkins-sa@devops-cc-472518.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding devops-cc-472518 \
    --member="serviceAccount:jenkins-sa@devops-cc-472518.iam.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.editor"

# Create and download service account key
gcloud iam service-accounts keys create ~/jenkins-sa-key.json \
    --iam-account=jenkins-sa@devops-cc-472518.iam.gserviceaccount.com
```

### 2.3 Setup Google Container Registry
```bash
# Configure Docker authentication for GCR
gcloud auth configure-docker

# Create a test image to initialize GCR
echo "FROM hello-world" > Dockerfile.test
docker build -t gcr.io/devops-cc-472518/test-image:v1 -f Dockerfile.test .
docker push gcr.io/devops-cc-472518/test-image:v1
rm Dockerfile.test

# Verify GCR setup
gcloud container images list
```

### 2.4 Create GKE Cluster
```bash
# Create GKE cluster
gcloud container clusters create campusconnect-cluster \
    --zone=asia-south1-a \
    --num-nodes=2 \
    --machine-type=e2-medium \
    --disk-size=20GB \
    --enable-autoscaling \
    --min-nodes=1 \
    --max-nodes=4 \
    --enable-autorepair \
    --enable-autoupgrade \
    --labels=environment=production,app=campusconnect

# Get cluster credentials
gcloud container clusters get-credentials campusconnect-cluster --zone=asia-south1-a

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

## Phase 3: Jenkins Configuration

### 3.1 Install Jenkins on VM
```bash
# SSH into Jenkins VM
gcloud compute ssh jenkins-server --zone=asia-south1-a

# Update system
sudo apt update && sudo apt upgrade -y

# Install Java
sudo apt install openjdk-11-jdk -y

# Add Jenkins repository
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Docker
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install gcloud CLI
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt update && sudo apt install google-cloud-cli -y

# Get Jenkins initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 3.2 Configure Jenkins
1. Access Jenkins at `http://[JENKINS_VM_IP]:8080`
2. Use initial admin password
3. Install suggested plugins
4. Create admin user
5. Install additional plugins:
   - Google Kubernetes Engine Plugin
   - Docker Pipeline
   - GitHub Integration Plugin

## Phase 4: GitHub Actions Setup

### 4.1 Create GitHub Secrets
In your GitHub repository, go to Settings → Secrets and variables → Actions, and add:

- `GCP_PROJECT_ID`: `devops-cc-472518`
- `GCP_SA_KEY`: Contents of `jenkins-sa-key.json`
- `GKE_CLUSTER`: `campusconnect-cluster`
- `GKE_ZONE`: `asia-south1-a`
- `JENKINS_URL`: `http://[JENKINS_VM_IP]:8080`
- `JENKINS_USER`: Your Jenkins username
- `JENKINS_TOKEN`: Jenkins API token

## Phase 5: File Commits and Configuration

### Commit 1: GitHub Actions Workflow
Create `.github/workflows/cicd.yml`

### Commit 2: Update Kubernetes Manifests for GCR
Update `k8s/` files to use GCR images

### Commit 3: Jenkins Pipeline Configuration
Create `Jenkinsfile`

### Commit 4: Docker Optimization
Update Dockerfiles for production

### Commit 5: Environment Configuration
Add production environment configs

## Verification Commands

### Check GCR Images
```bash
gcloud container images list --repository=gcr.io/devops-cc-472518
```

### Check GKE Deployments
```bash
kubectl get deployments -n default
kubectl get services -n default
kubectl get pods -n default
```

### Monitor Jenkins
```bash
# Check Jenkins status
sudo systemctl status jenkins

# View Jenkins logs
sudo journalctl -u jenkins -f
```

## Troubleshooting

### Common Issues
1. **Permission denied errors**: Check service account permissions
2. **Image pull errors**: Verify GCR authentication
3. **Cluster access issues**: Re-run `gcloud container clusters get-credentials`
4. **Jenkins connectivity**: Check firewall rules and VM status

### Useful Commands
```bash
# Reset cluster credentials
gcloud container clusters get-credentials campusconnect-cluster --zone=asia-south1-a

# Check node status
kubectl get nodes -o wide

# Describe problematic pods
kubectl describe pod [POD_NAME]

# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log
```

## Next Steps
After completing this setup, you'll have a complete CI/CD pipeline where:
1. Code commits trigger GitHub Actions
2. GitHub Actions trigger Jenkins jobs
3. Jenkins runs tests and builds Docker images
4. Images are pushed to GCR
5. GKE deployments are updated automatically
6. Application goes live

## Security Considerations
- Use least privilege access for service accounts
- Regularly rotate service account keys
- Enable GKE security features like Workload Identity
- Monitor resource usage and costs
- Set up proper backup strategies for Jenkins configuration