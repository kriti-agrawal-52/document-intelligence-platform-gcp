# GitHub Secrets Setup Guide

To enable automated deployments, you need to set up the following secrets in your GitHub repository.

## Required Secrets

### 1. GCP Service Account Key (`GCP_SA_KEY`)
```bash
# Create a service account with necessary permissions
gcloud iam service-accounts create github-actions-sa \
  --description="Service account for GitHub Actions" \
  --display-name="GitHub Actions SA"

# Grant necessary permissions
gcloud projects add-iam-policy-binding doc-intelligence-1758210325 \
  --member="serviceAccount:github-actions-sa@doc-intelligence-1758210325.iam.gserviceaccount.com" \
  --role="roles/container.admin"

gcloud projects add-iam-policy-binding doc-intelligence-1758210325 \
  --member="serviceAccount:github-actions-sa@doc-intelligence-1758210325.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

gcloud projects add-iam-policy-binding doc-intelligence-1758210325 \
  --member="serviceAccount:github-actions-sa@doc-intelligence-1758210325.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding doc-intelligence-1758210325 \
  --member="serviceAccount:github-actions-sa@doc-intelligence-1758210325.iam.gserviceaccount.com" \
  --role="roles/run.admin"

# Create and download the key
gcloud iam service-accounts keys create github-actions-key.json \
  --iam-account=github-actions-sa@doc-intelligence-1758210325.iam.gserviceaccount.com
```

### 2. OpenAI API Key (`OPENAI_API_KEY`)
- Get from: https://platform.openai.com/api-keys
- Format: `sk-proj-...`

### 3. JWT Secret Key (`JWT_SECRET_KEY`)
```bash
# Generate a secure random key
openssl rand -base64 32
```

### 4. MySQL Password (`MYSQL_PASSWORD`)
```bash
# Generate a secure random password
openssl rand -base64 16
```

## Setting Secrets in GitHub

### Option 1: Using GitHub CLI
```bash
# Set secrets using gh CLI (after creating the keys above)
gh secret set GCP_SA_KEY < github-actions-key.json
gh secret set OPENAI_API_KEY --body "your-openai-api-key"
gh secret set JWT_SECRET_KEY --body "your-jwt-secret-key"
gh secret set MYSQL_PASSWORD --body "your-mysql-password"
```

### Option 2: Using GitHub Web Interface
1. Go to your repository: https://github.com/kriti-agrawal-52/document-intelligence-platform-gcp
2. Click Settings → Secrets and variables → Actions
3. Click "New repository secret" for each secret:
   - `GCP_SA_KEY`: Paste the entire content of `github-actions-key.json`
   - `OPENAI_API_KEY`: Your OpenAI API key
   - `JWT_SECRET_KEY`: Generated JWT secret
   - `MYSQL_PASSWORD`: Generated MySQL password

## Verification

After setting up secrets, you can:
1. Go to Actions tab in your GitHub repository
2. Manually trigger "Deploy Infrastructure" workflow to create GCP resources
3. Push changes to main branch to trigger automatic application deployment

## Security Notes

- Never commit the `github-actions-key.json` file to git
- Store secrets securely and rotate them regularly
- Use least-privilege permissions for service accounts
- Monitor GitHub Actions logs for any security issues
