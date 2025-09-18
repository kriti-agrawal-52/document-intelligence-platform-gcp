# 🧠 Document Intelligence Platform - GCP Edition

A production-ready, cloud-native document processing platform built with microservices architecture on Google Cloud Platform, featuring AI-powered text extraction and summarization capabilities.

## 🏗️ Architecture Overview

```
Google Cloud Platform Stack:
├── Frontend: Cloud Run (Next.js SPA)
├── Backend: Google Kubernetes Engine (GKE)
├── Storage: Cloud Storage (document files)
├── Messaging: Pub/Sub (async processing)
├── Databases: Cloud SQL MySQL + Firestore + Redis
├── Container Registry: Artifact Registry
├── Secrets: Secret Manager
├── Build: GitHub Actions CI/CD
└── Networking: VPC with private/public subnets
```

## ✨ Features

### 🔐 **Authentication & Authorization**
- JWT-based authentication with 2-hour expiration
- Secure logout with token blacklisting
- User profile management
- Password hashing with bcrypt

### 📄 **Document Processing**
- **Cloud Storage-first strategy**: Raw images stored securely before processing
- **AI-powered text extraction** using OpenAI GPT-4o-mini
- **Asynchronous summarization** via Google Pub/Sub message queues
- **Redis caching** for fast retrieval of recent extractions
- **Complete lifecycle tracking** with status updates

### 🚀 **Production-Ready Infrastructure**
- **Container orchestration** with Google Kubernetes Engine (GKE)
- **Auto-scaling** based on CPU and queue depth
- **Load balancing** with Google Cloud Load Balancer
- **Multi-zone deployment** for high availability
- **Infrastructure as Code** with Terraform
- **Automated CI/CD** with GitHub Actions

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend** | Next.js 14 + TypeScript | Modern SPA with SSR |
| **Backend** | FastAPI + Python 3.11 | High-performance async APIs |
| **Authentication** | JWT + Redis | Secure token management |
| **Databases** | Cloud SQL MySQL + Firestore + Redis | Multi-model data storage |
| **Message Queue** | Google Pub/Sub | Async processing |
| **Storage** | Google Cloud Storage | Raw file storage |
| **AI Processing** | OpenAI GPT-4o-mini | Text extraction & summarization |
| **Container Platform** | Google Kubernetes Engine | Kubernetes orchestration |
| **Container Registry** | Artifact Registry | Docker image storage |
| **Infrastructure** | Terraform | Infrastructure as Code |
| **CI/CD** | GitHub Actions | Automated deployments |

## 🚀 Deployment

### Prerequisites
- Google Cloud Platform account with billing enabled
- GitHub repository with required secrets configured
- Terraform >= 1.5.0
- kubectl CLI tool

### GitHub Secrets Required
```
GCP_SA_KEY: Service account key JSON
OPENAI_API_KEY: OpenAI API key
JWT_SECRET_KEY: JWT signing secret
MYSQL_PASSWORD: Database password
```

### Infrastructure Deployment
1. **Deploy Infrastructure** (manual trigger):
   - Go to Actions → Deploy Infrastructure
   - Select "apply" action
   - This creates GCP resources via Terraform

2. **Application Deployment** (automatic on push to main):
   - Push to main branch triggers automatic deployment
   - Builds Docker images and deploys to GKE + Cloud Run

### Manual Deployment
```bash
# 1. Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 2. Deploy applications
kubectl apply -f kubernetes/
```

## 📁 Project Structure

```
├── frontend/              # Next.js frontend application
├── user_auth/             # Authentication microservice
├── text_extraction/       # Text extraction microservice
├── text_summarization/    # Text summarization microservice
├── shared/               # Shared utilities and configuration
├── terraform/            # Infrastructure as Code
├── kubernetes/           # Kubernetes manifests
├── .github/workflows/    # GitHub Actions CI/CD
├── cloudbuild.yaml       # Cloud Build configuration (alternative)
└── README.md            # This file
```

## 🔒 Security Features

- **🔐 JWT Authentication** with secure logout
- **🛡️ Token Blacklisting** in Redis
- **🔒 Secrets Management** with Google Secret Manager
- **🚫 Network Isolation** with VPC private subnets
- **👤 Non-root Containers** for security
- **📊 Audit Logging** with Google Cloud Logging

## 📊 Monitoring & Observability

- **Health Checks** for all services
- **Auto-scaling** based on metrics
- **Google Cloud Monitoring** and alerting
- **Container Health Checks** with Docker
- **Load Balancer Health Checks**

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Commit your changes: `git commit -m 'Add amazing feature'`
5. Push to the branch: `git push origin feature/amazing-feature`
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions, please use the GitHub Issues tab.

## 🚀 Deployment Status
- Infrastructure: Ready for deployment
- Application: Ready for automated deployment
- GitHub Actions: Configured and ready

Last updated: Fri Sep 19 01:26:32 IST 2025
