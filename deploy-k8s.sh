#!/bin/bash

# Clean up existing deployments
echo "Cleaning up existing deployments..."
kubectl delete deployments frontend backend --ignore-not-found
kubectl delete services frontend-service backend-service --ignore-not-found
kubectl delete configmap frontend-config --ignore-not-found

# Wait for resources to be deleted
echo "Waiting for resources to be deleted..."
sleep 5

# Build Docker images
echo "Building Docker images..."
docker build -t campusconnect-frontend:latest ./cc
docker build -t campusconnect-backend:latest ./server

# Create kubernetes deployments
echo "Creating Kubernetes deployments..."
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/backend-deployment.yaml
sleep 5  # Wait for backend to start before frontend
kubectl apply -f k8s/frontend-deployment.yaml

echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s
kubectl wait --for=condition=ready pod -l app=frontend --timeout=120s

# Verify the services
echo "Verifying services..."
kubectl get pods
kubectl get services

# Check pod logs
echo "Checking backend logs..."
kubectl logs -l app=backend --tail=50
echo "Checking frontend logs..."
kubectl logs -l app=frontend --tail=50

echo "Deployments are ready!"
echo "Frontend is available at: http://localhost:30000"
echo "Backend is available at: http://localhost:30001/api"

# Test backend endpoints
echo "Testing backend endpoints..."
echo "Testing students endpoint..."
Invoke-WebRequest -Uri "http://localhost:30001/api/students" -Method GET -UseBasicParsing
echo "Testing clubs endpoint..."
Invoke-WebRequest -Uri "http://localhost:30001/api/clubs" -Method GET -UseBasicParsing

# Print important environment variables
echo "Checking frontend environment..."
$POD_NAME = kubectl get pod -l app=frontend -o jsonpath="{.items[0].metadata.name}"
kubectl exec -it $POD_NAME -- printenv | Select-String "REACT_APP|WDS"
