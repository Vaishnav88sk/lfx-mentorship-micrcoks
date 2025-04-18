# Load env variables
source ./deploy-microcks-variables.sh

# Log values to verify
echo "Deploying with SubnetIds: $SUBNET_IDS_COMMA"

# Validate before passing to AWS
if [ -z "$SUBNET_IDS_COMMA" ]; then
  echo "❌ ERROR: SubnetIds is empty. Aborting CloudFormation deploy."
  exit 1
fi

# Step 1: Deploy CloudFormation stack using the retrieved subnet IDs
aws cloudformation deploy \
  --template-file eks-cluster.yaml \
  --stack-name eks-microcks-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides SubnetIds=$SUBNET_IDS_COMMA

# Check if the stack was created successfully
if [ $? -eq 0 ]; then
  echo "CloudFormation stack deployed successfully."
else
  echo "Error deploying CloudFormation stack."
  exit 1
fi

