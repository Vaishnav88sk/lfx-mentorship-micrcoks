source ./deploy-microcks-variables.sh

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
DOC_DB_ENDPOINT=$(aws docdb describe-db-clusters \
  --region ap-south-1 \
  --query "DBClusters[?DBClusterIdentifier=='microcks-docdb-cluster'].Endpoint" \
  --output text
)

echo "DocumentDB Cluster Endpoint: $DOC_DB_ENDPOINT"
