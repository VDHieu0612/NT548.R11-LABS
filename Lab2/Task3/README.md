# Task 3: CI/CD Microservices với Jenkins, SonarQube & Container

- **Thành viên phụ trách:** Võ Duy Hiếu (Leader - 23520498) & Hoàng Lê Nhật Minh (23520926)
- **Nhánh Git:** `feature/lab2-member1-jenkins-cicd`

---

## 🛠️ Giai đoạn 1: Môi trường Local (Jenkins + SonarQube + Postgres)

Cụm dịch vụ CI/CD được đóng gói qua `docker-compose.yml`:
- **Jenkins:** Chạy tại port `8080`, mount Docker socket để build image trực tiếp từ pipeline.
- **SonarQube Community:** Chạy tại port `9000`, quét phân tích chất lượng mã nguồn tĩnh.
- **PostgreSQL 15:** Database backend cho SonarQube.
- **Mạng dùng chung:** `cicd-net` (giúp Jenkins kết nối tới SonarQube bằng tên miền `http://sonarqube:9000`).

### Lệnh khởi chạy:
```bash
# Di chuyển vào thư mục Task3
cd Lab2/Task3

# Khởi chạy các container ở chế độ nền
docker compose up -d

# Xem log các dịch vụ
docker compose logs -f
```

### Lấy mật khẩu khởi tạo của Jenkins:
```bash
docker exec -it jenkins-server cat /var/jenkins_home/secrets/initialAdminPassword
```

### Thông tin đăng nhập mặc định:
- **Jenkins:** `http://localhost:8080` (Dùng initialAdminPassword ở lệnh trên để kích hoạt).
- **SonarQube:** `http://localhost:9000` (Tài khoản mặc định: `admin` / `admin`).
