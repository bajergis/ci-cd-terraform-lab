# Visual Dictionary — CI/CD Lab
 
A full CI/CD pipeline project built with Jenkins, Docker, and Terraform. Deploys a Flask-based visual dictionary app that lets users define words and attach images from Unsplash. Originally built as a learning tool for ELL (English Language Learner) students.
 
## What It Does
 
- Add words with definitions and images
- Search Unsplash for images and attach one to each word
- Browse a visual word card gallery
- RESTful API backend with a Jinja2 frontend
---
 
## Architecture
 
```
GitHub → Jenkins (webhook) → Build (Kaniko/Docker) → Test (pytest) → Deploy (EKS/Docker)
```
 
| Layer       | Local                          | AWS                              |
|-------------|--------------------------------|----------------------------------|
| App         | Flask + SQLite                 | Flask + SQLite                   |
| Images      | Docker Compose                 | EKS (t3.small nodes)             |
| Registry    | Local Docker daemon            | ECR                              |
| CI/CD       | Jenkins (Docker Compose)       | Jenkins (EKS pod, Kaniko builds) |
| IaC         | —                              | Terraform                        |
 
---
 
## Project Structure
 
```
ci-cd-terraform-lab/
├── docker/                        # Local Docker setup
│   ├── docker-compose.yml
│   ├── jenkins/
│   │   └── Dockerfile             # Jenkins + Docker CLI
│   └── flask-app/
│       ├── app.py
│       ├── database.py
│       ├── models.py
│       ├── requirements.txt
│       ├── Dockerfile
│       ├── static/style.css
│       ├── templates/
│       │   ├── base.html
│       │   ├── index.html
│       │   ├── add.html
│       │   └── word.html
│       └── tests/
│           ├── __init__.py
│           └── test_app.py
├── aws/
│   ├── main.tf                    # VPC + EKS + kubernetes provider
│   ├── variables.tf
│   ├── outputs.tf
│   ├── ecr.tf                     # ECR repos: visual-dictionary + jenkins-custom
│   ├── kubernetes.tf              # visual-dictionary namespace
│   ├── jenkins/
│   │   └── Dockerfile             # Jenkins + AWS CLI + kubectl
│   └── k8s/
│       ├── variables.tf
│       ├── secret.tf              # Unsplash key as K8s secret
│       ├── app.tf                 # Flask deployment + LoadBalancer service
│       └── jenkins.tf             # Jenkins deployment + LoadBalancer service
├── Jenkinsfile
└── README.md
```
 
---
 
## Prerequisites
 
| Tool | Purpose |
|------|---------|
| Docker Desktop | Local dev and Jenkins |
| Python 3.11+ | Running tests locally |
| Terraform | AWS infrastructure provisioning |
| AWS CLI | Interacting with EKS/ECR |
| kubectl | Managing Kubernetes resources |
| Unsplash API key | Image search (free tier, 50 req/hr) |
 
---
 
## Running Locally (Docker Compose)
 
1. Clone the repo:
   ```bash
   git clone https://github.com/bajergis/ci-cd-terraform-lab.git
   cd ci-cd-terraform-lab
   ```
 
2. Add your Unsplash API key:
   ```bash
   echo "UNSPLASH_ACCESS_KEY=your_key_here" > docker/.env
   ```
 
3. Start the stack:
   ```bash
   cd docker
   docker-compose up --build
   ```
 
4. Access the apps:
   - Visual Dictionary: http://localhost:5000
   - Jenkins: http://localhost:8080
### Local Jenkins Pipeline
 
SCM polling is set to every 2 minutes (webhooks aren't reliable behind ngrok locally). The pipeline runs:
 
1. **Checkout** — pulls latest code from GitHub
2. **Build** — builds a Docker image tagged with the build number
3. **Test** — runs pytest against the image
4. **Deploy** — stops old container, starts new one
5. **Verify** — confirms the container is running
> Jenkins runs as `root` in docker-compose to access the Docker socket. This is intentional for local dev only.
 
---
 
## Running Tests Locally
 
```bash
cd docker/flask-app
python -m pytest tests/ -v
```
 
---
 
## API Endpoints
 
| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/words` | Get all words |
| `GET` | `/api/words/<word>` | Get a single word |
| `POST` | `/api/words` | Create a word (`word`, `definition`, `image_url`, `image_credit` required) |
| `DELETE` | `/api/words/<word>` | Delete a word |
| `POST` | `/api/search-images` | Search Unsplash, returns 9-image grid |
 
---
 
## AWS Deployment
 
### Infrastructure Overview
 
| Resource | Value |
|----------|-------|
| Account ID | 397845934685 |
| Region | us-east-2 |
| IAM User | terraform-user |
| EKS Cluster | ci-cd-lab-cluster |
| VPC | ci-cd-lab-cluster-vpc (2 AZs, single NAT gateway) |
| Node type | t3.small, min 1 / max 2 / desired 2 |
| Namespace | visual-dictionary |
 
**ECR Repositories:**
- `397845934685.dkr.ecr.us-east-2.amazonaws.com/visual-dictionary`
- `397845934685.dkr.ecr.us-east-2.amazonaws.com/jenkins-custom`
### First-Time Terraform Setup
 
> **Important:** ECR repos and images must exist before the Kubernetes resources can be applied. Follow this order:
 
**Step 1 — Create ECR and EKS (comment out the k8s module first):**
```bash
cd aws
# Comment out the k8s module in main.tf before running
terraform init
terraform apply
```
 
**Step 2 — Authenticate with ECR and push images:**
```bash
aws ecr get-login-password --region us-east-2 | \
  docker login --username AWS --password-stdin \
  397845934685.dkr.ecr.us-east-2.amazonaws.com
 
# Build for AMD64 (required if developing on Apple Silicon)
docker build --platform linux/amd64 \
  -t 397845934685.dkr.ecr.us-east-2.amazonaws.com/visual-dictionary:latest \
  docker/flask-app/
docker push 397845934685.dkr.ecr.us-east-2.amazonaws.com/visual-dictionary:latest
 
docker build --platform linux/amd64 \
  -t 397845934685.dkr.ecr.us-east-2.amazonaws.com/jenkins-custom:latest \
  aws/jenkins/
docker push 397845934685.dkr.ecr.us-east-2.amazonaws.com/jenkins-custom:latest

cd react-app
docker build --platform linux/amd64 -t visual-dictionary-react .
docker tag visual-dictionary-react:latest \
    397845934685.dkr.ecr.us-east-2.amazonaws.com/visual-dictionary-react:latest
docker push \
    397845934685.dkr.ecr.us-east-2.amazonaws.com/visual-dictionary-react:latest
```
 
**Step 3 — Uncomment the k8s module and apply again:**
```bash
# Uncomment k8s module in main.tf, then:
terraform apply
```
 
### Updating kubeconfig
 
```bash
aws eks update-kubeconfig --region us-east-2 --name ci-cd-lab-cluster
```
 
### Kubernetes Secrets
 
The Unsplash API key is stored as a Kubernetes secret in the `visual-dictionary` namespace:
 
```bash
kubectl create secret generic unsplash-secret \
  --from-literal=UNSPLASH_ACCESS_KEY=your_key_here \
  -n visual-dictionary
```
 
This is managed via Terraform in `aws/k8s/secret.tf`.
 
### Useful kubectl Commands
 
```bash
# Check pods
kubectl get pods -n visual-dictionary
 
# Check services / get LoadBalancer URLs
kubectl get services -n visual-dictionary
 
# View app logs
kubectl logs -l app=visual-dictionary -n visual-dictionary
 
# View Jenkins logs
kubectl logs -l app=jenkins -n visual-dictionary
```
 
---
 
## Jenkins on EKS
 
Jenkins runs inside the `visual-dictionary` namespace using a custom image that includes AWS CLI and kubectl.
 
**Jenkins URL:** http://{really-longnumber}.us-east-2.elb.amazonaws.com:8080

Retrieve your Jenkins code by running:
```bash
kubectl exec -n visual-dictionary -it $(kubectl get pod -n visual-dictionary -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -- cat /var/jenkins_home/secrets/initialAdminPassword
```

GitHub webhooks are configured and trigger builds automatically on every push.
 
### Jenkins Credentials (configure before first run)

Find them here:
```bash
cat ~/.aws/credentials
```
Then add them in Jenkins under Manage Jenkins -> Credentials -> System -> Global

| Credential ID           | Type | Description                       |
|-------------------------|------|-----------------------------------|
| `aws-access-key-id`     | Secret text | AWS access key for ECR/EKS access |
| `aws-secret-access-key` | Secret text | AWS secret key                    |
| `unsplash-api-key`      | Secret text | Unsplash API key                  |
| `postgres-password`     | Secret text | PostgreSQL password               |
 
Then create a new Job in Jenkins where you add your git repo.

### EKS Pipeline Stages
 
Because there's no Docker daemon available inside EKS pods, the pipeline uses **Kaniko** to build and push images directly to ECR:
 
1. **Checkout** — pulls latest code from GitHub
2. **Build and Push to ECR** — Kaniko runs as a Kubernetes Job; a `git-clone` initContainer clones the repo, then Kaniko builds and pushes to ECR with `--platform linux/amd64`
3. **Test** — runs pytest as a Kubernetes Job using the freshly pushed ECR image
4. **Deploy to EKS** — `kubectl set image` + `kubectl rollout status`
5. **Verify** — `kubectl get pods` and `kubectl get services`
---
 
## Environment Variables
 
| Variable | Where | Description |
|----------|-------|-------------|
| `UNSPLASH_ACCESS_KEY` | `docker/.env` (local) / K8s secret (EKS) | Unsplash API access key |
 
---
 
## Known Gotchas
 
**ARM vs AMD64:** If you're on Apple Silicon (M1/M2/M3), always build with `--platform linux/amd64` for EKS. EKS nodes are x86.
 
**Terraform state drift:** If state gets out of sync, use:
```bash
terraform state rm <resource>
terraform import <resource> <id>
```
 
**Terraform ordering:** The k8s module depends on ECR images existing. On a fresh deploy, comment it out, push images first, then uncomment and re-apply.
 
**IAM access to cluster:** `terraform-user` IAM access is added directly in the EKS Terraform module via an `access_entries` block — no manual `aws-auth` ConfigMap editing needed.
 
---
 
## Roadmap — Phase 2
 
Planned evolution into a multi-service architecture:
 
- **React frontend** to replace Jinja2 templates
- **Flask** becomes a pure REST API
- **PostgreSQL** to replace SQLite
- **Redis** to cache Unsplash results
 

