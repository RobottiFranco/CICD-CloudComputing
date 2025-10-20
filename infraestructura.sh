# ========= PARÁMETROS =========
REGION=us-east-1
ACCOUNT_ID=343562361305
CLUSTER=fastapi-demo-cluster
SERVICE=fastapi-demo-service
TASK_FAMILY=fastapi-demo-task
ECR_REPO=fastapi-demo
LOG_GROUP=/ecs/fastapi-demo
PORT=8080

# ========= 1) ECR =========
aws ecr create-repository \
  --repository-name "$ECR_REPO" \
  --region "$REGION"

# ========= 2) ROLES IAM (una vez) =========
# Trust policy para tareas ECS
TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ecs-tasks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

# Rol de ejecución (pull de ECR + logs)
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document "$TRUST_POLICY" || true

aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || true

# Rol de la app (opcional; agrega políticas si tu app usa S3/Dynamo, etc.)
aws iam create-role \
  --role-name ecsAppTaskRole \
  --assume-role-policy-document "$TRUST_POLICY" || true

# ========= 3) LOG GROUP (para awslogs) =========
aws logs create-log-group --log-group-name "$LOG_GROUP" --region "$REGION" 2>/dev/null || true

# ========= 4) CLUSTER ECS =========
aws ecs create-cluster \
  --cluster-name "$CLUSTER" \
  --region "$REGION"  >/dev/null

# ========= 5) NETWORK (SG + subnets públicas en VPC por defecto) =========
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' --output text)

SG_ID=$(aws ec2 create-security-group \
  --group-name fastapi-demo-sg \
  --description "Allow ${PORT}/tcp" \
  --vpc-id "$VPC_ID" \
  --query 'GroupId' --output text)

# Permitir tráfico entrante al puerto 8080
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" --protocol tcp --port "$PORT" --cidr 0.0.0.0/0  >/dev/null

# Tomamos subnets públicas (con IP pública automática)
SUBNETS=($(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID \
  --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' --output text))
# (si no devuelve 2+, elegí manualmente dos subnets públicas)

# ========= 6) ACTUALIZAR ecs-taskdef.json con tus ARNs =========
# Asegúrate de que ecs-taskdef.json tenga:
# "executionRoleArn": "arn:aws:iam::343562361305:role/ecsTaskExecutionRole"
# "taskRoleArn":      "arn:aws:iam::343562361305:role/ecsAppTaskRole"
# "family":           "fastapi-demo-task"
# y el log group:     "/ecs/fastapi-demo"
# (La imagen la sobreescribe el workflow)

# Registrar Task Definition inicial
aws ecs register-task-definition \
  --cli-input-json file://ecs-taskdef.json \
  --region "$REGION" >/dev/null

# ========= 7) SERVICE ECS (una sola vez) =========
aws ecs create-service \
  --cluster "$CLUSTER" \
  --service-name "$SERVICE" \
  --task-definition "$TASK_FAMILY" \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$(IFS=,; echo "${SUBNETS[*]}")],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --region "$REGION"
