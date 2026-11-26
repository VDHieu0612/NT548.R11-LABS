# BÀI TẬP THỰC HÀNH 02
> **Đề tài:** Quản lý và triển khai hạ tầng AWS và ứng dụng microservices với Terraform, CloudFormation, GitHub Actions, AWS CodePipeline và Jenkins  
> **Môn học:** Công nghệ DevOps và Ứng dụng (NT548) - UIT  
> **Lớp:** NT548.R11 — Nhóm 04  

---

## 👥 PHÂN CÔNG NHIỆM VỤ THỰC HIỆN

| STT | Thành viên thực hiện | MSSV | Nhiệm vụ đảm nhiệm | Nhánh Git | Trạng thái |
|:---:|:---|:---:|:---|:---|:---:|
| 1 | **Cam Hồng Mạnh** | `23520914` | **Task 1:** Tự động hóa Terraform với GitHub Actions & Checkov | `feature/lab2-member2-github-actions` | ✅ Hoàn thành |
| 2 | **Lê Đoàn Phúc Thanh** | `24520030` | **Task 2:** Tự động hóa CloudFormation với AWS CodePipeline | `feature/lab2-member3-codepipeline` | ✅ Hoàn thành |
| 3 | **Võ Duy Hiếu (Leader)** | `23520498` | **Task 3:** CI/CD Platform (Docker Compose, Jenkins, SonarQube, App & Tests) | `feature/lab2-member1-jenkins-cicd` | ✅ Hoàn thành |
| 4 | **Hoàng Lê Nhật Minh** | `23520926` | **Task 3:** CI/CD Pipeline (Jenkinsfile, SonarQube & Trivy Security Gates, Deploy) | `feature/lab2-member4-jenkins-cicd` | ✅ Hoàn thành |

---

## 📋 CÁC NỘI DUNG YÊU CẦU & KẾT QUẢ ĐẠT ĐƯỢC

### 1. Task 1: Tự động hóa Terraform với GitHub Actions & Checkov (3 điểm) — *Cam Hồng Mạnh*
- **Mục tiêu:** Tự động hóa quy trình `terraform fmt`, `validate`, `plan`, `apply` khi có Pull Request / Push vào `main`.
- **Triển khai:**
  - Tái sử dụng workload 15 tài nguyên AWS từ Lab 1 tại `Lab2/Task1/terraform`.
  - Thiết lập remote state an toàn với S3 Bucket & DynamoDB State Lock qua thư mục `Lab2/Task1/bootstrap/`.
  - Tích hợp công cụ **Checkov** (`.checkov.yaml`) quét kiểm tra bảo mật IaC tĩnh, thiết lập Security Gate không cho phép vi phạm không được phê duyệt.
  - Xây dựng workflow GitHub Actions tại `.github/workflows/lab2-task1.yml`.
- 📖 **Chi tiết:** Xem 👉 **[Lab2/Task1/README.md](./Task1/README.md)**.

### 2. Task 2: Tự động hóa CloudFormation với AWS CodePipeline (3 điểm) — *Lê Đoàn Phúc Thanh*
- **Mục tiêu:** Tự động hóa CI/CD cho CloudFormation template khi có commit mới.
- **Triển khai:**
  - Sử dụng **AWS CodeCommit** làm kho chứa mã nguồn template (`Lab2/Task2/cfn-lab2/`).
  - Sử dụng **AWS CodeBuild** (`buildspec.yml`) tích hợp kiểm thử cú pháp bằng **`cfn-lint`** và kiểm thử đa region với **`taskcat`** (`.taskcat.yml`).
  - Khởi tạo toàn bộ pipeline tự động hóa bằng CloudFormation template: `Lab2/Task2/pipeline.yaml`.
- 📖 **Chi tiết:** Xem 👉 **[Lab2/Task2/README.md](./Task2/README.md)**.

### 3. Task 3: CI/CD Microservices với Jenkins, SonarQube & Container (4 điểm) — *Võ Duy Hiếu & Hoàng Lê Nhật Minh*
- **Mục tiêu:** Xây dựng pipeline CI/CD toàn trình cho ứng dụng Microservice với đầy đủ các cổng kiểm soát chất lượng mã nguồn và bảo mật container.
- **Triển khai:**
  - **Hạ tầng CI/CD:** Khởi chạy cụm **Jenkins Server** (tích hợp Docker CLI & Java 21), **SonarQube Server** và CSDL **PostgreSQL** thông qua `docker-compose.yml` và `Dockerfile.jenkins`.
  - **Ứng dụng mẫu:** REST API Node.js Express (`app/src/app.js`) kèm bộ Unit tests tự động bằng Jest (`app/test/app.test.js`) đạt 100% Code Coverage.
  - **Đóng gói Docker:** Multi-stage build (`app/Dockerfile`) chạy dưới quyền non-root `USER node`.
  - **Kiểm soát chất lượng mã nguồn:** Quét phân tích tĩnh bằng SonarQube Scanner (`sonar-project.properties`) và chặn pipeline nếu không đạt **Quality Gate**.
  - **Kiểm soát bảo mật container:** Tích hợp **Trivy** (`aquasec/trivy:latest`) quét lỗ hổng image, thiết lập Security Gate chặn triển khai nếu phát hiện lỗ hổng `CRITICAL`.
  - **Triển khai ứng dụng:** Tự động deploy container ứng dụng lên máy chủ và thực thi Smoke Test kiểm tra endpoint `/api/health`.
- 📖 **Chi tiết:** Xem 👉 **[Lab2/Task3/README.md](./Task3/README.md)**.

---

## 📂 CẤU TRÚC THƯ MỤC LAB 2

```text
Lab2/
├── Task1/                               # Task 1: Terraform + GitHub Actions + Checkov
│   ├── bootstrap/                       # Khởi tạo S3 backend & DynamoDB table lưu state
│   ├── config/                          # Cấu hình mẫu backend, biến GitHub & IAM policy
│   ├── docs/                            # Tài liệu IMPLEMENTATION, SECURITY, USER_SETUP
│   ├── scripts/                         # Script Python: security_gate, check_state, verify_local
│   ├── terraform/                       # Mã nguồn Terraform workload tái sử dụng từ Lab 1
│   │   ├── environments/dev/            # Root module dev
│   │   └── modules/                     # Modules vpc, nat, security, ec2
│   ├── tests/                           # Unit tests kiểm tra guards & logic script
│   ├── workflows/                       # File workflow lab2-task1.yml (đã kích hoạt tại .github/)
│   ├── .checkov.yaml                    # Cấu hình quy tắc quét bảo mật Checkov
│   ├── requirements-checkov.txt         # Khai báo phiên bản thư viện Checkov
│   ├── security-exceptions.json         # Danh sách ngoại lệ bảo mật được kiểm duyệt
│   └── README.md                        # Hướng dẫn chi tiết Task 1
├── Task2/                               # Task 2: CloudFormation + AWS CodePipeline
│   ├── cfn-lab2/                        # Thư mục mã nguồn đẩy lên CodeCommit
│   │   ├── cloudformation/              # Templates: 01-vpc, 02-sg, 03-ec2, master
│   │   ├── buildspec.yml                # Kịch bản CodeBuild chạy cfn-lint & taskcat
│   │   └── .taskcat.yml                 # Cấu hình kiểm thử đa region cho taskcat
│   ├── pipeline.yaml                    # Template CloudFormation tạo toàn bộ CodePipeline
│   └── README.md                        # Hướng dẫn chi tiết Task 2
├── Task3/                               # Task 3: Microservices CI/CD + Jenkins + SonarQube
│   ├── app/                             # Mã nguồn ứng dụng Microservice
│   │   ├── src/                         # REST API endpoints (app.js, server.js)
│   │   ├── test/                        # Bộ Jest unit tests (app.test.js)
│   │   ├── Dockerfile                   # Multi-stage build Dockerfile (non-root)
│   │   └── package.json                 # Cấu hình dependencies & test coverage
│   ├── docker-compose.yml               # Dựng cụm Jenkins, SonarQube, PostgreSQL
│   ├── Dockerfile.jenkins               # Image Jenkins JDK 21 tích hợp Docker CLI
│   ├── Jenkinsfile                      # Pipeline toàn trình: Test -> Sonar -> Docker -> Trivy -> Deploy
│   ├── sonar-project.properties         # Cấu hình project & coverage cho SonarQube
│   └── README.md                        # Hướng dẫn chi tiết Task 3
└── README.md                            # Tài liệu tổng quan Lab 2
```
