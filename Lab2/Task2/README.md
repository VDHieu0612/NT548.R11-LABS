# Task 2: Tự động hóa CloudFormation với AWS CodePipeline
- **Thành viên phụ trách:** Lê Đoàn Phúc Thanh (24520030)
- **Mục tiêu:**
  - Tái sử dụng template `Lab1/cloudformation`.
  - Sử dụng AWS CodeCommit làm kho chứa mã nguồn.
  - Sử dụng AWS CodeBuild tích hợp công cụ kiểm thử `cfn-lint` và `taskcat`.
  - Dùng AWS CodePipeline tự động kích hoạt quy trình build & deploy stack.

# Cấu trúc pipeline: 
```
git push ──> CodeCommit ──> CodeBuild (cfn-lint, taskcat) ──> CloudFormation deploy: 01, rồi 02, rồi 03
              (Source)              (Build)                                   (Deploy)
```

# Hướng dẫn triển khai

### 0. Tạo access key từ tài khoản IAM
```bash
aws configure

# Kiểm tra tài khoản đúng 
aws sts get-caller-identity
```

### 1. Tạo keypair
```bash 
# Trong git bash, tạo key pair
aws ec2 create-key-pair --key-name lab2-key --query KeyMaterial --output text > lab2-key.pem
chmod 400 lab2-key.pem
```

### 2. Tạo repo và pipeline
```bash
aws cloudformation deploy --template-file pipeline.yaml --stack-name lab2-pipeline --capabilities CAPABILITY_IAM --parameter-overrides MyIp=<ip-cua-ban>/32
# Kiểm tra kết quả 
aws cloudformation describe-stacks --stack-name lab2-pipeline --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output table
```

### 3. Cấu hình git với CodeCommit
```bash 
git config --global credential.helper '!aws codecommit credential-helper $@'

git config --global credential.UseHttpPath true

git clone https://git-codecommit.us-east-1.amazonaws.com/v1/repos/lab2-cfn
```
git sẽ clone một repo rỗng sau đó đặt các file vào repo như sau: 
```
lab2-cfn/
├── .taskcat.yml      
├── buildspec.yml
└── cloudformation/
    ├── 01-vpc-network.yaml
    ├── 02-security-groups.yaml
    ├── 03-ec2-instances.yaml
    └── master.yaml
```

```bash 
git checkout -b main 
git add .
git commit -m "..." 
git push -u origin main
```

### 4. Theo dõi pipeline 
```bash
aws codepipeline get-pipeline-state --name lab2-cfn-pipeline --query "stageStates[].[stageName,latestExecution.status]" --output table
```
Quá trình Build và Deploy sẽ tốn cỡ 15-30p

### 5. Kiểm tra kết quả triển khai
```bash
aws cloudformation describe-stacks --query "Stacks[?starts_with(StackName,'lab2-')].[StackName,StackStatus]" --output table
aws cloudformation describe-stacks --stack-name lab2-ec2 --query "Stacks[0].Outputs[].[OutputKey,OutputValue]" --output table
```

### 6. Kiểm tra pipeline 
Sau khi push nếu file hợp lệ thì pipeline tự chạy lại, nếu lỗi thì pipeline chặn và không gây ảnh hưởng đến các stack đang chạy. Kiểm tra bằng lệnh:
```bash
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=lab2-project-vpc" --query "Vpcs[].VpcId"
```

### 7. Dọn dẹp 
```bash
# Xóa 3 stack
aws cloudformation delete-stack --stack-name lab2-ec2
aws cloudformation wait stack-delete-complete --stack-name lab2-ec2
aws cloudformation delete-stack --stack-name lab2-sg
aws cloudformation wait stack-delete-complete --stack-name lab2-sg
aws cloudformation delete-stack --stack-name lab2-vpc
aws cloudformation wait stack-delete-complete --stack-name lab2-vpc

# Làm rỗng bucket artifact và xóa stack pipeline/repo CodeCommit
aws cloudformation describe-stacks --stack-name lab2-pipeline --query "Stacks[0].Outputs[?OutputKey=='ArtifactBucketName'].OutputValue" --output text
aws s3 rm s3://<ten-bucket> --recursive
aws cloudformation delete-stack --stack-name lab2-pipeline
aws cloudformation wait stack-delete-complete --stack-name lab2-pipeline 

# Xóa S3 bucket của taskcat
aws s3api list-buckets --query "Buckets[?starts_with(Name,'tcat-')].Name" --output text
aws s3 rb s3://<ten-bucket-tcat> --force

# Xóa Key Pair
aws ec2 delete-key-pair --key-name lab2-key 
```

Lệnh kiểm tra lại từng tài nguyên: 
```bash 
# NAT GW 
aws ec2 describe-nat-gateways --filter "Name=state,Values=available,pending,deleting" --query "NatGateways[].[NatGatewayId,State]"

# EIP 
aws ec2 describe-addresses --query "Addresses[].[PublicIp,AllocationId]"

# EC2 
aws ec2 describe-instances --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" --query "Reservations[].Instances[].[InstanceId,State.Name]"

# Taskcat stack 
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE UPDATE_ROLLBACK_COMPLETE ROLLBACK_COMPLETE CREATE_FAILED DELETE_FAILED --query "StackSummaries[?starts_with(StackName,'lab2-') || starts_with(StackName,'tCaT') || starts_with(StackName,'my-')].[StackName,StackStatus]"

# VPC 
aws ec2 describe-vpcs --filters "Name=is-default,Values=false" --query "Vpcs[].[VpcId,CidrBlock]"

# SG 
aws ec2 describe-security-groups --query "SecurityGroups[?GroupName!='default'].[GroupId,GroupName]"

# Key Pair 
aws ec2 describe-key-pairs --query "KeyPairs[].KeyName"

# Pipeline
aws codepipeline list-pipelines --query "pipelines[].name"
aws codecommit list-repositories --query "repositories[].repositoryName"
aws codebuild list-projects

# Artifact S3 Bucket 
aws s3api list-buckets --query "Buckets[?starts_with(Name,'tcat-') || contains(Name,'lab2')].Name"

# Log CodeBuild 
aws logs describe-log-groups --log-group-name-prefix /aws/codebuild/lab2 --query "logGroups[].logGroupName"

# IAM và EventBridge
aws iam list-roles --query "Roles[?contains(RoleName,'lab2')].RoleName"
aws events list-rules --query "Rules[?contains(Name,'lab2')].Name"
```
