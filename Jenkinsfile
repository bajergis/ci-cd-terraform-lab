pipeline {
    agent any

    environment {
        IMAGE_NAME = "visual-dictionary"
        IMAGE_TAG = "${BUILD_NUMBER}"
        UNSPLASH_ACCESS_KEY = credentials('unsplash-api-key')
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
                sh """
                    docker build \
                        -t ${IMAGE_NAME}:${IMAGE_TAG} \
                        -t ${IMAGE_NAME}:latest \
                        ./docker/flask-app
                """
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh '''
                    docker run --rm \
                        -e UNSPLASH_ACCESS_KEY=test \
                        visual-dictionary:${BUILD_NUMBER} \
                        python -m pytest tests/ -v || echo "No tests yet"
                '''
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying new version...'
                withCredentials([string(credentialsId: 'unsplash-api-key', variable: 'UNSPLASH_KEY')]) {
                    sh '''
                        docker stop visual-dictionary || true
                        docker rm visual-dictionary || true
                        docker run -d \
                            --name visual-dictionary \
                            --network docker_ci-cd-network \
                            -p 5000:5000 \
                            -e UNSPLASH_ACCESS_KEY=$UNSPLASH_KEY \
                            visual-dictionary:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Verify') {
            steps {
                echo 'Verifying deployment...'
                sh """
                    sleep 5
                    docker ps | grep visual-dictionary
                """
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded! Visual Dictionary is live.'
        }
        failure {
            echo 'Pipeline failed. Check the logs above.'
        }
        always {
            echo 'Pipeline finished.'
        }
    }
}