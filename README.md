# NT548.R11-LABS — CÔNG NGHỆ DEVOPS VÀ ỨNG DỤNG

> **Trường:** Đại học Công nghệ Thông tin - ĐHQG-HCM (UIT)  
> **Khoa:** Mạng máy tính và Truyền thông  
> **Môn học:** Công nghệ DevOps và Ứng dụng (NT548)  
> **Lớp:** NT548.R11  
> **Giảng viên hướng dẫn:** ThS. Lê Anh Tuấn  

---

## 👥 THÀNH VIÊN NHÓM THỰC HIỆN

| STT | Họ và Tên | MSSV | Vai trò chính | Nhiệm vụ đảm nhiệm |
|:---:|:---|:---:|:---|:---|
| 1 | **Võ Duy Hiếu (Leader)** | `23520498` | Quản lý dự án, Network IaC Lead & CI/CD Platform | - Quản lý cấu trúc Monorepo & quy trình Git Flow<br>- **Lab 1:** Xây dựng module Terraform `vpc` & `nat` (VPC, Subnets, IGW, NAT GW, EIP)<br>- **Lab 2:** Thiết lập cụm CI/CD local (`docker-compose.yml`, `Dockerfile.jenkins`), xây dựng Microservice Node.js & Jest Unit Tests |
| 2 | **Cam Hồng Mạnh** | `23520914` | Compute & Security Lead (Terraform & CI/CD) | - **Lab 1:** Xây dựng module Terraform `security` (SG) & `ec2` (Bastion Host, Private EC2)<br>- **Lab 2:** Tự động hóa Terraform CI/CD qua GitHub Actions, tích hợp bảo mật Checkov Security Gate, S3 remote state bootstrap |
| 3 | **Lê Đoàn Phúc Thanh** | `24520030` | AWS CloudFormation & CodePipeline Lead | - **Lab 1:** Triển khai hạ tầng bằng CloudFormation templates (VPC, Subnets, SG, EC2, Nested Stack)<br>- **Lab 2:** Tự động hóa CloudFormation CI/CD bằng AWS CodePipeline, CodeBuild, `cfn-lint` & `taskcat` |
| 4 | **Hoàng Lê Nhật Minh** | `23520926` | QA, Test Automation & DevSecOps Lead | - **Lab 1:** Xây dựng ma trận kịch bản kiểm thử (TC01-TC06) & script tự động `test_connectivity.sh`<br>- **Lab 2:** Xây dựng `Jenkinsfile` hoàn chỉnh cho Microservice: tích hợp SonarQube Quality Gate, quét lỗ hổng Trivy Security Scan và deploy container |

---

## 📚 TỔNG QUAN CÁC BÀI THỰC HÀNH

### 📍 [Bài Thực Hành 01: Quản lý và Triển khai Hạ Tầng AWS với Terraform & CloudFormation](./Lab1)
- **Mục tiêu:** Tự động hóa khởi tạo VPC, Public/Private Subnets, Internet Gateway, NAT Gateway, Route Tables, Security Groups và EC2 Instances (Bastion Host Pattern).
- **Công nghệ:** Terraform (Module hóa), AWS CloudFormation (Nested Stacks), Bash Script Testing tự động.
- **Trạng thái:** ✅ **Hoàn thành 100%** (Đã kiểm thử thực tế trên AWS và thu hồi tài nguyên sạch).
- **Chi tiết:** Xem hướng dẫn phân chia task và cấu trúc mã nguồn tại 👉 **[Lab1/README.md](./Lab1/README.md)**.

### 📍 [Bài Thực Hành 02: Tự Động Hóa CI/CD Hạ Tầng AWS & Ứng Dụng Microservices](./Lab2)
- **Mục tiêu:**
  - **Task 1 (3đ):** Tự động hóa triển khai Terraform với GitHub Actions (`.github/workflows/lab2-task1.yml`), quét bảo mật IaC với Checkov, quản lý S3 backend state.
  - **Task 2 (3đ):** Tự động hóa build/deploy CloudFormation qua AWS CodePipeline, AWS CodeBuild tích hợp `cfn-lint` và `taskcat`.
  - **Task 3 (4đ):** Xây dựng pipeline CI/CD toàn trình cho ứng dụng Microservices qua Jenkins, Docker, SonarQube (Quality Gate), Trivy (Vulnerability Scan) và triển khai container.
- **Trạng thái:** ✅ **Hoàn thành 100%** (Cả 3 task đã được kiểm thử và hợp nhất vào nhánh `main`).
- **Chi tiết:** Xem hướng dẫn và cấu hình từng task tại 👉 **[Lab2/README.md](./Lab2/README.md)**.

---

## 📂 CẤU TRÚC MONOREPO

```text
NT548.R11-LABS/
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md         # Template tạo PR chuẩn quy trình Git Flow
│   └── workflows/
│       └── lab2-task1.yml               # GitHub Actions CI/CD cho Terraform & Checkov (Task 1)
├── Lab1/                                # BÀI THỰC HÀNH 01 (Terraform & CloudFormation)
│   ├── cloudformation/                  # CloudFormation templates (01-vpc, 02-sg, 03-ec2, master)
│   ├── terraform/                       # Terraform modules (vpc, nat, security, ec2) & dev environment
│   ├── scripts/                         # Script test_connectivity.sh tự động kiểm thử kết nối
│   └── README.md                        # Hướng dẫn chi tiết triển khai Lab 1
├── Lab2/                                # BÀI THỰC HÀNH 02 (CI/CD Pipeline)
│   ├── Task1/                           # Task 1: Terraform + GitHub Actions + Checkov
│   │   ├── bootstrap/                   # Terraform bootstrap S3 bucket & DynamoDB lock
│   │   ├── config/                      # Cấu hình backend, IAM policies mẫu
│   │   ├── docs/                        # Tài liệu hướng dẫn thiết lập & phân tích bảo mật
│   │   ├── scripts/                     # Security gate, state guards, kiểm tra local
│   │   ├── terraform/                   # Modules & môi trường dev cho Task 1
│   │   ├── tests/                       # Unit tests cho các guards kiểm soát
│   │   ├── workflows/                   # Bản sao workflow lab2-task1.yml
│   │   ├── .checkov.yaml                # Cấu hình rule Checkov IaC scanning
│   │   └── README.md                    # Hướng dẫn chi tiết Task 1
│   ├── Task2/                           # Task 2: CloudFormation + AWS CodePipeline
│   │   ├── cfn-lab2/                    # Thư mục mã nguồn đẩy lên AWS CodeCommit
│   │   │   ├── cloudformation/          # Templates CloudFormation tái sử dụng từ Lab 1
│   │   │   ├── buildspec.yml            # CodeBuild: chạy cfn-lint và taskcat
│   │   │   └── .taskcat.yml             # Cấu hình kiểm thử đa region với taskcat
│   │   ├── pipeline.yaml                # CloudFormation template khởi tạo CodePipeline
│   │   └── README.md                    # Hướng dẫn chi tiết triển khai Task 2
│   ├── Task3/                           # Task 3: Microservices CI/CD + Jenkins + SonarQube
│   │   ├── app/                         # Mã nguồn REST API Node.js Express, Jest tests & Dockerfile
│   │   ├── docker-compose.yml           # Khởi chạy cụm Jenkins, SonarQube và PostgreSQL
│   │   ├── Dockerfile.jenkins           # Image Jenkins mở rộng tích hợp Docker CLI (Java 21)
│   │   ├── Jenkinsfile                  # Pipeline toàn trình: Test -> SonarQube -> Docker -> Trivy -> Deploy
│   │   ├── sonar-project.properties     # Cấu hình quét mã nguồn cho SonarQube
│   │   └── README.md                    # Hướng dẫn vận hành & kiểm thử Task 3
│   └── README.md                        # Tổng quan yêu cầu và phân công Lab 2
├── .gitattributes                       # Quy chuẩn định dạng xuống dòng LF cho script *.sh
├── .gitignore                           # Loại bỏ file nhạy cảm (.tfstate, *.pem, node_modules, logs)
└── README.md                            # Trang chủ tổng quan dự án môn học
```

---

## 📑 QUY TRÌNH PHỐI HỢP GIT FLOW
1. **Branch chính:** `main` (chỉ merge khi có sự review và code đã pass kiểm thử).
2. **Quy tắc đặt tên nhánh (Branch Naming):**
   - Lab 1: `feature/lab1-memberX-taskname`
   - Lab 2: `feature/lab2-memberX-taskname`
3. **Commit Message:** Tuân thủ chuẩn Conventional Commits:
   - `feat: add vpc terraform module`
   - `fix: correct security group ingress port`
   - `docs: update lab1 test cases report`
4. **Pull Request:** Mọi thay đổi đều được mở PR vào `main`, sử dụng template chuẩn và tag ít nhất 1 thành viên review trước khi hợp nhất.
