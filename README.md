# Visual Dictionary CI/CD Lab

A full CI/CD pipeline project built with Jenkins, Docker, and Terraform.
Deploys a Flask-based visual dictionary app that lets you define words and
attach images from Unsplash.

## Architecture

- **App:** Python Flask + SQLite + Unsplash API
- **CI/CD:** Jenkins pipeline (build → test → deploy)
- **Local:** Docker Compose
- **Cloud:** AWS EKS via Terraform (see `aws/`)

## Project Structure

ci-cd-terraform-lab/
├── docker/                  # Local Docker setup
│   ├── docker-compose.yml
│   ├── jenkins/             # Custom Jenkins image
│   └── flask-app/           # Flask app + tests
├── aws/                     # Terraform EKS deployment
├── Jenkinsfile              # Pipeline definition
└── README.md

## Prerequisites

- Docker Desktop
- Python 3.11+
- Terraform
- AWS CLI (for AWS deployment)

## Running Locally

1. Clone the repo:
   git clone https://github.com/YOUR_USERNAME/ci-cd-terraform-lab.git
   cd ci-cd-terraform-lab

2. Add your Unsplash API key to docker/.env:
   UNSPLASH_ACCESS_KEY=your_key_here

3. Start the stack:
   cd docker
   docker-compose up --build

4. Access the apps:
   - Visual Dictionary: http://localhost:5000
   - Jenkins: http://localhost:8080

## Jenkins Pipeline

The pipeline runs automatically every 2 minutes via SCM polling:

1. Checkout — pulls latest code from GitHub
2. Build — builds a Docker image tagged with the build number
3. Test — runs pytest suite against the image
4. Deploy — stops old container, starts new one
5. Verify — confirms the container is running

## Running Tests Locally

cd docker/flask-app
python -m pytest tests/ -v

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/words | Get all words |
| GET | /api/words/<word> | Get a single word |
| POST | /api/words | Create a new word |
| DELETE | /api/words/<word> | Delete a word |
| POST | /api/search-images | Search Unsplash images |

## AWS Deployment

See the aws/ folder for Terraform configuration to deploy on EKS.

## Environment Variables

| Variable | Description |
|----------|-------------|
| UNSPLASH_ACCESS_KEY | Unsplash API access key |

## Jenkins Credentials

Add the following in Jenkins before running the pipeline:
- ID: unsplash-api-key — your Unsplash API key (Secret text)