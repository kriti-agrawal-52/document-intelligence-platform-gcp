# 🔐 Secure Secrets Management Guide

## Overview
This project uses **GitHub Secrets** as the single source of truth for all sensitive data. No secrets should ever be committed to the repository.

## Required GitHub Secrets

### 1. Authentication & APIs
```bash
gh secret set OPENAI_API_KEY --body "sk-proj-your-new-key-here"
gh secret set JWT_SECRET_KEY --body "your-jwt-secret-here"
```

### 2. Database Credentials
```bash
gh secret set MYSQL_PASSWORD --body "your-secure-mysql-password"
```

### 3. GCP Service Account
```bash
gh secret set GCP_SA_KEY --body "$(cat path/to/your-service-account-key.json)"
```

## How It Works

### Terraform (Infrastructure)
- Reads secrets via `TF_VAR_*` environment variables
- No secrets in `terraform.tfvars` file
- GitHub Actions sets environment variables from secrets

### Kubernetes (Applications)
- CD workflow creates secrets from GitHub secrets
- Fallback mechanism if External Secrets Operator fails
- All pods read from Kubernetes secrets

### Local Development
```bash
# Set environment variables locally
export TF_VAR_openai_api_key="your-key"
export TF_VAR_jwt_secret_key="your-jwt"
export TF_VAR_mysql_password="your-password"

# Then run terraform
cd terraform
terraform plan
```

## Security Benefits
✅ No secrets in Git history
✅ Centralized secret management
✅ Automatic rotation support
✅ Access control via GitHub permissions
✅ Audit trail of secret usage

## Adding New Secrets
1. Add to GitHub Secrets: `gh secret set SECRET_NAME --body "value"`
2. Update GitHub Actions workflow to pass as environment variable
3. Update Terraform variables if needed
4. Update Kubernetes manifests if needed

## Never Do This ❌
- Don't commit secrets to any files
- Don't put secrets in terraform.tfvars
- Don't hardcode secrets in YAML files
- Don't share secrets in chat/email
