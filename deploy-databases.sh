You're right! **Step 5** in the shell script, which generates the CloudFormation template dynamically, isn't necessary if you're deploying the CloudFormation template separately (as a static file). I included this in the shell script assuming you might want to automate the entire process, including the generation of the CloudFormation file, but it might be redundant if you already have the CloudFormation template defined separately.

### To clarify:

If you're using **separate CloudFormation** files (`microcks-aurora-cluster.yaml`), you don’t need to dynamically generate the CloudFormation file in the shell script. Instead, the script would just fetch the necessary dynamic values and then deploy the pre-existing CloudFormation template.

So, **Step 5** in the shell script is redundant in this context. Below is the revised script, which will:

- Fetch necessary dynamic values like default VPC ID, public subnets, Aurora engine version, and default security group ID.
- Use the **already prepared CloudFormation template**.

### Updated Shell Script (`deploy-aurora-db.sh`)

This version will **only** fetch the required dynamic values and deploy the CloudFormation template without regenerating the template:

```bash
#!/bin/bash

# Set your AWS region dynamically or statically
REGION="ap-south-1"

# Step 1: Fetch the default VPC ID
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters Name=isDefault,Values=true \
  --query "Vpcs[0].VpcId" \
  --output text)

# Check if the default VPC exists
if [ "$DEFAULT_VPC_ID" == "None" ]; then
  echo "No default VPC found in region $REGION."
  exit 1
fi
echo "Default VPC ID: $DEFAULT_VPC_ID"

# Step 2: Fetch public subnets of the default VPC
SUBNET_IDS=$(aws ec2 describe-subnets \
  --region $REGION \
  --filters Name=vpc-id,Values=$DEFAULT_VPC_ID Name=default-for-az,Values=true \
  --query "Subnets[*].SubnetId" \
  --output text)

# Check if any subnets were found
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

# Step 5: Deploy CloudFormation stack (using an existing template)
aws cloudformation deploy \
  --template-file microcks-aurora-cluster.yaml \
  --stack-name microcks-db-stack \
  --parameter-overrides \
    SubnetIds=$SUBNET_IDS_COMMA \
    EngineVersion=$LATEST_ENGINE_VERSION \
    VpcSecurityGroupId=$DEFAULT_SG_ID \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

# Step 6: Fetch DB cluster endpoint after deployment
ENDPOINT=$(aws rds describe-db-clusters --query "DBClusters[0].Endpoint" --output text --region $REGION)
echo "DB Cluster Endpoint: $ENDPOINT"
```

### Changes:
- **Step 5** (template generation) has been removed from the script.
- The script now uses the **pre-defined CloudFormation template** (`microcks-aurora-cluster.yaml`) and dynamically injects parameters into the deployment.
  
### CloudFormation Template (`microcks-aurora-cluster.yaml`)

This CloudFormation template will receive dynamic inputs for `SubnetIds`, `EngineVersion`, and `VpcSecurityGroupId` during deployment, which are passed by the shell script.

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Parameters:
  SubnetIds:
    Type: String
    Description: Comma-separated list of subnet IDs
  EngineVersion:
    Type: String
    Description: Aurora PostgreSQL Engine Version
  VpcSecurityGroupId:
    Type: String
    Description: Security Group ID for the VPC

Resources:
  MicrocksDBSubnetGroup:
    Type: AWS::RDS::DBSubnetGroup
    Properties:
      DBSubnetGroupDescription: "Subnet group for Microcks Aurora"
      SubnetIds: !Ref SubnetIds

  MicrocksDBCluster:
    Type: AWS::RDS::DBCluster
    Properties:
      DBClusterIdentifier: microcks-db-cluster
      Engine: aurora-postgresql
      EngineVersion: !Ref EngineVersion
      MasterUsername: microcks
      MasterUserPassword: microcks123
      DBSubnetGroupName: !Ref MicrocksDBSubnetGroup
      VpcSecurityGroupIds:
        - !Ref VpcSecurityGroupId
      ServerlessV2ScalingConfiguration:
        MinCapacity: 0.5
        MaxCapacity: 2
      BackupRetentionPeriod: 7
      EnableHttpEndpoint: true

  MicrocksDBInstance:
    Type: AWS::RDS::DBInstance
    Properties:
      DBInstanceIdentifier: microcks-db-instance
      DBClusterIdentifier: !Ref MicrocksDBCluster
      Engine: aurora-postgresql
      DBInstanceClass: db.serverless
```

### How the script works now:

1. **Dynamic Fetching**: The shell script fetches the following values dynamically:
   - **Default VPC ID**
   - **Public Subnet IDs** (comma-separated)
   - **Aurora PostgreSQL Engine Version**
   - **Default Security Group ID**

2. **Deploy CloudFormation Stack**: The script uses the `aws cloudformation deploy` command to deploy the `microcks-aurora-cluster.yaml` template with dynamic parameters passed via `--parameter-overrides`.

3. **Fetch DB Endpoint**: After the stack is created, the script queries and outputs the DB cluster endpoint.

### Usage:

1. **Save the Shell Script**: `deploy-aurora-db.sh`.
2. **Save the CloudFormation Template**: `microcks-aurora-cluster.yaml`.
3. **Make the Shell Script Executable**:
   ```bash
   chmod +x deploy-aurora-db.sh
   ```
4. **Run the Script**:
   ```bash
   ./deploy-aurora-db.sh
   ```

Let me know if you need further adjustments!
