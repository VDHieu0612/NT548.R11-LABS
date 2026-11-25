# Nhật ký triển khai và đối chiếu yêu cầu - Task 1

Ngày thực hiện: **2026-11-25, Asia/Saigon**. Mốc trước phiên này: commit `6edc243`, source Lab2 đã được tách khỏi Lab1, 6 mock tests workload đã pass. Phiên hiện tại chỉ thay đổi file bên trong `Lab2/Task1`; không sửa AGENTS.md root, Lab1, Task2/3 hoặc `.github/workflows`.

## 1. Yêu cầu nào là bắt buộc?

| Mã | Nguồn yêu cầu | Nội dung |
| --- | --- | --- |
| R1 | Đề Lab 2, trang 2, A.1 | Tái sử dụng hạ tầng Terraform đã làm ở Lab 1; Task 1 có trọng số 3 điểm |
| R2 | Đề Lab 2 + yêu cầu cụ thể của người dùng | Tự động hóa bằng GitHub Actions, gồm fmt/validate/plan/apply |
| R3 | Đề Lab 2, A.1 | Checkov kiểm tra compliance/security trước triển khai |
| R4 | Đề Lab 2, yêu cầu nộp bài | README hướng dẫn môi trường, chạy mã và kiểm tra kết quả |
| U1 | Yêu cầu tổ chức source mới nhất | Chỉ sửa trong Lab2/Task1, giữ Lab1 nguyên trạng và kiến trúc/module/resource addresses |
| U2 | Yêu cầu tài liệu trong phiên này | Ghi chi tiết từng bước, mục đích và yêu cầu được đáp ứng; để trống dữ liệu cần người dùng |

S3 Remote State, native locking, OIDC, concurrency, SHA-pinned actions và mock tests là **giải pháp kỹ thuật được chọn**, không phải tên công nghệ mà đề bắt buộc dùng cho từng chức năng. Báo cáo Word thuộc yêu cầu nộp toàn nhóm; phiên này cung cấp tài liệu Markdown để làm cơ sở cho báo cáo.

## 2. Tổng hợp các bước

| Bước trong kế hoạch | Việc đã làm | Mục đích/yêu cầu | Trạng thái thực tế |
| --- | --- | --- | --- |
| 1 | Đã có nhánh feature và commit chuẩn bị | Tách công việc Task1; U1 | Đã làm từ phiên trước; không commit/push phiên này |
| 2 | Learner Lab đã được người dùng xác nhận; lần STS trước trả ExpiredToken | Authentication/quyền cần trước AWS thật | Người dùng dời lại; phiên này không gọi AWS |
| 3 | Source/version/validation/dependency/outputs đã chuẩn hóa; tiếp tục hardening trong bản Lab2 | R1, R2, R3, U1 | Đã sửa và kiểm tra local |
| 4 | Cài Checkov 3.4.11, scan baseline, khắc phục và đăng ký ngoại lệ, viết gate | R3 | Có kết quả scanner thật trên source local |
| 5 | Viết bootstrap S3, backend partial config, policy ví dụ và state guard | Hỗ trợ R2, giữ state dùng chung/locking | Code và mock tests có; bucket/migration thật chưa làm |
| 6 | Viết job CI không credentials và script kiểm tra local | R2, R3 | Workflow đã lint; chưa được GitHub nhận vì chưa chép vào `.github/workflows` |
| 7 | Viết trusted plan/apply, session/OIDC, concurrency, saved-plan cleanup | R2, R3 | Đã chuẩn bị code; chưa chạy trên Actions/AWS |
| 8 | Viết README, nhật ký này, hướng dẫn điền cấu hình và security report | R4, U2 | Có file bàn giao; các ô cần người dùng còn trống |
| 9 | Local Terraform/Python tests, Checkov, workflow lint và negative test | Kiểm tra chất lượng trước triển khai | Kiểm chứng local; chưa có minh chứng deployment/SSH/NAT thật |

## 3. Bước 3-4: source Terraform và Checkov

### Baseline và lựa chọn xử lý

Checkov 3.4.11 quét workload gốc: **21 passed, 18 failed, 0 skipped**, 15 resources, 0 parsing errors. Bootstrap S3 mới: **15 passed, 4 failed, 0 skipped**, 7 resources. Các baseline JSON chỉ chứa source/mock inputs, lưu local trong `.artifacts`.

Các thay đổi khắc phục ở bản Lab2:

| File | Trước/sau | Mục đích và nguyên lý |
| --- | --- | --- |
| `terraform/modules/ec2/main.tf` | Chưa khai báo IMDSv2/encryption -> cả hai EC2 có `http_tokens=required`, `root_block_device.encrypted=true` | Khắc phục CKV_AWS_79/8; không đổi subnet, SG, AMI selection, instance type hoặc Key Pair |
| `terraform/modules/vpc/main.tf` | Public Subnet tự cấp public IP -> mặc định tắt | Khắc phục CKV_AWS_130. Public EC2 vẫn `associate_public_ip_address=true`; public routing và NAT EIP giữ nguyên |
| Cùng file VPC | Default SG self-ingress/all-egress -> ingress/egress rỗng | Khắc phục CKV2_AWS_12; hai EC2 vẫn dùng SG riêng, giữ resource Default SG theo đề Lab1 |
| Các resource cần ngoại lệ | Bổ sung inline checkov skip có mã EX và giải trình | Giữ Bastion/public IP, baseline t2.micro, outbound behavior và không thêm IAM/logging/replication chỉ để scanner xanh |

Root disk encryption có thể làm plan yêu cầu thay EC2 đang tồn tại. Mock tests không xác định được replacement trên account thật; cần xem plan thật trước apply. Không thay thế hoặc triển khai EC2 trong phiên này.

### Gate hoạt động thế nào?

`scripts/security_gate.py` chạy `python -X utf8 -m checkov.main` theo version đã pin, đọc `.checkov.yaml`, scan workload/bootstrap và xuất JSON. Nó trả nonzero nếu scanner lỗi, còn failed checks, parsing errors, mất coverage hoặc suppression không có cặp check ID/resource/reason/mitigation trong `security-exceptions.json`.

Gate yêu cầu workload >=15 và bootstrap >=7 resources, cùng bằng chứng checks cho VPC/EC2/SG và bucket/public-access-block. Một số NAT/routing/versioning resources được tính vào resource_count nhưng không có standalone check records; không tự tạo ra check giả cho chúng.

Không dùng soft-fail, continue-on-error hoặc skip toàn framework. Các biến scan dùng địa chỉ tài liệu 192.0.2.10/32; deployment lấy giá trị thật từ cấu hình đã validate. Xem SECURITY.md để biết rõ 12 exceptions workload và 4 exceptions bootstrap.

## 4. Bước 5: state/backend và bootstrap

- `terraform/environments/dev/backend.tf`: S3 backend với encryption và native `use_lockfile=true`; bucket/key/region được điền qua backend.hcl. Terraform minimum được tăng lên >=1.10; CLI chọn 1.17.1 và provider 5.100.0 giữ nguyên.
- `bootstrap/`: Root riêng với 7 managed resources cho bucket, Block Public Access, ownership, versioning, AES256, TLS-only bucket policy và lifecycle. Root riêng tránh vòng lặp bucket chưa tồn tại nhưng backend cần chính bucket đó.
- `prevent_destroy=true` và force_destroy=false bảo vệ bucket; lifecycle chỉ xóa noncurrent versions sau 90 ngày và abort multipart upload sau 7 ngày, không expire current state.
- `config/backend.hcl.example`: bucket để trống; không chứa credentials. `config/iam/backend-policy.json.example`: scope state object và lock object, chỉ cho DeleteObject trên `.tflock`.
- `scripts/check_state.py`: `existing` yêu cầu đúng 15 resource addresses trước plan; `new` chấp nhận state rỗng hoặc state đã có đúng 15 resources của lần deploy trước. State sai/thiếu/unrelated resource bị chặn. Đây là kiểm tra cấu trúc, không thay thế kiểm tra account/region/resource identity.

Chưa tạo bucket, cấp IAM policy hoặc di chuyển state của Lab1. Source Lab2 chưa nhận quyền quản lý hạ tầng cũ chỉ vì source/resource addresses giống nhau.

## 5. Bước 6-7: workflow chuẩn bị sẵn

File `workflows/lab2-task1.yml` được để trong Task1 để tuân thủ U1. GitHub yêu cầu người dùng chép file sang `.github/workflows/lab2-task1.yml`; đến lúc đó mới có workflow hoạt động.

Job `ci` chạy trên PR/main/feature/manual: setup version -> cài pinned Checkov -> Python guard tests -> fmt/init backend=false/validate/mock tests -> Checkov. Không tham chiếu Secrets hay xin OIDC trong job này. Checkout tắt persist-credentials.

Job `deploy` có needs=ci, chỉ main, TF_DEPLOYMENT_READY=true, Environment `lab2-task1-dev` và trigger hợp lệ. Inputs được kiểm tra trước auth; session mode yêu cầu cả 3 Secrets, OIDC mode yêu cầu role trong account đã điền. Action kiểm tra allowed-account-ids và mask account ID. IAM/OIDC thực tế chưa xác minh.

Sau auth: init backend -> state guard -> validate -> saved plan -> optional apply cùng plan trong cùng job/run. Không upload binary plan hoặc state để dùng lại giữa các run. Cleanup xóa file plan/backend config của run. Concurrency theo bucket/key không hủy deployment đang chạy; S3 lock xử lý writers bên ngoài workflow.

Manual operation=plan chỉ plan; operation=apply áp dụng saved plan. Push main chỉ auto-apply khi TF_AUTO_APPLY=true. Hai readiness flags mặc định false để các ô trống không dẫn tới deployment ngoài ý muốn.

Các action được kiểm tra tag/commit từ repository chính thức và pin SHA: checkout v7.0.1, setup-python v7.1.0, setup-terraform v4.0.1, configure-aws-credentials v6.3.0. actionlint local dùng v1.7.12, binary kiểm tra checksum release. Version direct được pin; dependencies transitive của pip chưa được khóa toàn bộ bằng hash.

## 6. Bước 8-9: tài liệu và kiểm chứng

- `README.md`: điểm bắt đầu, source tree, lệnh local và trạng thái chưa kích hoạt workflow.
- `USER_SETUP.md`: các ô cần điền, lựa chọn state, thao tác AWS/GitHub thật và cách nghiệm thu.
- `SECURITY.md` + manifest: findings, ngoại lệ theo resource, rủi ro và giới hạn.
- `tests/test_guards.py`: 24 Python tests cho input/state/fail-closed.
- Workload native tests: 6 mock plans. Bootstrap: 3 mock plans. Không tạo tài nguyên thật.
- Negative fixture chỉ nằm trong `.cache`: đổi SSH ingress thành 0.0.0.0/0; gate phải trả 1 và report có CKV_AWS_24. Source chính không bị mở SSH.
- actionlint kiểm tra syntax, expressions và action inputs của workflow template; không chạy shellcheck/pyflakes trong lần lint local.

Kết quả cuối phiên đã kiểm chứng local trên Windows/Python 3.10/Terraform 1.17.1:

| Kiểm tra | Kết quả |
| --- | --- |
| verify_local.py (luồng tổng hợp) | Exit 0 sau khi sửa kiểm tra coverage cho resources không có standalone policies |
| fmt/init backend=false/validate | Pass cho cả workload và bootstrap, provider lockfile readonly |
| Native mock plans | 6 workload + 3 bootstrap pass, không có AWS resources thật |
| Python guards | 24 tests pass |
| Checkov workload | 27 passed / 0 failed / 12 skipped, 15 resources, 0 parsing errors |
| Checkov bootstrap | 15 passed / 0 failed / 4 skipped, 7 resources, 0 parsing errors |
| Negative SSH fixture | Gate exit 1 như kỳ vọng; CKV_AWS_24 được phát hiện, source chính không bị đổi |
| actionlint 1.7.12 | Pass; shellcheck/pyflakes không được chạy trong lần lint này |
| Exception manifest / IAM JSON | Đủ 16 inline markers khớp manifest; hai policy examples parse JSON thành công |
| Phạm vi file | Checksum 42 file ngoài Task1 (gồm AGENTS.md root) giữ nguyên; mọi visible changes ở Task1, không staged/new commit |

Lần scan đầu trên Windows gặp cp1258/UnicodeDecodeError, không tạo được report hợp lệ và không được coi là security pass. Runner hiện dùng Python -X utf8. Khi phát triển coverage guard, đã điều chỉnh yêu cầu check records cho NAT/versioning vì scanner không cung cấp standalone records cho mọi resource; inventory vẫn được kiểm tra qua resource_count. Các lần kiểm tra cuối sau sửa đều đã chạy lại và đạt.

Chưa có kết quả GitHub runner/Linux hoặc AWS runtime. Các việc cần người dùng không được đánh dấu hoàn tất. Không chạy apply/destroy, bootstrap/migration thật hoặc thay đổi account/GitHub settings; không commit/push phiên này.

## 7. Nguồn kỹ thuật đã đối chiếu

- [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3): partial config, encryption, native locking, permissions state/lock.
- [Terraform provider mocking](https://developer.hashicorp.com/terraform/language/tests/mocking): kiểm tra không tạo AWS resources.
- [Checkov CLI](https://www.checkov.io/2.Basics/CLI%20Command%20Reference.html), [resource suppressions](https://www.checkov.io/2.Basics/Suppressing%20and%20Skipping%20Policies.html): report và ngoại lệ có lý do.
- [GitHub workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax), [OIDC in AWS](https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws): vị trí workflow, needs/if/concurrency và trust boundary.
- [Checkov package](https://pypi.org/project/checkov/3.4.11/), [actionlint release](https://github.com/rhysd/actionlint/releases/tag/v1.7.12): versions công cụ đã dùng.
