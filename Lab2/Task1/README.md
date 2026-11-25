# Task 1: Tự động hóa Terraform với GitHub Actions & Checkov
- **Thành viên phụ trách:** Cam Hồng Mạnh (23520914)
- **Mục tiêu:**
  - Tái sử dụng kiến trúc và mã nguồn Lab 1 qua bản sao tại `Lab2/Task1/terraform`.
  - Thiết lập GitHub Actions workflow (`.github/workflows/deploy.yml` hoặc `terraform-ci.yml`) để tự động hóa `fmt`, `validate`, `plan`, `apply`.
  - Tích hợp **Checkov** kiểm tra bảo mật IaC.

## Source Terraform của Task 1

```text
Lab2/Task1/
├── README.md
└── terraform/
    ├── environments/dev/
    │   ├── .terraform-version
    │   ├── .terraform.lock.hcl
    │   ├── main.tf
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── terraform.tfvars.example
    │   └── tests/inputs.tftest.hcl
    └── modules/
        ├── vpc/
        ├── nat/
        ├── security/
        └── ec2/
```

Theo yêu cầu tổ chức bài làm, `Lab1/terraform` được giữ nguyên ở baseline; mọi thay đổi Terraform cho Task 1 được thực hiện trên bản Lab 2. Bốn module giữ kiến trúc Lab 1. Các đường dẫn `../../modules/...` trong Root Module trỏ tới modules bên trong `Lab2/Task1/terraform`.

Bản Lab 2 có các bổ sung của bước chuẩn hóa: chọn Terraform 1.17.1 qua `.terraform-version`, kiểm tra SSH IPv4 `/32`, kiểm tra Region/AZ, dependency NAT đợi VPC/IGW và Root Outputs phục vụ nghiệm thu. `.terraform.lock.hcl` tiếp tục khóa AWS provider 5.100.0.

## Kiểm tra cấu hình local, chưa triển khai AWS

Từ root repository, dùng Terraform đúng phiên bản rồi chạy:

```bash
cd Lab2/Task1/terraform/environments/dev
terraform init -backend=false -input=false -lockfile=readonly
terraform fmt -check -recursive ../..
terraform validate
terraform test
```

Tests hiện có dùng `mock_provider "aws"` và plan mô phỏng để kiểm tra input/defaults; không tạo tài nguyên thật và không yêu cầu session AWS. Lần init đầu cần tải provider nếu máy chưa có sẵn. Kết quả mock không xác nhận quyền IAM, Key Pair, state hoặc kết nối AWS thực tế.

Không sao chép `terraform.tfvars`, state/backup, `.terraform/`, credentials hoặc private key từ Lab 1 sang Lab 2. Khi cần triển khai thật, phải xác định state có thẩm quyền và cấu hình backend/auth trước; việc sao chép source không tự tiếp quản hạ tầng đã triển khai từ Lab 1.

Workflow GitHub Actions, Checkov Security Gate và Remote Backend sẽ được bổ sung ở các bước sau. Working directory của workflow sẽ là `Lab2/Task1/terraform/environments/dev`.
