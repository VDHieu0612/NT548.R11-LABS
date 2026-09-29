# BÀI TẬP THỰC HÀNH 02
> **Đề tài:** Quản lý và triển khai hạ tầng AWS và ứng dụng microservices với Terraform, CloudFormation, GitHub Actions, AWS CodePipeline và Jenkins  
> **Môn học:** Công nghệ DevOps và Ứng dụng (NT548) - UIT  

---

## 📋 CÁC NỘI DUNG YÊU CẦU

### 1. Task 1: Tự động hóa Terraform với GitHub Actions & Checkov (3 điểm)
- Tái sử dụng hạ tầng AWS đã xây dựng ở Bài thực hành 1 (`Lab1/terraform`).
- Tự động hóa quá trình `terraform fmt`, `validate`, `plan`, `apply` với **GitHub Actions** (`.github/workflows/deploy.yml`).
- Tích hợp công cụ **Checkov** để quét kiểm tra tính tuân thủ và bảo mật của mã nguồn Terraform trước khi triển khai.

### 2. Task 2: Tự động hóa CloudFormation với AWS CodePipeline (3 điểm)
- Tái sử dụng template CloudFormation của Bài thực hành 1 (`Lab1/cloudformation`).
- Sử dụng **AWS CodeCommit** làm kho chứa mã nguồn template.
- Sử dụng **AWS CodeBuild** tích hợp công cụ kiểm thử **`cfn-lint`** và **`taskcat`**.
- Dùng **AWS CodePipeline** để tự động kích hoạt quy trình build và deploy stack khi có commit mới.

### 3. Task 3: CI/CD Microservices với Jenkins, SonarQube & Container (4 điểm)
- Dựng server **Jenkins** tự động hóa quy trình build, test và deploy ứng dụng Microservices.
- Đóng gói ứng dụng bằng **Docker** và triển khai lên Kubernetes hoặc Docker container.
- Tích hợp **SonarQube** để phân tích chất lượng mã nguồn tĩnh.
- Tùy chọn: Tích hợp công cụ quét bảo mật **Trivy** hoặc **Snyk** để kiểm tra lỗ hổng của image.

---

*Thư mục này sẽ được triển khai chi tiết khi lớp bắt đầu Bài thực hành 02.*
