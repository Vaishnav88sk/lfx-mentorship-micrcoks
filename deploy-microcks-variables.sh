#!/bin/bash

# Set your region
REGION="ap-south-1"

# Step 1: Get the default VPC ID
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters Name=isDefault,Values=true \
  --query "Vpcs[0].VpcId" \
  --output text)

# Check if the default VPC ID was fetched successfully
if [ "$DEFAULT_VPC_ID" == "None" ]; then
  echo "No default VPC found in region $REGION."
  exit 1
fi

echo "Default VPC ID: $DEFAULT_VPC_ID"

# Step 2: Get public subnet IDs from the default VPC
SUBNET_IDS=$(aws ec2 describe-subnets \
  --region $REGION \
  --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=default-for-az,Values=true \
  --query "Subnets[*].SubnetId" \
  --output text)

# Check if any public subnets were found
if [ -z "$SUBNET_IDS" ]; then
  echo "No public subnets found in the default VPC."
  exit 1
fi

# Convert space-separated subnet IDs to comma-separated
SUBNET_IDS_COMMA=$(echo $SUBNET_IDS | tr ' ' ',')

echo "Public Subnet IDs: $SUBNET_IDS_COMMA"

# Step 3: Fetch the latest Aurora PostgreSQL engine version
LATEST_ENGINE_VERSION=$(aws rds describe-db-engine-versions \
  --region $REGION \
  --engine aurora-postgresql \
  --query "DBEngineVersions[0].EngineVersion" \
  --output text)

echo "Latest Aurora PostgreSQL Engine Version: $LATEST_ENGINE_VERSION"

# Step 4: Fetch default VPC security group ID
DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=group-name,Values=default \
  --query "SecurityGroups[0].GroupId" \
  --output text)

echo "Default Security Group ID: $DEFAULT_SG_ID"


