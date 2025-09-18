#!/bin/bash

# Jenkins VM Setup Script
# Run this on your GCP VM after SSH connection

set -e  # Exit on any error

echo "🚀 Starting Jenkins VM Setup..."
echo "=================================================="

# Update system
echo "📦 Step 1: Updating system packages..."
sudo apt update -y
sudo apt upgrade -y

# Install Java
echo "☕ Step 2: Installing Java..."
sudo apt install openjdk-11-jdk -y

# Verify Java installation
echo "✅ Java version:"
java -version

# Install Jenkins
echo "🔧 Step 3: Installing Jenkins..."
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update -y
sudo apt install jenkins -y

# Start Jenkins
echo "🎯 Step 4: Starting Jenkins..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check Jenkins status
echo "✅ Jenkins status:"
sudo systemctl status jenkins --no-pager

# Install Docker
echo "🐳 Step 5: Installing Docker..."
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

# Add users to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker $USER

echo "✅ Docker status:"
sudo systemctl status docker --no-pager

# Install kubectl
echo "⚙️ Step 6: Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "✅ kubectl version:"
kubectl version --client

# Install gcloud CLI
echo "☁️ Step 7: Installing gcloud CLI..."
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt update -y
sudo apt install google-cloud-cli -y

echo "✅ gcloud version:"
gcloud version

# Restart services to apply group changes
echo "🔄 Step 8: Restarting services..."
sudo systemctl restart jenkins
sudo systemctl restart docker

# Wait for Jenkins to start
echo "⏳ Waiting for Jenkins to fully start..."
sleep 30

echo ""
echo "🎉 INSTALLATION COMPLETED SUCCESSFULLY!"
echo "=================================================="
echo ""
echo "🔑 Your Jenkins initial admin password is:"
echo "=================================================="
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo "=================================================="
echo ""
echo "🌐 Access Jenkins at: http://$(curl -s ifconfig.me):8080"
echo ""
echo "📋 Next Steps:"
echo "1. Copy the password above"
echo "2. Open Jenkins in your browser"
echo "3. Complete the setup wizard"
echo "4. Install suggested plugins"
echo ""
echo "✅ Setup complete! Jenkins is ready for configuration."