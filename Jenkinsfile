pipeline {
    agent any

    environment {
        AWS_REGION      = "us-east-2"
        ECR_REPO_FLASK  = "397845934685.dkr.ecr.us-east-2.amazonaws.com/visual-dictionary"
        ECR_REPO_REACT  = "397845934685.dkr.ecr.us-east-2.amazonaws.com/visual-dictionary-react"
        CLUSTER_NAME    = "ci-cd-lab-cluster"
        IMAGE_TAG       = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }

        stage('Build and Push to ECR') {
            steps {
                echo 'Building and pushing Flask and React images with Kaniko...'
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        aws eks update-kubeconfig \
                            --region $AWS_REGION \
                            --name $CLUSTER_NAME

                        ECR_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION)
                        ECR_AUTH=$(echo -n "AWS:$ECR_PASSWORD" | base64 | tr -d "\\n")

                        kubectl delete secret ecr-credentials -n visual-dictionary --ignore-not-found
                        kubectl create secret generic ecr-credentials \
                            -n visual-dictionary \
                            --from-literal=config.json="{\\"auths\\":{\\"397845934685.dkr.ecr.us-east-2.amazonaws.com\\":{\\"auth\\":\\"$ECR_AUTH\\"}}}"

                        # --- Flask Kaniko job ---
                        kubectl delete job kaniko-flask-$BUILD_NUMBER -n visual-dictionary --ignore-not-found

                        cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: kaniko-flask-$BUILD_NUMBER
  namespace: visual-dictionary
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      initContainers:
      - name: git-clone
        image: alpine/git
        command:
        - git
        - clone
        - https://github.com/bajergis/ci-cd-terraform-lab
        - /workspace
        volumeMounts:
        - name: workspace
          mountPath: /workspace
      containers:
      - name: kaniko
        image: gcr.io/kaniko-project/executor:latest
        args:
        - --context=/workspace/docker/flask-app
        - --dockerfile=/workspace/docker/flask-app/Dockerfile
        - --destination=$ECR_REPO_FLASK:$IMAGE_TAG
        - --destination=$ECR_REPO_FLASK:latest
        volumeMounts:
        - name: kaniko-secret
          mountPath: /kaniko/.docker
        - name: workspace
          mountPath: /workspace
      volumes:
      - name: kaniko-secret
        secret:
          secretName: ecr-credentials
          items:
          - key: config.json
            path: config.json
      - name: workspace
        emptyDir: {}
EOF

                        # --- React Kaniko job ---
                        kubectl delete job kaniko-react-$BUILD_NUMBER -n visual-dictionary --ignore-not-found

                        cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: kaniko-react-$BUILD_NUMBER
  namespace: visual-dictionary
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      initContainers:
      - name: git-clone
        image: alpine/git
        command:
        - git
        - clone
        - https://github.com/bajergis/ci-cd-terraform-lab
        - /workspace
        volumeMounts:
        - name: workspace
          mountPath: /workspace
      containers:
      - name: kaniko
        image: gcr.io/kaniko-project/executor:latest
        args:
        - --context=/workspace/react-app
        - --dockerfile=/workspace/react-app/Dockerfile
        - --destination=$ECR_REPO_REACT:$IMAGE_TAG
        - --destination=$ECR_REPO_REACT:latest
        volumeMounts:
        - name: kaniko-secret
          mountPath: /kaniko/.docker
        - name: workspace
          mountPath: /workspace
      volumes:
      - name: kaniko-secret
        secret:
          secretName: ecr-credentials
          items:
          - key: config.json
            path: config.json
      - name: workspace
        emptyDir: {}
EOF

                        # --- Wait for both jobs to complete ---
                        kubectl wait --for=condition=complete \
                            job/kaniko-flask-$BUILD_NUMBER \
                            -n visual-dictionary \
                            --timeout=600s

                        kubectl wait --for=condition=complete \
                            job/kaniko-react-$BUILD_NUMBER \
                            -n visual-dictionary \
                            --timeout=600s
                    '''
                }
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        aws eks update-kubeconfig \
                            --region $AWS_REGION \
                            --name $CLUSTER_NAME

                        kubectl delete job pytest-$BUILD_NUMBER -n visual-dictionary --ignore-not-found

                        cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: pytest-$BUILD_NUMBER
  namespace: visual-dictionary
spec:
  ttlSecondsAfterFinished: 300
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: pytest
        image: $ECR_REPO_FLASK:$IMAGE_TAG
        command: ["python", "-m", "pytest", "tests/", "-v"]
        env:
        - name: UNSPLASH_ACCESS_KEY
          value: "test"
        - name: POSTGRES_HOST
          value: "postgres-service"
        - name: POSTGRES_PORT
          value: "5432"
        - name: POSTGRES_DB
          value: "visual_dictionary"
        - name: POSTGRES_USER
          value: "vdict"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
                name: postgres-secret
                key: POSTGRES_PASSWORD
        - name: REDIS_URL
          value: "redis://redis-service:6379"
EOF

                        kubectl wait --for=condition=complete \
                            job/pytest-$BUILD_NUMBER \
                            -n visual-dictionary \
                            --timeout=300s

                        EXIT_CODE=$?

                        kubectl logs job/pytest-$BUILD_NUMBER -n visual-dictionary

                        if [ $EXIT_CODE -ne 0 ]; then
                            echo "Tests failed"
                            exit 1
                        fi
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

                        aws eks update-kubeconfig \
                            --region $AWS_REGION \
                            --name $CLUSTER_NAME

                        kubectl set image deployment/visual-dictionary \
                            visual-dictionary=$ECR_REPO:$IMAGE_TAG \
                            -n visual-dictionary

                        kubectl rollout status deployment/visual-dictionary \
                            -n visual-dictionary

                        kubectl set image deployment/visual-dictionary-react \
                            visual-dictionary-react=$ECR_REPO_REACT:$IMAGE_TAG \
                            -n visual-dictionary

                        kubectl rollout status deployment/visual-dictionary-react \
                            -n visual-dictionary
                    '''
                }
            }
        }

        stage('Verify') {
            steps {
                echo 'Verifying deployment...'
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        aws eks update-kubeconfig \
                            --region $AWS_REGION \
                            --name $CLUSTER_NAME

                        kubectl get pods -n visual-dictionary
                        kubectl get services -n visual-dictionary
                    '''
                }
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