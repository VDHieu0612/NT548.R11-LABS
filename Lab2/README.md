# BÀI TẬP THỰC HÀNH 02
> **Đề tài:** Quản lý và triển khai hạ tầng AWS và ứng dụng microservices với Terraform, CloudFormation, GitHub Actions, AWS CodePipeline và Jenkins  
> **Môn học:** Công nghệ DevOps và Ứng dụng (NT548) - UIT  

---

## 👥 PHÂN CÔNG NHIỆM VỤ THỰC HIỆN

| STT | Thành viên thực hiện | MSSV | Nhiệm vụ đảm nhiệm | Nhánh Git dự kiến |
|:---:|:---|:---:|:---|:---|
| 1 | **Cam Hồng Mạnh** | `23520914` | **Task 1:** Tự động hóa Terraform với GitHub Actions & Checkov | `feature/lab2-member2-github-actions` |
| 2 | **Lê Đoàn Phúc Thanh** | `24520030` | **Task 2:** Tự động hóa CloudFormation với AWS CodePipeline | `feature/lab2-member3-codepipeline` |
| 3 | **Võ Duy Hiếu (Leader)** | `23520498` | **Task 3:** CI/CD Microservices với Jenkins, SonarQube & Container | `feature/lab2-member1-jenkins-cicd` |
| 4 | **Hoàng Lê Nhật Minh** | `23520926` | **Task 3:** CI/CD Microservices với Jenkins, SonarQube & Container | `feature/lab2-member4-jenkins-cicd` |

---

## 📋 CÁC NỘI DUNG YÊU CẦU

### 1. Task 1: Tự động hóa Terraform với GitHub Actions & Checkov (3 điểm) — *Phụ trách: Cam Hồng Mạnh*
- Tái sử dụng hạ tầng AWS đã xây dựng ở Bài thực hành 1 (`Lab1/terraform`).
- Tự động hóa quá trình `terraform fmt`, `validate`, `plan`, `apply` với **GitHub Actions** (`.github/workflows/deploy.yml` hoặc `terraform-ci.yml`).
- Tích hợp công cụ **Checkov** để quét kiểm tra tính tuân thủ và bảo mật của mã nguồn Terraform trước khi triển khai.
- **Thư mục làm việc:** `Lab2/Task1/` & `.github/workflows/`

### 2. Task 2: Tự động hóa CloudFormation với AWS CodePipeline (3 điểm) — *Phụ trách: Lê Đoàn Phúc Thanh*
- Tái sử dụng template CloudFormation của Bài thực hành 1 (`Lab1/cloudformation`).
- Sử dụng **AWS CodeCommit** làm kho chứa mã nguồn template.
- Sử dụng **AWS CodeBuild** tích hợp công cụ kiểm thử **`cfn-lint`** và **`taskcat`**.
- Dùng **AWS CodePipeline** để tự động kích hoạt quy trình build và deploy stack khi có commit mới.
- **Thư mục làm việc:** `Lab2/Task2/`

### 3. Task 3: CI/CD Microservices với Jenkins, SonarQube & Container (4 điểm) — *Phụ trách: Võ Duy Hiếu & Hoàng Lê Nhật Minh*
- Dựng server **Jenkins** tự động hóa quy trình build, test và deploy ứng dụng Microservices.
- Đóng gói ứng dụng bằng **Docker** và triển khai lên Kubernetes hoặc Docker container.
- Tích hợp **SonarQube** để phân tích chất lượng mã nguồn tĩnh.
- Tùy chọn: Tích hợp công cụ quét bảo mật **Trivy** hoặc **Snyk** để kiểm tra lỗ hổng của image.
- **Thư mục làm việc:** `Lab2/Task3/`

---

## 📂 CẤU TRÚC THƯ MỤC LAB 2

```text
Lab2/
├── Task1/             # Tự động hóa Terraform (GitHub Actions & Checkov)
│   └── README.md
├── Task2/             # Tự động hóa CloudFormation (AWS CodePipeline, CodeBuild, cfn-lint)
│   └── README.md
├── Task3/             # CI/CD Microservices (Jenkins, Docker, SonarQube)
│   └── README.md
└── README.md          # Tài liệu tổng quan Lab 2
```
