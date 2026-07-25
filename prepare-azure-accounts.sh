# -----------------------------------------------------------------------------
# CONFIGURATION - CHANGE THESE 2 VARIABLES
# -----------------------------------------------------------------------------
GITHUB_USER="subhash-devopslearner"
GITHUB_REPO="terraform-azure-practice"

# -----------------------------------------------------------------------------
# 1. CREATE PERMANENT MANAGEMENT RESOURCE GROUP
# -----------------------------------------------------------------------------
echo "Creating Management Resource Group..."
az group create --name subhash-mgmt-rg --location "eastus"

# -----------------------------------------------------------------------------
# 2. CREATE TERRAFORM REMOTE STATE STORAGE ACCOUNT & CONTAINER
# -----------------------------------------------------------------------------
echo "Creating Storage Account for Remote State..."
# Storage account names must be globally unique and lowercase numbers/letters
STORAGE_NAME="subhashtfstate$RANDOM"

az storage account create \
  --name $STORAGE_NAME \
  --resource-group subhash-mgmt-rg \
  --location eastus \
  --sku Standard_LRS \
  --allow-blob-public-access false

az storage container create \
  --name tfstate \
  --account-name $STORAGE_NAME

# -----------------------------------------------------------------------------
# 3. CREATE GITHUB ACTIONS MANAGED IDENTITY & FEDERATED TRUST (OIDC)
# -----------------------------------------------------------------------------
echo "Creating GitHub Actions Managed Identity..."
az identity create --name github-actions-identity --resource-group subhash-mgmt-rg

# Capture variables
IDENTITY_CLIENT_ID=$(az identity show --name github-actions-identity --resource-group subhash-mgmt-rg --query clientId -o tsv)
SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Create Federated Credential Trust
az identity federated-credential create \
  --name "github-ops-trust" \
  --identity-name github-actions-identity \
  --resource-group subhash-mgmt-rg \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${GITHUB_USER}/${GITHUB_REPO}:ref:refs/heads/main" \
  --audience "api://AzureADTokenExchange"

# -----------------------------------------------------------------------------
# 4. ASSIGN ALL NECESSARY RBAC ROLES (MANAGEMENT + DATA PLANE)
# -----------------------------------------------------------------------------
echo "Assigning RBAC Roles..."

# Role A: Contributor over Subscription (To create RGs, ACRs, ACI, KeyVault)
az role assignment create \
  --role "Contributor" \
  --assignee $IDENTITY_CLIENT_ID \
  --scope /subscriptions/$SUB_ID

# Role B: Storage Blob Data Contributor (CRUCIAL: To read/write .tfstate files)
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $IDENTITY_CLIENT_ID \
  --scope /subscriptions/$SUB_ID

# -----------------------------------------------------------------------------
# 5. PRINT YOUR GITHUB SECRETS & STORAGE ACCOUNT NAME
# -----------------------------------------------------------------------------
echo "======================================================================"
echo "SUCCESS! SAVE THESE VALUES FOR YOUR GITHUB SECRETS & TERRAFORM CONFIG:"
echo "======================================================================"
echo "AZURE_CLIENT_ID:       $IDENTITY_CLIENT_ID"
echo "AZURE_TENANT_ID:       $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUB_ID"
echo "STORAGE_ACCOUNT_NAME:  $STORAGE_NAME"
echo "======================================================================"