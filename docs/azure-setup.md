# Azure Click-by-Click Setup Guide (Students)

This is a full UI-first walkthrough for your project in this repository.

## A) One-time tools setup (local machine)

### A1) Install required CLIs on Windows (PowerShell)

Run these commands in an elevated PowerShell window (Run as Administrator):

winget install Microsoft.AzureCLI
winget install Hashicorp.Terraform
winget install Git.Git
winget install GitHub.cli

Docker Desktop (includes Docker CLI):

winget install Docker.DockerDesktop

After installation, restart terminal and open Docker Desktop once.

### A2) Verify all CLIs

Run in PowerShell:

az --version
terraform --version
git --version
gh --version
docker --version
docker compose version

### A3) First-time CLI sign-in checks

Azure CLI login and subscription selection:

az login
az account list --output table
az account set --subscription "YOUR_AZURE_FOR_STUDENTS_SUBSCRIPTION_NAME_OR_ID"
az account show --output table

GitHub CLI login (optional but useful):

gh auth login
gh auth status

If any command is not found, close and reopen terminal, then verify again.

## B) Create GitHub repository and push code

1. In GitHub:
- Click top-right plus icon.
- Click New repository.
- Repository name: AzureDotnetProject.
- Visibility: Public or Private.
- Click Create repository.

2. In local terminal at project root:
git init
git add .
git commit -m "Initial DevOps learning project"
git branch -M main
git remote add origin https://github.com/OWNER/REPO.git
git push -u origin main

## C) Azure Portal click-by-click: create identity for GitHub Actions (OIDC)

1. Open portal
- Go to portal.azure.com.
- Sign in with Azure for Students account.

2. Check subscription
- In top search bar, type Subscriptions.
- Open Subscriptions.
- Confirm Azure for Students is Active.

3. Create App Registration
- Search for App registrations.
- Click New registration.
- Name: taskapi-gha-oidc.
- Supported account types: Accounts in this organizational directory only.
- Click Register.

4. Copy IDs
- On app Overview page, copy and store:
- Application (client) ID.
- Directory (tenant) ID.

5. Create Service Principal for app
- Search for Enterprise applications.
- Click All applications.
- Search taskapi-gha-oidc and open it.
- If not visible yet, wait 30-60 seconds and refresh.

6. Add federated credential (GitHub OIDC)
- Return to App registrations and open taskapi-gha-oidc.
- In left menu click Certificates and secrets.
- Click Federated credentials tab.
- Click Add credential.
- Federated credential scenario: GitHub Actions deploying Azure resources.
- Organization: your GitHub owner.
- Repository: your repository name.
- Entity type: Branch.
- GitHub branch name: main.
- Name: github-main.
- Click Add.

## D) Azure Portal click-by-click: grant permissions

1. Go to Subscriptions
- Open your Azure for Students subscription.

2. Open Access control (IAM)
- Left menu: Access control (IAM).
- Click Add.
- Click Add role assignment.

3. Select role
- Role: Owner (for easiest first bootstrap).
- Click Next.

4. Assign to app
- Assign access to: User, group, or service principal.
- Click Select members.
- Search taskapi-gha-oidc.
- Select it.
- Click Review + assign.

Note:
- Owner is broad and easiest for first deployment.
- After first success, reduce to least privilege roles.

## E) GitHub click-by-click: add Actions secrets

1. Open repository in GitHub
- Click Settings tab.
- Left menu: Secrets and variables.
- Click Actions.
- Click New repository secret.

2. Add these secrets now
- AZURE_CLIENT_ID: from App registration Overview.
- AZURE_TENANT_ID: from App registration Overview.
- AZURE_SUBSCRIPTION_ID: from Subscriptions page.
- JWT_SECRET: strong random 32+ characters.

## F) Terraform provisioning (local first run)

1. In terminal
Set-Location .\infra\terraform
Copy-Item .\terraform.tfvars.example .\terraform.tfvars

2. Edit terraform.tfvars
- location = "westeurope"
- app_service_sku = "B1"
- postgres_sku_name = "B_Standard_B1ms"
- jwt_secret = your strong value
- For lowest spend while learning pipelines only:
- create_postgres = false

3. Run Terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply

4. Copy outputs
terraform output

You need these output values for GitHub secrets in next section.

## G) GitHub click-by-click: add deployment secrets

1. Go to repository Settings -> Secrets and variables -> Actions.
2. Add these secrets from terraform output:
- ACR_NAME
- ACR_LOGIN_SERVER
- RESOURCE_GROUP_NAME
- WEBAPP_NAME

## H) Trigger pipelines and deploy

1. Push any small commit to main
git add .
git commit -m "Trigger pipelines"
git push

2. Watch workflow runs
- In GitHub repo, click Actions.
- Verify CI workflow passes.
- Verify CD workflow passes.

## I) Azure click-by-click: verify app and logs

1. Find app
- In portal search, type App Services.
- Open the web app created by Terraform.

2. Open app URL
- On Overview, click Default domain.
- Test:
- /swagger
- /health

3. Check container logs
- In App Service left menu, click Monitoring -> Log stream.
- Confirm startup logs show application listening on port 8080.

4. Check insights
- In App Service left menu, click Application Insights.
- Open Application Insights resource.
- Check Failures, Performance, and Live Metrics.

## J) Cost-safe operating routine (important)

1. Keep only one environment (dev).
2. Keep ACR Basic and App Service B1.
3. If not actively practicing, delete resource group.
4. Use create_postgres = false when DB practice is not needed.
5. Review Cost Management once per week.

## K) Troubleshooting quick map

1. Terraform not found
- Reinstall Terraform.
- Restart terminal.

2. GitHub Action Azure login fails
- Recheck AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID secrets.
- Recheck federated credential branch is main.

3. CD pushes image but app not updating
- Confirm WEBAPP_NAME and RESOURCE_GROUP_NAME secrets match Terraform outputs.
- In App Service, verify container image points to latest tag.

4. App starts but API fails
- Check App Service Configuration values.
- Check Key Vault secret references and access policies.
