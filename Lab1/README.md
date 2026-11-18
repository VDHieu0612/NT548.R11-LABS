# NT548 - BÀI TẬP THỰC HÀNH 01
> **Đề tài:** Dùng Terraform và CloudFormation để quản lý và triển khai hạ tầng AWS  
> **Môn học:** Công nghệ DevOps và Ứng dụng (NT548) - UIT  
> **Giảng viên hướng dẫn:** ThS. Lê Anh Tuấn  

---

## 👥 THÀNH VIÊN NHÓM VÀ PHÂN CÔNG CÔNG VIỆC

| STT | Họ và Tên | MSSV | Vai trò chính | Nhiệm vụ đảm nhiệm | Tự đánh giá |
|:---:|:---|:---:|:---|:---|:---:|
| 1 | **Võ Duy Hiếu (Leader)** | `23520498` | **Network IaC Lead (Terraform)** | - Quản lý repo, kiến trúc tổng thể hạ tầng<br>- Viết Module Terraform `vpc` (VPC, Public/Private Subnets, IGW, Default SG)<br>- Viết Module Terraform `nat` (EIP, NAT Gateway, Public/Private Route Tables)<br>- Review & Merge Pull Requests | 100% |
| 2 | **Cam Hồng Mạnh** | `23520914` | **Compute & Security IaC (Terraform)** | - Viết Module Terraform `security` (Public/Private Security Groups)<br>- Viết Module Terraform `ec2` (Bastion Host, Private EC2, Key Pair)<br>- Tích hợp Root Terraform (`main.tf`, `variables.tf`, `outputs.tf`)<br>- Thực hiện kiểm thử hạ tầng Terraform | 100% |
| 3 | **Lê Đoàn Phúc Thanh** | `24520030` | **CloudFormation Lead** | - Triển khai hạ tầng tương đương bằng AWS CloudFormation<br>- Viết `01-vpc-network.yaml` (VPC, Subnets, IGW, NAT GW, Route Tables)<br>- Viết `02-security-groups.yaml` (Security Groups)<br>- Viết `03-ec2-instances.yaml` (Public/Private EC2, KeyPair)<br>- Hướng dẫn triển khai CloudFormation CLI / Console | 100% |
| 4 | **Hoàng Lê Nhật Minh** | `23520926` | **QA, Test Automation & Report Lead** | - Viết kịch bản kiểm thử (Test Cases Matrix)<br>- Viết script tự động kiểm thử kết nối (`scripts/test_connectivity.sh`)<br>- Thu thập log, chụp ảnh minh chứng hoạt động của hệ thống<br>- Soạn thảo Báo cáo thực hành file Word theo đúng biểu mẫu UIT | 100% |

---

## 🏛️ KIẾN TRÚC HẠ TẦNG (ARCHITECTURE OVERVIEW)

```
                            [ INTERNET ]
                                 ▲
                                 │
                        ┌────────▼────────┐
                        │ Internet Gateway│
                        └────────┬────────┘
                                 │
┌─── AWS VPC (10.0.0.0/16) ──────┼────────────────────────────────────────┐
│                                │                                        │
│  ┌── Public Subnet (10.0.1.0/24)─────────────────────────────────────┐  │
│  │                             │                                     │  │
│  │    ┌───────────────────┐    │         ┌──────────────────────┐    │  │
│  │    │   NAT Gateway     │◄───┘         │  Public EC2 Instance │    │  │
│  │    │   (Elastic IP)    │              │     (Bastion Host)   │    │  │
│  │    └─────────▲─────────┘              │  (SSH Port 22: MyIP) │    │  │
│  │              │                        └──────────▲───────────┘    │  │
│  └──────────────┼───────────────────────────────────┼────────────────┘  │
│                 │                                   │                   │
│                 │ (Internet Outbound)               │ (SSH Inbound)     │
│                 │                                   │                   │
│  ┌── Private Subnet (10.0.2.0/24)───────────────────┼────────────────┐  │
│  │              │                                   ▼                │  │
│  │              └────────────────────────►┌──────────────────────┐   │  │
│  │                                        │ Private EC2 Instance │   │  │
│  │                                        │   (Private Subnet)   │   │  │
│  │                                        │  (SSH from Bastion)  │   │  │
│  │                                        └──────────────────────┘   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 📂 CẤU TRÚC THƯ MỤC DỰ ÁN

```text
.
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md         # Template tạo PR chuẩn quy trình Git Flow
├── terraform/                           # Triển khai bằng Terraform (Module hóa)
│   ├── environments/
│   │   └── dev/
│   │       ├── main.tf                  # Root module gọi các submodules
│   │       ├── variables.tf             # Input variables
│   │       ├── outputs.tf               # Outputs (IPs, Subnet IDs, VPC ID)
│   │       ├── providers.tf             # Cấu hình AWS provider
│   │       └── terraform.tfvars.example # File mẫu cấu hình biến
│   └── modules/
│       ├── vpc/                         # Module VPC, Subnets, IGW, Default SG
│       ├── nat/                         # Module NAT Gateway, EIP, Route Tables
│       ├── security/                    # Module Security Groups
│       └── ec2/                         # Module EC2 Instances & Key Pair
├── cloudformation/                      # Triển khai bằng CloudFormation Templates
│   ├── master.yaml                      # Template Master điều phối (Nested Stacks)
│   ├── 01-vpc-network.yaml              # VPC, Subnet, IGW, NAT GW, Route Tables
│   ├── 02-security-groups.yaml          # Security Groups cho Public/Private
│   └── 03-ec2-instances.yaml            # EC2 instances, UserData
├── scripts/
│   └── test_connectivity.sh             # Script kiểm thử kết nối tự động
├── .gitignore                           # Loại bỏ file nhạy cảm (.tfstate, *.pem, v.v.)
└── README.md
```

---

## 📖 HƯỚNG DẪN CHI TIẾT TỪNG FILE & NHIỆM VỤ THÀNH VIÊN

Phần này giúp từng thành viên hình dung rõ cấu trúc, mục đích của từng file và cần viết những gì vào đó.

### 1. Phân hệ Terraform Modules & Dev Root

#### 🔹 `terraform/modules/vpc/` (Võ Duy Hiếu phụ trách)
- `main.tf`: Khai báo các tài nguyên mạng cơ bản:
  - `aws_vpc`: Khởi tạo VPC với CIDR block (mặc định `10.0.0.0/16`), bật `enable_dns_support` và `enable_dns_hostnames`.
  - `aws_internet_gateway`: Tạo IGW và gắn vào VPC.
  - `aws_subnet.public`: Tạo Public Subnet (`10.0.1.0/24`), bật `map_public_ip_on_launch = true`.
  - `aws_subnet.private`: Tạo Private Subnet (`10.0.2.0/24`), tắt public IP (`map_public_ip_on_launch = false`).
  - `aws_default_security_group`: Khởi tạo Default Security Group cho VPC (theo yêu cầu đề bài).
- `variables.tf`: Khai báo các input variables: `vpc_cidr`, `public_subnet_cidr`, `private_subnet_cidr`, `availability_zone`, `project_name`.
- `outputs.tf`: Xuất các giá trị cần cho các module khác: `vpc_id`, `public_subnet_id`, `private_subnet_id`, `internet_gateway_id`, `default_security_group_id`.

#### 🔹 `terraform/modules/nat/` (Võ Duy Hiếu phụ trách)
- `main.tf`: Khai báo NAT và bảng định tuyến (Route Tables):
  - `aws_eip`: Cấp phát 1 Elastic IP cho NAT Gateway.
  - `aws_nat_gateway`: Tạo NAT Gateway đặt tại **Public Subnet** và gắn Elastic IP trên.
  - `aws_route_table.public`: Bảng định tuyến Public với route `0.0.0.0/0` trỏ tới `Internet Gateway`.
  - `aws_route_table_association.public`: Gắn bảng định tuyến Public vào Public Subnet.
  - `aws_route_table.private`: Bảng định tuyến Private với route `0.0.0.0/0` trỏ tới `NAT Gateway`.
  - `aws_route_table_association.private`: Gắn bảng định tuyến Private vào Private Subnet.
- `variables.tf`: Nhận các biến từ module VPC: `vpc_id`, `public_subnet_id`, `private_subnet_id`, `internet_gateway_id`.
- `outputs.tf`: Xuất `nat_gateway_id`, `nat_eip`, `public_route_table_id`, `private_route_table_id`.

#### 🔹 `terraform/modules/security/` (Cam Hồng Mạnh phụ trách)
- `main.tf`: Khai báo các nhóm bảo mật (Security Groups):
  - `aws_security_group.public_ec2_sg`: Chỉ cho phép Ingress SSH (port 22) từ IP cụ thể của bạn (`var.allowed_ssh_ip`). Egress mở cho mọi luồng.
  - `aws_security_group.private_ec2_sg`: Ingress SSH (port 22) và Ping (ICMP) **chỉ cho phép nguồn từ Public Security Group** (`security_groups = [aws_security_group.public_ec2_sg.id]`). Egress mở ra ngoài để qua NAT GW.
- `variables.tf`: Nhận `vpc_id` và `allowed_ssh_ip`.
- `outputs.tf`: Xuất `public_security_group_id` và `private_security_group_id`.

#### 🔹 `terraform/modules/ec2/` (Cam Hồng Mạnh phụ trách)
- `main.tf`: Khai báo máy ảo:
  - `data "aws_ami"`: Lấy AMI Amazon Linux 2023 mới nhất.
  - `aws_instance.public_ec2`: Máy Bastion đặt tại Public Subnet, gắn Public SG, có Public IP (`associate_public_ip_address = true`), gắn SSH Key Pair.
  - `aws_instance.private_ec2`: Máy App đặt tại Private Subnet, gắn Private SG, không có Public IP (`associate_public_ip_address = false`), gắn SSH Key Pair.
- `variables.tf`: Nhận `public_subnet_id`, `private_subnet_id`, `public_security_group_id`, `private_security_group_id`, `key_name`, `instance_type`.
- `outputs.tf`: Xuất `public_ec2_ip` và `private_ec2_internal_ip`.

#### 🔹 `terraform/environments/dev/` (Cam Hồng Mạnh phụ trách ghép nối)
- `providers.tf`: Cấu hình provider AWS, phiên bản Terraform và Region.
- `variables.tf`: Khai báo các tham số đầu vào cho môi trường Dev (`aws_region`, `allowed_ssh_ip`, `key_name`, v.v.).
- `terraform.tfvars.example`: Mẫu giá trị truyền vào (IP cá nhân, tên key `vockey`) để người dùng tạo file `terraform.tfvars`.
- `main.tf`: Root module gọi và liên kết 4 module trên lại với nhau (`module.vpc -> module.nat, module.security -> module.ec2`).
- `outputs.tf`: In ra màn hình sau khi apply xong: IP Public Bastion, IP Private EC2, Elastic IP NAT, câu lệnh SSH mẫu.

---

### 2. Phân hệ CloudFormation (Lê Đoàn Phúc Thanh phụ trách)

- `cloudformation/01-vpc-network.yaml`:
  - Viết template tạo VPC, Public Subnet, Private Subnet, IGW, EIP, NAT Gateway, 2 Route Tables và Associations.
  - Phần `Outputs` phải dùng `Export: Name: ...` để export `VpcId`, `PublicSubnetId`, `PrivateSubnetId`, `NatPublicIP`.
- `cloudformation/02-security-groups.yaml`:
  - Viết template tạo 2 Security Groups (Public & Private).
  - Dùng `Fn::ImportValue` để import `VpcId` từ stack 1.
  - Export `PublicSecurityGroupId` và `PrivateSecurityGroupId`.
- `cloudformation/03-ec2-instances.yaml`:
  - Viết template tạo 2 máy ảo EC2.
  - Dùng `Fn::ImportValue` để import Subnet IDs và Security Group IDs từ stack 1 và stack 2.
  - Xuất ra `PublicEC2IP` và `PrivateEC2InternalIP`.

---

### 3. Phân hệ Scripts & Automation (Hoàng Lê Nhật Minh phụ trách)

- `scripts/test_connectivity.sh`:
  - Bash script nhận tham số: `<path_key.pem> <PUBLIC_IP> <PRIVATE_IP> [NAT_EIP]`.
  - Thực hiện kiểm tra tự động:
    1. SSH vào Public EC2 (TC01) bằng command `ssh -i <key> ec2-user@<PUBLIC_IP> "uptime"`.
    2. (Cần AWS CLI) Kiểm tra Public SG không mở SSH cho `0.0.0.0/0` (TC02 - phần cấu hình).
    3. SSH thẳng vào Private IP phải thất bại; Private EC2 không có Public IP (TC03).
    4. SSH nhảy cóc vào Private EC2 qua Bastion bằng `ProxyCommand` và ping từ Bastion (TC04).
       > Không dùng `-J`/`ProxyJump` vì tùy chọn `-i <key>` không được áp dụng cho chặng Bastion.
    5. Từ Private EC2 gọi `curl checkip.amazonaws.com` để xác minh IP ra Internet chính là Elastic IP của NAT Gateway (TC05).
  - In kết quả `PASSED` / `FAILED` / `SKIPPED`, trả exit code 0 khi không có test FAILED (TC06) và lưu log vào `scripts/logs/` (đã gitignore).
- `docs/BaoCao_Lab01_Nhom04.docx`: Báo cáo thực hành theo biểu mẫu UIT (các chỗ tô vàng là ảnh minh chứng / kết quả cần điền sau khi chạy test).

---

## 🚀 HƯỚNG DẪN TRIỂN KHAI

### 1. Triển khai bằng Terraform
```bash
# 1. Chuyển vào thư mục dev
cd terraform/environments/dev

# 2. Tạo file cấu hình biến từ file mẫu
cp terraform.tfvars.example terraform.tfvars
# Chỉnh sửa IP của bạn trong terraform.tfvars

# 3. Khởi tạo và kiểm tra
terraform init
terraform plan

# 4. Triển khai hạ tầng
terraform apply -auto-approve

# 5. Hủy tài nguyên sau khi nghiệm thu
terraform destroy -auto-approve
```

### 2. Triển khai bằng CloudFormation
```bash
# Triển khai qua AWS CLI (chạy tại thư mục Lab1/)
aws cloudformation deploy \
  --template-file cloudformation/01-vpc-network.yaml \
  --stack-name my-vpc \
  --parameter-overrides ProjectName=NT548-Lab01

aws cloudformation deploy \
  --template-file cloudformation/02-security-groups.yaml \
  --stack-name my-sg \
  --parameter-overrides NetworkStackName=my-vpc MyIp=$(curl -s https://checkip.amazonaws.com)/32

aws cloudformation deploy \
  --template-file cloudformation/03-ec2-instances.yaml \
  --stack-name my-ec2 \
  --parameter-overrides NetworkStackName=my-vpc SecurityStackName=my-sg KeyName=vockey

# Hủy tài nguyên (theo thứ tự ngược vì các stack Export/Import lẫn nhau)
for s in my-ec2 my-sg my-vpc; do
  aws cloudformation delete-stack --stack-name $s
  aws cloudformation wait stack-delete-complete --stack-name $s
done
```

### 3. Chạy kiểm thử tự động
```bash
# Hạ tầng Terraform (chạy tại Lab1/terraform/environments/dev)
bash ../../../scripts/test_connectivity.sh ~/.ssh/labsuser.pem \
  $(terraform output -raw public_bastion_ip) \
  $(terraform output -raw private_instance_internal_ip) \
  $(aws ec2 describe-addresses --filters Name=tag:Name,Values=NT548-Lab01-nat-eip --query 'Addresses[0].PublicIp' --output text)

# Hạ tầng CloudFormation (chạy tại Lab1/)
get() { aws cloudformation describe-stacks --stack-name "$1" \
          --query "Stacks[0].Outputs[?OutputKey=='$2'].OutputValue" --output text; }
bash scripts/test_connectivity.sh ~/.ssh/labsuser.pem \
  $(get my-ec2 PublicEC2IP) $(get my-ec2 PrivateEC2InternalIP) $(get my-vpc NatPublicIP)
```
TC02 cần kiểm tra thủ công từ một IP khác (ví dụ AWS CloudShell): `ssh -o ConnectTimeout=10 -i labsuser.pem ec2-user@<PUBLIC_IP>` phải bị timeout.

---

## 🧪 KỊCH BẢN KIỂM THỬ (TEST CASES)

| Test ID | Tên kịch bản | Thao tác thực hiện | Kết quả kỳ vọng |
|:---:|:---|:---|:---|
| **TC01** | Kiểm tra SSH vào Public EC2 | `ssh -i <key.pem> ec2-user@<PUBLIC_IP>` từ máy cá nhân | Kết nối SSH thành công |
| **TC02** | Chặn SSH từ IP lạ | Thử SSH vào Public EC2 từ IP không nằm trong whitelist | Kết nối bị Timeout / Connection Denied |
| **TC03** | Chặn SSH trực tiếp vào Private EC2 | Thử SSH trực tiếp vào IP nội bộ hoặc IP Public (nếu có) từ Internet | Không thể truy cập từ Internet |
| **TC04** | SSH từ Public EC2 sang Private EC2 | SSH vào Public EC2, sau đó chạy `ssh ec2-user@<PRIVATE_IP>` | Kết nối thành công (Bastion pattern) |
| **TC05** | Private EC2 ra Internet qua NAT Gateway | Đứng trên Private EC2 chạy: `curl -I https://google.com` hoặc `curl ifconfig.me` | Kết nối thành công; IP trả về chính là Elastic IP của NAT Gateway |
| **TC06** | Test Script tự động | Chạy `bash scripts/test_connectivity.sh <key> <PUBLIC_IP> <PRIVATE_IP> [NAT_EIP]` | Không có test FAILED, exit code 0 |

---

## 📑 QUY TRÌNH LÀM VIỆC NHÓM TRÊN GIT (GIT FLOW)
1. **Branch chính:** `main` (chỉ merge khi đã test thành công và qua review).
2. **Branch chức năng:** Mỗi thành viên tạo branch theo cú pháp:
   - `feature/member1-terraform-vpc-nat`
   - `feature/member2-terraform-ec2-sg`
   - `feature/member3-cloudformation`
   - `feature/member4-tests-docs`
3. **Commit message:** Rõ ràng, tuân thủ conventional commits: `feat: add vpc module`, `fix: security group ssh ingress rule`, `docs: update test cases report`.
4. **Pull Request (PR):** Tạo PR vào `main`, tag ít nhất 1 thành viên review trước khi merge.
