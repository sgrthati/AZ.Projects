#!/bin/bash
set -euxo pipefail
# This script must be run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root. Attempting to elevate privileges..."
  sudo "$0" "$@"
  exit $?
fi

# Set environment variables with defaults if not already set
domainName="srisri.xyz"
emailAddress="admin@srisri.xyz"
Build_SourcesDirectory="$(pwd)"
subscriptionID="$(az account show | jq -r .id)"
clientSecret="secret"
#azure dns provisioned resource group
resourceGroups="NetworkWatcherRG" 

# Setup Environment
echo "Installing Azure CLI and Certbot..."

# installing dependencies
sudo apt update && sudo apt install -y python3 python3-venv curl openssl

# Check if Azure CLI is installed
if ! command -v az &> /dev/null
then
    echo "Azure CLI could not be found. Installing..."

    # Use Microsoft's script to install Azure CLI
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    echo "Azure CLI installed successfully."
else
    echo "Azure CLI is already installed."
fi

# Create a python virtual environment and install certbot
cd "$Build_SourcesDirectory"
mkdir cert_venv && cd cert_venv
python3 -m venv certbot_venv
source certbot_venv/bin/activate
pip install certbot certbot-dns-azure

# Login to Azure
echo "Logging into Azure..."
if ! az account show &> /dev/null; then
    echo "You are not logged in to Azure. Please log in."
    az login
fi

# Create Azure Certbot Credentials File

cat > $Build_SourcesDirectory/cert_venv/azure_certbot_credentials.ini <<EOF
dns_azure_use_cli_credentials = true
dns_azure_environment = "AzurePublicCloud"
dns_azure_zone1 = $domainName:/subscriptions/$subscriptionID/resourceGroups/$resourceGroups
EOF

# Generate/Refresh SSL Certificate
chmod 600 $Build_SourcesDirectory/cert_venv/azure_certbot_credentials.ini # Locking down permisions on the credentials file

certbot certonly --authenticator dns-azure \
    --preferred-challenges dns \
    --dns-azure-credentials $Build_SourcesDirectory/cert_venv/azure_certbot_credentials.ini \
    -d $domainName \
    -d *.$domainName \
    --config-dir $Build_SourcesDirectory/cert_venv/letsencrypt \
    --work-dir $Build_SourcesDirectory/cert_venv/letsencrypt/work \
    --logs-dir $Build_SourcesDirectory/cert_venv/letsencrypt/logs \
    --non-interactive \
    --agree-tos \
    --email $emailAddress
#copying generated certs to Certs Location
cd $Build_SourcesDirectory/
if ! mkdir generated_certs &> /dev/null; then
    echo "generated_certs already exist removing existing files"
    rm -rf $Build_SourcesDirectory/generated_certs/*
fi
cp -r $Build_SourcesDirectory/cert_venv/letsencrypt/archive/$domainName/* $Build_SourcesDirectory/generated_certs/
cp -r $Build_SourcesDirectory/cert_venv/letsencrypt/archive/$domainName/fullchain*.pem $Build_SourcesDirectory/generated_certs/public.crt
cp -r $Build_SourcesDirectory/cert_venv/letsencrypt/archive/$domainName/privkey*.pem $Build_SourcesDirectory/generated_certs/private.key

#Convert Certificates to PFX
openssl pkcs12 -export \
    -out $Build_SourcesDirectory/generated_certs/certificate.pfx \
    -inkey $Build_SourcesDirectory/generated_certs/privkey*.pem \
    -in $Build_SourcesDirectory/generated_certs/cert*.pem \
    -certfile $Build_SourcesDirectory/generated_certs/fullchain*.pem \
    -passout pass:$clientSecret

echo "generated certs stored in $Build_SourcesDirectory/generated_certs/ & .pfx cert password is $clientSecret"

#Removing Certbot generated logs etc,we can uncomment it if we wanted to see logs
certbot delete --cert-name $domainName
rm -rf $Build_SourcesDirectory/cert_venv/
