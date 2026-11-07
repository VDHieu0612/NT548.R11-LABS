# NT548.R11-LABS — CÔNG NGHỆ DEVOPS VÀ ỨNG DỤNG

> **Trường:** Đại học Công nghệ Thông tin - ĐHQG-HCM (UIT)  
> **Khoa:** Mạng máy tính và Truyền thông  
> **Môn học:** Công nghệ DevOps và Ứng dụng (NT548)  
> **Lớp:** NT548.R11  
> **Giảng viên hướng dẫn:** ThS. Lê Anh Tuấn  

---

## 👥 THÀNH VIÊN NHÓM THỰC HIỆN

| STT | Họ và Tên | MSSV | Vai trò chính |
|:---:|:---|:---:|:---|
| 1 | **Võ Duy Hiếu (Leader)** | `23520498` | Quản lý dự án, Network Infrastructure Lead |
| 2 | **Cam Hồng Mạnh** | `23520914` | Compute & Security Lead (Terraform) |
| 3 | **Lê Đoàn Phúc Thanh** | `24520030` | AWS CloudFormation Lead |
| 4 | **Hoàng Lê Nhật Minh** | `23520926` | QA, Test Automation & Technical Documentation |

---

## 📚 TỔNG QUAN CÁC BÀI THỰC HÀNH

### 📍 [Bài Thực Hành 01: Quản lý và Triển khai Hạ Tầng AWS với Terraform & CloudFormation](./Lab1)
- **Mục tiêu:** Tự động hóa khởi tạo VPC, Public/Private Subnets, Internet Gateway, NAT Gateway, Route Tables, Security Groups và EC2 Instances (Bastion Host Pattern).
- **Công nghệ:** Terraform (Module hóa), AWS CloudFormation, Bash Script Testing.
- **Chi tiết:** Xem hướng dẫn phân chia task và cấu trúc mã nguồn tại 👉 **[Lab1/README.md](./Lab1/README.md)**.

### 📍 [Bài Thực Hành 02: Tự Động Hóa CI/CD Hạ Tầng AWS & Ứng Dụng Microservices](./Lab2)
- **Mục tiêu:**
  - **Task 1:** Tự động hóa triển khai Terraform với GitHub Actions + Quét bảo mật Checkov.
  - **Task 2:** Tự động hóa build/deploy CloudFormation với AWS CodePipeline, CodeCommit, CodeBuild (cfn-lint & taskcat).
  - **Task 3:** CI/CD cho ứng dụng Microservices qua Jenkins, Docker, SonarQube, Trivy và Kubernetes.
- **Chi tiết:** Xem kế hoạch chuẩn bị tại 👉 **[Lab2/README.md](./Lab2/README.md)**.

---

## 📂 CẤU TRÚC MONOREPO

```text
NT548.R11-LABS/
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md         # Template tạo PR chuẩn quy trình Git Flow
│   └── workflows/                       # GitHub Actions CI/CD (dùng cho Lab 2 Task 1)
├── Lab1/                                # BÀI THỰC HÀNH 01 (Terraform & CloudFormation)
│   ├── cloudformation/                  # CloudFormation templates
│   ├── terraform/                       # Terraform modules & dev environment
│   ├── scripts/                         # Script test kết nối tự động
│   └── README.md                        # Hướng dẫn chi tiết triển khai Lab 1
├── Lab2/                                # BÀI THỰC HÀNH 02 (CI/CD Pipeline)
│   ├── Task1/                           # Terraform + GitHub Actions + Checkov
│   ├── Task2/                           # CloudFormation + AWS CodePipeline
│   ├── Task3/                           # Microservices CI/CD + Jenkins + SonarQube
│   └── README.md                        # Kế hoạch và hướng dẫn triển khai Lab 2
├── .gitignore                           # Loại bỏ file nhạy cảm (.tfstate, *.pem, v.v.)
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
4. **Pull Request:** Mọi thay đổi đều được mở PR vào `main`, sử dụng template chuẩn và tag ít nhất 1 thành viên review.
