# Lab 2 - Task 1: Terraform, GitHub Actions và Checkov

**Phụ trách:** Cam Hồng Mạnh (23520914). **Nhánh:** `feature/lab2-member2-github-actions`.

Task 1 tái sử dụng kiến trúc/module Lab 1 qua source chính `Lab2/Task1/terraform`. Lab 1 được giữ nguyên. Workload vẫn có 15 resources: VPC, Public/Private Subnet, IGW, NAT/EIP, Route Tables, Default SG, hai EC2 SG và hai EC2 theo Bastion pattern.

## Trạng thái bàn giao

- Đã chuẩn bị Terraform, Checkov Security Gate, S3 bootstrap/backend, workflow CI/plan/apply và tests local.
- Workflow nằm tại **`workflows/lab2-task1.yml`**. GitHub chỉ nhận workflow ở `.github/workflows`; file hiện tại **chưa được kích hoạt** vì người dùng chỉ cho sửa `Lab2/Task1`.
- Chưa đăng nhập/cấp quyền AWS, tạo bucket, migrate state, chạy plan/apply thật, chạy GitHub Actions, commit hoặc push các thay đổi mới của phiên này.
- Các ô cần người dùng điền được để trống trong `config/github-variables.example.env`, `config/backend.hcl.example` và `bootstrap/terraform.tfvars.example`. Deployment mặc định tắt.

## Đọc tài liệu theo mục đích

| Tài liệu | Nội dung |
| --- | --- |
| [IMPLEMENTATION.md](docs/IMPLEMENTATION.md) | Từng bước đã làm, file nào thay đổi, mục đích, đáp ứng yêu cầu nào, bằng chứng và giới hạn kiểm chứng |
| [USER_SETUP.md](docs/USER_SETUP.md) | Các việc còn cần bạn: credentials, điền cấu hình, bootstrap/migration, GitHub Settings và kích hoạt workflow |
| [SECURITY.md](docs/SECURITY.md) | Findings gốc, phần đã sửa, 16 ngoại lệ theo resource và rủi ro còn lại |
| [security-exceptions.json](security-exceptions.json) | Danh sách ngoại lệ được gate kiểm tra bằng máy; không có skip toàn cục |

## Cấu trúc chính

```text
Task1/
├── terraform/                 # Workload tái sử dụng từ Lab 1
│   ├── environments/dev/      # Root Module, backend S3, variables, outputs, mock tests
│   └── modules/               # vpc, nat, security, ec2
├── bootstrap/                 # Root riêng tạo bucket state, chưa apply
├── workflows/lab2-task1.yml   # Workflow hoàn chỉnh chờ chép vào vị trí GitHub yêu cầu
├── scripts/                   # Local checks, security gate, input/state guards
├── tests/                     # Python tests cho fail-closed/input/state
├── config/                    # Ví dụ cấu hình và IAM policy, không chứa credentials
├── docs/                      # Tài liệu bàn giao chi tiết
├── requirements-checkov.txt   # Checkov 3.4.11
└── .gitignore                 # Loại tools/cache/reports/state/credentials/bộ nhớ
```

## Kiểm tra local không cần AWS

Cần Terraform 1.17.1 theo `terraform/environments/dev/.terraform-version` và Python >= 3.10. Ví dụ PowerShell từ root repository:

```powershell
python -m venv Lab2/Task1/.tools/checkov
& Lab2/Task1/.tools/checkov/Scripts/python.exe -m pip install -r Lab2/Task1/requirements-checkov.txt
& Lab2/Task1/.tools/checkov/Scripts/python.exe -X utf8 -m unittest discover -s Lab2/Task1/tests -v
& Lab2/Task1/.tools/checkov/Scripts/python.exe -X utf8 Lab2/Task1/scripts/verify_local.py
```

Linux/macOS dùng `.tools/checkov/bin/python` thay cho `Scripts/python.exe`. Nếu đã có provider mirror local, thêm `--plugin-dir <đường-dẫn-provider-mirror>` vào lệnh cuối để không tải lại provider.

`verify_local.py` kiểm tra formatting source thật, tạo bản sao **source-only** tạm trong `.cache`, chạy `init -backend=false -lockfile=readonly`, `validate`, mock tests cho workload/bootstrap và Checkov. Script bỏ AWS credentials/TF_VAR từ environment của tiến trình kiểm tra và không mang theo state/tfvars local. `.cache` không phải source chính. `.context` chỉ giữ bộ nhớ agent và bị ignore.

Chỉ chạy gate:

```powershell
& Lab2/Task1/.tools/checkov/Scripts/python.exe -X utf8 Lab2/Task1/scripts/security_gate.py
```

Checkov quét cả workload (15 resources) và bootstrap (7 resources). Gate chặn finding chưa xử lý, lỗi tool/parser, thiếu coverage hoặc suppression không có trong manifest. Reports JSON nằm tại `.artifacts`, không commit. Passing có ngoại lệ được ghi rõ, không có nghĩa là mọi policy đều đạt.

## Nguyên lý pipeline đã chuẩn bị

```text
Push/PR/manual check -> fmt -> init backend=false -> validate -> mock tests -> Checkov
                                                                          |
                      main + deployment ready + trigger hợp lệ <-----------+
                                      |
                      kiểm tra input -> AWS auth -> S3 backend/locking
                                      |
                           kiểm tra state -> plan lưu trong run
                                      |
                       apply đúng saved plan nếu được yêu cầu
```

PR/feature branch chỉ chạy CI không credentials. Plan/apply thật chỉ từ `main`, sau CI thành công và `TF_DEPLOYMENT_READY=true`; apply do manual operation=apply hoặc push main khi `TF_AUTO_APPLY=true`. Plan và apply cùng job/run; plan không được upload thành artifact dùng chung. Concurrency không hủy apply đang chạy; S3 lockfile bảo vệ state.

Xem [USER_SETUP.md](docs/USER_SETUP.md) trước khi bật deployment. Source copy không tự tiếp quản tài nguyên Lab 1: phải chọn rõ `existing` hoặc `new` và xác minh state. Không chạy apply từ state trống nếu muốn tiếp tục quản lý hạ tầng cũ.
