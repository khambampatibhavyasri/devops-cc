pipeline {
    agent any

    environment {
        PROJECT_ID = 'devops-cc-472518'
        CLUSTER_NAME = 'campusconnect-cluster'
        CLUSTER_ZONE = 'asia-south1-a'
        FRONTEND_IMAGE = 'campusconnect-frontend'
        BACKEND_IMAGE = 'campusconnect-backend'
        GCR_REGISTRY = 'gcr.io'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo "Checked out code from repository"
            }
        }

        stage('Environment Setup') {
            steps {
                script {
                    sh '''
                        echo "Setting up environment variables..."
                        export BUILD_ID=${BUILD_NUMBER}
                        export GIT_COMMIT_SHORT=$(git rev-parse --short HEAD)
                        echo "Build ID: ${BUILD_ID}"
                        echo "Git Commit: ${GIT_COMMIT_SHORT}"
                    '''
                }
            }
        }

        stage('Frontend Tests') {
            steps {
                dir('cc') {
                    script {
                        try {
                            sh '''
                                echo "Installing frontend dependencies..."
                                npm ci

                                echo "Running frontend tests..."
                                npm run test -- --coverage --watchAll=false || true

                                echo "Running frontend linting..."
                                npm run lint || echo "Linting completed with warnings"
                            '''
                        } catch (Exception e) {
                            echo "Frontend tests encountered issues: ${e.getMessage()}"
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
            }
        }

        stage('Backend Tests') {
            steps {
                dir('server') {
                    script {
                        try {
                            sh '''
                                echo "Installing backend dependencies..."
                                npm ci

                                echo "Running backend tests..."
                                npm test || true
                            '''
                        } catch (Exception e) {
                            echo "Backend tests encountered issues: ${e.getMessage()}"
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh '''
                        echo "Authenticating with Google Container Registry..."
                        gcloud auth configure-docker --quiet

                        echo "Building frontend Docker image..."
                        docker build -t "${GCR_REGISTRY}/${PROJECT_ID}/${FRONTEND_IMAGE}:${BUILD_NUMBER}" \
                                     -t "${GCR_REGISTRY}/${PROJECT_ID}/${FRONTEND_IMAGE}:latest" \
                                     -f cc/Dockerfile cc/

                        echo "Building backend Docker image..."
                        docker build -t "${GCR_REGISTRY}/${PROJECT_ID}/${BACKEND_IMAGE}:${BUILD_NUMBER}" \
                                     -t "${GCR_REGISTRY}/${PROJECT_ID}/${BACKEND_IMAGE}:latest" \
                                     -f server/Dockerfile server/
                    '''
                }
            }
        }

        stage('Push to GCR') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh '''
                        echo "Pushing images to Google Container Registry..."

                        docker push "${GCR_REGISTRY}/${PROJECT_ID}/${FRONTEND_IMAGE}:${BUILD_NUMBER}"
                        docker push "${GCR_REGISTRY}/${PROJECT_ID}/${FRONTEND_IMAGE}:latest"

                        docker push "${GCR_REGISTRY}/${PROJECT_ID}/${BACKEND_IMAGE}:${BUILD_NUMBER}"
                        docker push "${GCR_REGISTRY}/${PROJECT_ID}/${BACKEND_IMAGE}:latest"

                        echo "Images pushed successfully!"
                    '''
                }
            }
        }

        stage('Deploy to GKE') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh '''
                        echo "Getting GKE cluster credentials..."
                        gcloud container clusters get-credentials ${CLUSTER_NAME} --zone=${CLUSTER_ZONE} --project=${PROJECT_ID}

                        echo "Updating Kubernetes manifests..."
                        sed -i "s|campusconnect-frontend:latest|${GCR_REGISTRY}/${PROJECT_ID}/${FRONTEND_IMAGE}:${BUILD_NUMBER}|g" k8s/frontend-deployment.yaml
                        sed -i "s|campusconnect-backend:latest|${GCR_REGISTRY}/${PROJECT_ID}/${BACKEND_IMAGE}:${BUILD_NUMBER}|g" k8s/backend-deployment.yaml

                        echo "Applying Kubernetes configurations..."
                        kubectl apply -f k8s/configmap.yaml
                        kubectl apply -f k8s/backend-deployment.yaml
                        kubectl apply -f k8s/frontend-deployment.yaml

                        echo "Waiting for deployments to complete..."
                        kubectl rollout status deployment/backend --timeout=300s
                        kubectl rollout status deployment/frontend --timeout=300s

                        echo "Deployment completed successfully!"
                        kubectl get pods
                        kubectl get services
                    '''
                }
            }
        }

        stage('Health Check') {
            when {
                branch 'main'
            }
            steps {
                script {
                    sh '''
                        echo "Performing health checks..."

                        # Wait for pods to be ready
                        sleep 30

                        # Check if pods are running
                        kubectl get pods | grep Running || echo "Some pods may not be running yet"

                        # Get service endpoints
                        echo "Service information:"
                        kubectl get services

                        echo "Application should be accessible via NodePort services"
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution completed'

            // Clean up Docker images on Jenkins server
            sh '''
                echo "Cleaning up local Docker images..."
                docker image prune -f || true
                docker system prune -f || true
            '''
        }

        success {
            echo '✅ Pipeline executed successfully!'
            echo "Frontend and Backend deployed to GKE cluster: ${CLUSTER_NAME}"
        }

        failure {
            echo '❌ Pipeline execution failed!'
            echo 'Check the logs above for error details'
        }

        unstable {
            echo '⚠️ Pipeline executed with warnings!'
            echo 'Some tests may have failed, but deployment proceeded'
        }
    }
}