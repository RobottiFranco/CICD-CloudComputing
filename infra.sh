aws ecr create-repository \
  --repository-name fastapi-jenkins-demo \
  --region us-east-1

aws ecs create-cluster \
  --cluster-name fastapi-demo-cluster \
  --region us-east-1

aws ecs register-task-definition \
  --cli-input-json file://ecs-taskdef.json

