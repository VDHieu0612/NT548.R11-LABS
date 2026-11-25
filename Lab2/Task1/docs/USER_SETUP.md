# Các phần người dùng cần tự hoàn tất

Tài liệu này mô tả thao tác tương lai. Agent chưa chạy các lệnh AWS/apply/migration hoặc sửa `.github/workflows`. Giữ TF_DEPLOYMENT_READY=false và TF_AUTO_APPLY=false đến khi hoàn tất state/auth review.

## 1. Những ô cần điền

File tham khảo: `../config/github-variables.example.env`. Đây là danh sách để nhập vào GitHub Settings, không phải file chứa Secrets để commit.

| Repository Variable | Mặc định/giá trị cần điền | Ý nghĩa |
| --- | --- | --- |
| AWS_ACCOUNT_ID | **Trống: tự điền 12 chữ số** | Action chỉ chấp nhận identity thuộc account này |
| AWS_REGION | us-east-1 | Region workload; phải được Learner Lab cho phép |
| AWS_AUTH_MODE | session | Dùng credentials tạm thời của Lab; đổi oidc chỉ khi cấu hình IAM thành công |
| AWS_ROLE_ARN | **Trống** | Chỉ bắt buộc khi chọn oidc |
| TF_AVAILABILITY_ZONE | us-east-1a | AZ phải thuộc AWS_REGION và khả dụng thật |
| TF_ALLOWED_SSH_CIDR | **Trống: Public IPv4 của bạn/32** | Whitelist SSH vào Bastion, không dùng IP GitHub runner |
| TF_PROJECT_NAME | NT548-Lab01 | Đổi tên riêng nếu tạo môi trường mới |
| TF_INSTANCE_TYPE | t2.micro | Giữ baseline hoặc loại được Lab cho phép |
| TF_KEY_NAME | vockey | Key Pair phải có sẵn ở đúng region |
| TF_STATE_BUCKET | **Trống: bucket đã bootstrap/xác minh** | Bucket private lưu state |
| TF_STATE_KEY | lab2/task1/dev/terraform.tfstate | Key riêng cho môi trường, dùng nhất quán |
| TF_STATE_REGION | us-east-1 | Region của bucket |
| TF_STATE_STRATEGY | **Trống: chọn existing hoặc new** | Tiếp quản state cũ hoặc môi trường mới |
| TF_DEPLOYMENT_READY | false | Chỉ chuyển true sau các bước bên dưới |
| TF_AUTO_APPLY | false | true cho phép push main auto-apply sau CI; có thể giữ false và dùng manual apply |

Các biến điều khiển job readiness phải đặt ở **Repository Variables**, vì job-level if được đánh giá trước khi load Environment settings. Không đặt giá trị mâu thuẫn cùng tên ở Environment.

Session mode cần **Environment Secrets trong `lab2-task1-dev`**: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN. Nhập trực tiếp tại GitHub Settings -> Environments -> lab2-task1-dev. Giới hạn Environment chỉ cho main trước khi thêm Secrets để CI/feature không nhận credentials. Không dán vào chat, source, tfvars hoặc báo cáo. Các ô credentials trong ví dụ được ghi theo tên, không có giá trị.

## 2. Xác minh Learner Lab khi sẵn sàng

Start Lab, lấy credentials của cùng phiên tại AWS Details và cập nhật profile default trên máy. Lần kiểm tra trước từng trả ExpiredToken; kết nối Lab1 cũ không chứng minh phiên mới còn hạn.

```powershell
aws sts get-caller-identity --profile default --region us-east-1
aws ec2 describe-key-pairs --profile default --region us-east-1 --key-names vockey --query 'KeyPairs[].KeyName' --output text
aws ec2 describe-availability-zones --profile default --region us-east-1 --filters Name=zone-name,Values=us-east-1a --query 'AvailabilityZones[].State' --output text
```

STS thành công chỉ xác nhận identity, không xác nhận đủ quyền. Cần EC2/VPC/SG/NAT/EIP CRUD, Describe/Tags và quyền S3 state/lock. Bootstrap cần quyền quản lý bucket/versioning/encryption/public-access-block/ownership/policy/lifecycle. Nếu account không cho phép một thao tác, ghi nhận AccessDenied cụ thể rồi điều chỉnh quyền/phương án; không tự giả định quyền IAM vì đây là Learner Lab.

OIDC là tùy chọn: chỉ dùng nếu được phép tạo/cấu hình identity provider và role. `config/iam/oidc-trust.json.example` còn placeholders; xác minh subject thật của repository/Environment theo GitHub docs, không copy subject mẫu. Role cần quyền backend và workload phù hợp; policy backend ví dụ không cấp đủ quyền EC2 để deploy.

## 3. Bootstrap bucket state (chỉ khi chưa có bucket phù hợp)

1. Vào `Lab2/Task1/bootstrap`, tạo terraform.tfvars từ ví dụ, điền tên bucket global unique và region. Không chứa credentials.
2. Chạy init/validate/plan, kiểm tra chỉ có 7 supporting resources S3; apply khi đã xem plan và quyền/chi phí phù hợp.

```powershell
cd Lab2/Task1/bootstrap
Copy-Item terraform.tfvars.example terraform.tfvars
# Sua state_bucket_name truoc cac lenh ben duoi.
terraform init -input=false -lockfile=readonly
terraform validate
terraform plan -out=bootstrap.tfplan
terraform apply bootstrap.tfplan
terraform output -raw state_bucket_name
```

Đây là local backend riêng của bootstrap; giữ state/bootstrap.tfplan ngoài Git và bảo quản backup an toàn. Bucket hiện mã hóa AES256, TLS-only, Block Public Access, versioning; giữ noncurrent versions 90 ngày. Không bật cross-region replication/logging/KMS/event notifications trong cấu hình tối thiểu; SECURITY.md ghi rõ ngoại lệ. Bucket có prevent_destroy và force_destroy=false; không dùng destroy để dọn bucket state một cách tự động.

Nếu đã có bucket, không apply bootstrap lên tên đó mà chưa xác minh ownership/import. Điền bucket đã xác minh vào config thay vì tạo trùng.

## 4. Chọn state strategy trước deployment

### existing: tiếp tục quản lý hạ tầng Lab1

- Xác minh account/region và state có thẩm quyền; dừng các tiến trình Terraform khác trong lúc migration.
- Backup state an toàn. **Agent chưa copy state**. Nếu chọn tiếp quản, tự sao chép đúng state từ Lab1 sang `Lab2/Task1/terraform/environments/dev/terraform.tfstate`; không commit hoặc gửi nội dung state.
- Tạo backend.hcl từ `config/backend.hcl.example`, điền bucket/key/region.
- Tại Root Lab2, dùng `terraform init -migrate-state -backend-config=backend.hcl` và kiểm tra cẩn thận trước khi xác nhận migration. Không dùng -reconfigure để thay cho migration rồi bỏ quên local state.
- Sau migration, chạy state list; phải có đúng 15 managed resource addresses theo scripts/check_state.py (data source AMI không tính vào 15). Xác minh resource IDs/account thực tế, không chỉ số lượng.
- Plan thật có thể yêu cầu replacement do encryption hoặc AMI most_recent; xem kỹ trước apply. Không chạy lại Lab1 để quản lý cùng tài nguyên sau khi đã chuyển quyền quản lý state sang Lab2.

### new: môi trường Lab2 mới

- Chọn key state riêng và tên project riêng, chấp nhận rằng apply tạo thêm workload và phát sinh chi phí riêng.
- Không copy state Lab1. Init backend Lab2 bằng backend.hcl đã điền. Đặt TF_STATE_STRATEGY=new rõ ràng.
- State rỗng được phép chỉ theo lựa chọn này. Những lần update tiếp theo phải có đúng tập 15 resource addresses; state không liên quan vẫn bị chặn.

Sao chép source không tạo resource mới trong phiên chuẩn bị, nhưng apply từ state rỗng sẽ tạo tài nguyên; phải chọn strategy trước khi bật readiness.

## 5. Kích hoạt GitHub Actions (thao tác ngoài phạm vi agent được sửa)

Người dùng tự thực hiện từ root repository khi đồng ý thêm workflow vào vị trí GitHub yêu cầu:

```powershell
New-Item -ItemType Directory -Path .github/workflows -Force
Copy-Item Lab2/Task1/workflows/lab2-task1.yml .github/workflows/lab2-task1.yml
```

Sau đó review và commit/push theo quy trình nhóm. Không stage AGENTS.md hoặc .context; không force-add các file bị ignore. Chỉ có file trong Task1/workflows sẽ không chạy trên GitHub.

Trong Settings -> Environments, tạo `lab2-task1-dev`, giới hạn deployment branch main; thêm required reviewer nếu gói/quyền GitHub cho phép. Tạo Variables/Secrets ở bảng trên, xác minh session còn hiệu lực, state strategy và backend. Sau đó mới đặt TF_DEPLOYMENT_READY=true.

Merge workflow/source đã review vào main. PR/feature chỉ chạy CI. Trong Actions -> Lab2 Task1 Terraform -> Run workflow trên main:

- operation=check: CI không credentials.
- operation=plan: CI, auth/backend/state guard và saved plan; chưa apply.
- operation=apply: CI, tạo plan mới của chính run đó rồi apply saved plan trong cùng job. Plan từ run operation=plan trước đó không được đem dùng chéo run.

Có thể giữ TF_AUTO_APPLY=false để dùng manual apply. Nếu bật true, push main chạm Task1/workflow có thể triển khai sau khi CI và Environment rules cho phép.

## 6. Kiểm tra kết quả thật và minh chứng nộp bài

1. Lưu ảnh Actions của các bước fmt/validate/tests/Checkov/plan/apply; che account/ARN/IP nếu chia sẻ công khai.
2. Kiểm tra Root Outputs: vpc_id, public/private_subnet_id, nat_gateway_id, nat_eip, route table IDs và hai EC2 IPs.
3. AWS Console/CLI: VPC/Subnet/IGW/NAT/Route Tables/SG attachments đúng thiết kế; public SSH /32, private ingress từ Public SG, private không public IP, Default SG đóng.
4. Kiểm tra hai EC2 IMDSv2 required và encrypted root volumes. Basic monitoring và EBS optimization vẫn theo ngoại lệ đã ghi.
5. SSH Public EC2, SSH/ICMP Private EC2 qua Bastion, kiểm tra private outbound có IP bằng NAT EIP. Script Lab1 có thể chạy thủ công ở chế độ đọc source; xem từng test và SKIPPED, không chỉ exit code.
6. Xác minh state xuất hiện trong bucket, versioning/encryption/public access/TLS policy; xác minh lock contention bằng quy trình kiểm thử có kiểm soát trước khi cho nhiều người deploy.

Agent chưa có các minh chứng này. Không đưa raw state, plan binary/JSON, private key hoặc credentials vào báo cáo/repository. Muốn dọn workload sau nghiệm thu, xác minh đúng account/backend/state rồi thực hiện cleanup thủ công theo quyền riêng; pipeline không cung cấp destroy tự động.

## 7. Troubleshooting

| Hiện tượng | Hướng xử lý |
| --- | --- |
| Không thấy workflow trong Actions | Chép file vào .github/workflows và push; kiểm tra default/main branch |
| Deploy bị skipped | Kiểm tra main/ref, TF_DEPLOYMENT_READY repository var, operation và TF_AUTO_APPLY |
| ExpiredToken | Start/refresh Lab, cập nhật đủ 3 Secrets cùng phiên |
| Prepare deployment fail | Điền các ô trống, /32, Region/AZ, account ID và state strategy đúng |
| State guard fail | Dừng trước plan; kiểm tra key/state/migration, không đổi existing thành new chỉ để vượt lỗi |
| Security gate fail | Đọc .artifacts/checkov-*.json và stderr; sửa finding/parser/coverage, không bật soft-fail |
| State lock contention | Đợi tiến trình hợp lệ kết thúc; không force-unlock khi chưa xác minh owner/run |
| Backend AccessDenied | Kiểm tra bucket/key/region và quyền trên state cùng .tflock; policy ví dụ chỉ là backend scope |
