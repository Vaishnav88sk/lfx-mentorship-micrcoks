source ./deploy-microcks-variables.sh

# Step 1: Deploy CloudFormation stack (using an existing template)
aws cloudformation deploy \
  --template-file microcks-aurora-cluster.yaml \
  --stack-name microcks-db-stack \
  --parameter-overrides \
    SubnetIds=$SUBNET_IDS_COMMA \
    EngineVersion=$LATEST_ENGINE_VERSION \
    VpcSecurityGroupId=$DEFAULT_SG_ID \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

# Step 2: Fetch DB cluster endpoint after deployment
AURORA_DB_ENDPOINT=$(aws rds describe-db-clusters --query "DBClusters[0].Endpoint" --output text --region $REGION)
echo "Aurora DB Cluster Endpoint: $AURORA_DB_ENDPOINT"
