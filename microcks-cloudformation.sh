#!/bin/bash

# Load environment variables
source ./deploy-microcks-variables.sh

# Log values
echo "Deploying with SubnetIds: $SUBNET_IDS_COMMA"
echo "Deploying in Region: $REGION"

# Validate required variables
if [ -z "$SUBNET_IDS_COMMA" ] || [ -z "$DEFAULT_SG_ID" ]; then
  echo "❌ ERROR: Required environment variables are missing. Aborting deployment."
  exit 1
fi

# Deploy EKS, Aurora DB, DocumentDB together
# Using the combined CloudFormation template

# Step 1: Deploy Combined CloudFormation stack
aws cloudformation deploy \
  --template-file microcks-cloudformation.yaml \
  --stack-name microcks-infra-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SubnetIds=$SUBNET_IDS_COMMA \
    DocDBSubnetIds=$SUBNET_IDS_COMMA \
    EngineVersion=$LATEST_ENGINE_VERSION \
    VpcSecurityGroupId=$DEFAULT_SG_ID \
  --region $REGION

# Check deployment result
if [ $? -eq 0 ]; then
  echo "✅ CloudFormation stack 'microcks-infra-stack' deployed successfully."
else
  echo "❌ Error deploying CloudFormation stack."
  exit 1
fi

# Step 2: Fetch EKS, Aurora DB, DocumentDB Endpoints
echo "Fetching resource endpoints..."

EKS_CLUSTER_ENDPOINT=$(aws cloudformation describe-stacks --stack-name microcks-infra-stack --query "Stacks[0].Outputs[?OutputKey=='ClusterEndpoint'].OutputValue" --output text --region $REGION)
AURORA_DB_ENDPOINT=$(aws cloudformation describe-stacks --stack-name microcks-infra-stack --query "Stacks[0].Outputs[?OutputKey=='AuroraClusterEndpoint'].OutputValue" --output text --region $REGION)
DOCDB_CLUSTER_ENDPOINT=$(aws cloudformation describe-stacks --stack-name microcks-infra-stack --query "Stacks[0].Outputs[?OutputKey=='DocumentDBClusterEndpoint'].OutputValue" --output text --region $REGION)

echo "------------------------------------------------------------"
echo "✅ EKS Cluster Endpoint     : $EKS_CLUSTER_ENDPOINT"
echo "✅ Aurora DB Cluster Endpoint: $AURORA_DB_ENDPOINT"
echo "✅ DocumentDB Cluster Endpoint: $DOCDB_CLUSTER_ENDPOINT"
echo "------------------------------------------------------------"
