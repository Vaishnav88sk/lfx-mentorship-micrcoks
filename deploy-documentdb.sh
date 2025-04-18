# Step 1: Deploy CloudFormation stack
aws cloudformation deploy \
  --region $REGION \
  --template-file microcks-docdb-cluster.yaml \
  --stack-name microcks-docdb-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    SubnetIds=$SUBNET_IDS_COMMA \
    VpcSecurityGroupId=$DEFAULT_SG_ID

# Step 2: Output the cluster endpoint
ENDPOINT=$(aws docdb describe-db-clusters \
  --region $REGION \
  --query "DBClusters[0].Endpoint" \
  --output text)

echo "DocumentDB Cluster Endpoint: $ENDPOINT"
