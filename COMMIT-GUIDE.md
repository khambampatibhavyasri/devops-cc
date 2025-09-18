# Step-by-Step Commit Guide for GCP CI/CD Setup

Follow these commits in order to set up your complete CI/CD pipeline.

## Prerequisites Checklist
- [ ] GCP Project created: `devops-cc-472518`
- [ ] gcloud CLI installed and configured
- [ ] GitHub repository ready
- [ ] All GCP APIs enabled (run the commands from GCP-CICD-SETUP.md)

## Commit 1: Infrastructure Setup Documentation
**Purpose**: Add comprehensive setup documentation

### Files to Add:
```bash
git add GCP-CICD-SETUP.md
git commit -m "docs: Add comprehensive GCP CI/CD setup documentation

- Complete infrastructure setup guide for GCP
- Jenkins VM configuration steps
- GKE cluster setup in Mumbai zone (asia-south1-a)
- Service account and permissions configuration
- Step-by-step gcloud CLI commands

🤖 Generated with Claude Code"
```

## Commit 2: GitHub Actions Workflow
**Purpose**: Add CI/CD pipeline automation

### Files to Add:
```bash
git add .github/workflows/cicd.yml
git commit -m "ci: Add GitHub Actions CI/CD workflow

- Automated testing for frontend and backend
- Jenkins job triggering on main branch commits
- Docker image building and pushing to GCR
- Automated GKE deployment
- Success/failure notifications

Features:
- Runs tests on every PR and push
- Triggers Jenkins for additional testing
- Deploys to GKE only on main branch
- Uses GCR for container registry

🤖 Generated with Claude Code"
```

## Commit 3: Jenkins Pipeline Configuration
**Purpose**: Add Jenkins declarative pipeline

### Files to Add:
```bash
git add Jenkinsfile
git commit -m "ci: Add Jenkins declarative pipeline

- Comprehensive testing stages for frontend and backend
- Docker image building and pushing to GCR
- Automated deployment to GKE cluster
- Health checks and rollout verification
- Cleanup and post-deployment steps

Pipeline stages:
1. Checkout code
2. Environment setup
3. Frontend tests
4. Backend tests
5. Build Docker images
6. Push to GCR
7. Deploy to GKE
8. Health checks

🤖 Generated with Claude Code"
```

## Commit 4: Update Kubernetes Manifests for GCR
**Purpose**: Configure K8s deployments to use Google Container Registry

### Files to Modify:
```bash
git add k8s/frontend-deployment.yaml k8s/backend-deployment.yaml
git commit -m "k8s: Update deployments to use GCR images

- Changed image sources to gcr.io/devops-cc-472518/
- Updated imagePullPolicy to Always for latest images
- Configured for production GKE deployment

Images:
- Frontend: gcr.io/devops-cc-472518/campusconnect-frontend:latest
- Backend: gcr.io/devops-cc-472518/campusconnect-backend:latest

🤖 Generated with Claude Code"
```

## Commit 5: Production Dockerfile Optimization
**Purpose**: Optimize Dockerfiles for production deployment

### Create/Update Files:
```bash
# If your Dockerfiles need optimization, add them here
git add server/Dockerfile cc/Dockerfile
git commit -m "docker: Optimize Dockerfiles for production deployment

- Multi-stage builds for smaller image sizes
- Non-root user configuration for security
- Production environment optimizations
- Health check configurations

🤖 Generated with Claude Code"
```

## Commit 6: Environment Configuration
**Purpose**: Add production environment configurations

### Files to Add/Modify:
```bash
# Create production environment files if needed
touch .env.production
echo "NODE_ENV=production" > .env.production

git add .env.production k8s/configmap.yaml
git commit -m "config: Add production environment configuration

- Production environment variables
- Updated ConfigMap for GKE deployment
- Secure configuration management
- Environment-specific settings

🤖 Generated with Claude Code"
```

## Commit 7: Add Step-by-Step Guide
**Purpose**: Document the commit process

### Files to Add:
```bash
git add COMMIT-GUIDE.md
git commit -m "docs: Add step-by-step commit guide for CI/CD setup

- Detailed commit sequence for proper setup
- File-by-file commit organization
- Prerequisites and verification steps
- Troubleshooting guidance

🤖 Generated with Claude Code"
```

## After All Commits: Setup Infrastructure

### Step 1: Run Infrastructure Commands
Execute all commands from `GCP-CICD-SETUP.md` in order:

```bash
# 1. Configure gcloud
gcloud config set project devops-cc-472518
gcloud config set compute/zone asia-south1-a

# 2. Enable APIs
gcloud services enable compute.googleapis.com container.googleapis.com containerregistry.googleapis.com

# 3. Create Jenkins VM
gcloud compute instances create jenkins-server --zone=asia-south1-a --machine-type=e2-medium

# 4. Create GKE cluster
gcloud container clusters create campusconnect-cluster --zone=asia-south1-a --num-nodes=2

# 5. Setup service accounts and permissions
# (Follow complete commands from GCP-CICD-SETUP.md)
```

### Step 2: Configure GitHub Secrets
In your GitHub repo → Settings → Secrets and variables → Actions:

- `GCP_PROJECT_ID`: `devops-cc-472518`
- `GCP_SA_KEY`: (Service account JSON key content)
- `GKE_CLUSTER`: `campusconnect-cluster`
- `GKE_ZONE`: `asia-south1-a`
- `JENKINS_URL`: `http://[JENKINS_VM_IP]:8080`
- `JENKINS_USER`: (Your Jenkins username)
- `JENKINS_TOKEN`: (Jenkins API token)

### Step 3: Setup Jenkins
1. SSH into Jenkins VM and install Jenkins (follow GCP-CICD-SETUP.md)
2. Access Jenkins UI and complete setup
3. Install required plugins
4. Create the `campusconnect-pipeline` job
5. Configure the job to use your GitHub repository

### Step 4: Test the Pipeline
```bash
# Make a small change to trigger the pipeline
echo "# Campus Connect" > README.md
git add README.md
git commit -m "test: Trigger CI/CD pipeline test"
git push origin main
```

## Verification Steps

### 1. Check GitHub Actions
- Go to your repo → Actions tab
- Verify workflow runs successfully

### 2. Check Jenkins
- Access Jenkins UI
- Verify job runs and completes

### 3. Check GCR
```bash
gcloud container images list --repository=gcr.io/devops-cc-472518
```

### 4. Check GKE Deployment
```bash
kubectl get deployments
kubectl get services
kubectl get pods
```

### 5. Access Your Application
```bash
# Get external IPs
kubectl get services

# Access frontend at http://[FRONTEND_IP]:30000
# Access backend at http://[BACKEND_IP]:30001
```

## Troubleshooting

### Common Issues and Solutions

1. **Permission Errors**
   ```bash
   # Check service account permissions
   gcloud projects get-iam-policy devops-cc-472518
   ```

2. **Image Pull Errors**
   ```bash
   # Verify GCR authentication
   gcloud auth configure-docker
   ```

3. **Cluster Connection Issues**
   ```bash
   # Re-authenticate with cluster
   gcloud container clusters get-credentials campusconnect-cluster --zone=asia-south1-a
   ```

4. **Jenkins Connection Issues**
   ```bash
   # Check Jenkins VM status
   gcloud compute instances list
   # Check firewall rules
   gcloud compute firewall-rules list
   ```

## Success Indicators

✅ **Pipeline Working When:**
- GitHub Actions runs successfully
- Jenkins job completes without errors
- Images appear in GCR
- Pods are running in GKE
- Application is accessible via external IPs
- New commits trigger automatic deployments

## Next Steps

After successful setup:
1. Configure monitoring and logging
2. Set up alerting for failed deployments
3. Implement backup strategies
4. Add security scanning to pipeline
5. Configure auto-scaling policies
6. Set up staging environment

## Support

If you encounter issues:
1. Check the logs in GitHub Actions
2. Review Jenkins console output
3. Examine pod logs: `kubectl logs [pod-name]`
4. Verify all secrets are correctly set
5. Ensure all GCP APIs are enabled

Remember: This setup creates a production-ready CI/CD pipeline that will automatically deploy your Campus Connect application to GKE whenever you push to the main branch!