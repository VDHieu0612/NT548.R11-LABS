# Checkov baseline, hardening và ngoại lệ

Tool: Checkov **3.4.11**, nguồn pin `requirements-checkov.txt`. Chỉ scan Terraform của Task1 và supporting bootstrap; không scan hoặc sửa Lab1/Task2/Task3. Không cần Prisma/Bridgecrew account/API key cho gate này.

## 1. Findings trước khắc phục

| Phạm vi | Resources | Passed | Failed | Skipped | Parsing errors |
| --- | ---: | ---: | ---: | ---: | ---: |
| Workload tái sử dụng Lab1 | 15 | 21 | 18 | 0 | 0 |
| S3 bootstrap | 7 | 15 | 4 | 0 | 0 |

Đã sửa 6 failed check occurrences: CKV_AWS_79 và CKV_AWS_8 trên cả hai EC2, CKV_AWS_130 trên Public Subnet, CKV2_AWS_12 trên VPC/Default SG.

Các sửa đổi giữ Bastion có public IP, Private EC2 không public IP, hai SG chuyên dụng, NAT và routing. Root disk encryption có thể yêu cầu EC2 replacement trong plan thật; chưa có plan/runtime AWS xác nhận.

## 2. Ngoại lệ theo resource

Source có inline `#checkov:skip=...:EX-...` tại đúng resource. Manifest `security-exceptions.json` chứa reason và mitigation; gate từ chối skip ngoài danh sách hoặc comment không có mã EX. Không có global skip-check list.

| Mã | Check/resource | Lý do giữ và rủi ro còn lại |
| --- | --- | --- |
| EX-001, EX-005 | CKV_AWS_126 / Public và Private EC2 | Giữ basic monitoring, tránh tự bật detailed monitoring có thể tăng chi phí. Mức quan sát còn hạn chế |
| EX-002, EX-006 | CKV_AWS_135 / hai EC2 | Giữ t2.micro của Lab1, không bật EBS optimized không phù hợp loại máy. Cần xem lại khi đổi instance type |
| EX-003 | CKV_AWS_88 / Public EC2 | Public Bastion là yêu cầu kiến trúc. Giảm rủi ro bằng SSH IPv4 /32, IMDSv2 và encrypted root volume |
| EX-004, EX-007 | CKV2_AWS_41 / hai EC2 | Workload hiện không gọi AWS APIs; không tự tạo/attach IAM roles khi quyền Learner Lab chưa xác minh. Không đặt credentials trong EC2 |
| EX-008, EX-010 | CKV_AWS_382 / hai SG | Giữ outbound behavior Lab1 và kiểm thử NAT; all-egress vẫn là rủi ro. Production cần thu hẹp theo nhu cầu ứng dụng |
| EX-009, EX-011 | CKV2_AWS_5 / hai SG | Scanner 3.4.11 báo graph finding dù Root truyền SG outputs vào EC2 vpc_security_group_ids. HCL wiring/validate đã kiểm tra; phải xác minh attachments trên AWS khi nghiệm thu |
| EX-012 | CKV2_AWS_11 / VPC | Flow Logs cần thêm logging/IAM resources ngoài topology giữ lại. Chưa có network flow audit |
| EX-013 | CKV2_AWS_62 / state bucket | State không có event consumer; lockfile không cần event notification |
| EX-014 | CKV_AWS_18 / state bucket | Chưa tạo thêm bucket ghi access log. Có public access block/TLS/versioning, nhưng chưa có access audit đầy đủ |
| EX-015 | CKV_AWS_144 / state bucket | Replication thêm bucket/region/IAM ngoài phạm vi Lab. Có version history 90 ngày cho noncurrent objects, chưa có cross-region disaster recovery |
| EX-016 | CKV_AWS_145 / state bucket | AES256 SSE-S3 để không giả định quyền KMS. State vẫn encrypted, TLS-only và IAM scope hạn chế; cân nhắc KMS khi quyền/thiết kế cho phép |

Các ngoại lệ là lựa chọn kỹ thuật cho phạm vi Lab và được ghi công khai để review, không phải tất cả đều là yêu cầu bắt buộc của đề. Trước production phải đánh giá lại. Chúng không chứng minh runtime an toàn hoặc IAM đã cấu hình đúng.

Đối chiếu loại máy: bảng [AWS general-purpose instance specifications](https://docs.aws.amazon.com/ec2/latest/instancetypes/gp.html) nêu các loại không có trong bảng EBS-optimized không hỗ trợ tối ưu hóa này; t2.micro không nằm trong bảng đó. Ngoại lệ EX-002/006 giữ baseline, không tự chuyển instance type để đáp ứng policy.

## 3. Gate không chỉ dựa vào exit code

- Checkov phải trả 0, report JSON hợp lệ, failed=0 và parsing_errors=0.
- Resource count ít nhất 15 workload và 7 bootstrap; phải có checks cho các VPC/EC2/SG và S3 security resources quan trọng.
- Một số resource routing/NAT không có policy độc lập trong bộ checks hiện tại; resource_count bao phủ inventory, không tuyên bố mọi resource có check riêng.
- Suppressions được đối chiếu check ID/resource/mã EX/reason/mitigation; thêm một skip không đăng ký làm gate fail.
- Scanner/tool lỗi, thiếu module coverage hoặc report lỗi đều chặn deploy; CI không có continue-on-error và deploy needs=ci.

`config/checkov.tfvars.example` dùng documentation IP cho source scan, không phải SSH CIDR triển khai. Input thật được prepare_deployment.py và Terraform validation kiểm tra trước plan.

## 4. Giới hạn đã biết

Checkov source scan không xác nhận permissions, AMI/Key Pair tồn tại, SG attachment runtime, state migration, khóa đồng thời hay kết nối EC2. Python tests và mock plans chỉ xác minh logic/configuration local. Chưa chạy Actions thực tế hoặc kiểm thử AWS trong phiên này.

Workflow được pin SHA nhưng dependencies pip transitive chưa hash-lock hoàn toàn. Native S3 locking/concurrency giảm ghi đồng thời, không thay cho chọn đúng state/account. GitHub Environment phải được người dùng tạo và giới hạn main trước khi bật readiness.

## 5. Cách đọc bằng chứng

Reports local: `.artifacts/checkov-workload.json`, `checkov-bootstrap.json` và stderr tương ứng; không commit. Baseline trước sửa lưu riêng `checkov-before-*.json`. Negative fixture trong `.cache` mở SSH 0.0.0.0/0 phải làm gate fail CKV_AWS_24; chỉ fixture bị đổi, source chính giữ rule theo biến /32.

Kết quả cuối sau hardening/ngoại lệ và thử nghiệm regression được ghi trong IMPLEMENTATION.md và bộ nhớ PROGRESS.md. Các lệnh thật trên AWS còn ở USER_SETUP.md.
