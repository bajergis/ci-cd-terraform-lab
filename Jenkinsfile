pipeline {
    agent any

    environment {
        AWS_REGION          = "us-east-2"
        ECR_REPO            = "397845934685.dkr.ecr.us-east-2.amazonaws.com/visual-dictionary"
        CLUSTER_NAME        = "ci-cd-lab-cluster"
        IMAGE_TAG           = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        # Install AWS CLI if not present
                        which aws || apt-get install -y awscli

                        # Authenticate with ECR
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        aws ecr get-login-password --region $AWS_REGION | \
                            docker login --username AWS --password-stdin $ECR_REPO

                        # Build for linux/amd64 to match EKS nodes
                        docker build --platform linux/amd64 \
                            -t $ECR_REPO:$IMAGE_TAG \
                            -t $ECR_REPO:latest \
                            ./docker/flask-app
                    '''
                }
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh '''
                    docker run --rm \
                        -e UNSPLASH_ACCESS_KEY=test \
                        $ECR_REPO:$IMAGE_TAG \
                        python -m pytest tests/ -v
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                echo 'Pushing image to ECR...'
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        docker push $ECR_REPO:$IMAGE_TAG
                        docker push $ECR_REPO:latest
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo 'Deploying to EKS...'
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        # Update kubeconfig to point at EKS
                        aws eks update-kubeconfig \
                            --region $AWS_REGION \
                            --name $CLUSTER_NAME

                        # Roll out new image
                        kubectl set image deployment/visual-dictionary \
                            visual-dictionary=$ECR_REPO:$IMAGE_TAG \
                            -n visual-dictionary

                        # Wait for rollout to complete
                        kubectl rollout status deployment/visual-dictionary \
                            -n visual-dictionary
                    '''
                }
            }
        }

        stage('Verify') {
            steps {
                echo 'Verifying deployment...'
                sh '''
                    kubectl get pods -n visual-dictionary
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline succeeded! Visual Dictionary is live on EKS.'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above.'
        }
        always {
            echo 'Pipeline finished.'
        }
    }
}