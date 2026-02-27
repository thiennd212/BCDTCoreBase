# Đề xuất: Test coverage đầy đủ cho B1 (Auth) – tránh phát sinh bug

**Mục đích:** Bổ sung test cases có cấu trúc (happy path + edge cases), cập nhật checklist cho AI, và (tùy chọn) tự động hóa bằng integration test để tránh regression khi sửa Auth.

**Trạng thái:** Đề xuất – chờ confirm trước khi triển khai.

---

## 1. Hiện trạng

### 1.1. Đã có

- **Checklist "Kiểm tra cho AI"** trong `B1_JWT.md` (mục 7.1): Build, API, Login (admin/Admin@123), Me, Refresh, Logout + Refresh (401), MCP PasswordHash, Postman JSON.
- **Postman collection** `docs/postman/BCDT-API.postman_collection.json`: Login, Me, Refresh, Logout, Health.
- **Rule** `always-verify-after-work`: Build khi cần, tự test trước khi báo xong, tắt process BCDT.Api nếu build bị lock.
- **B1 fix:** Logout + Me (401) đã triển khai; case này đã được test thủ công nhưng **chưa ghi rõ trong checklist 7.1**.

### 1.2. Thiếu / chưa đủ

| Hạng mục | Mô tả |
|----------|--------|
| **Edge cases** | Login sai mật khẩu → 401; Login thiếu username/password hoặc body rỗng → 400; Me không gửi Bearer → 401; Me token sai/hết hạn → 401; Refresh token sai/đã revoke → 401; Logout + Me (401) chưa nằm trong checklist 7.1. |
| **Test case có cấu trúc** | Chưa có bảng test case (ID, Mô tả, Input, Kỳ vọng, Cách chạy) để AI/người chạy theo từng scenario. |
| **Tự động hóa** | Chưa có project integration test (xUnit + WebApplicationFactory) cho Auth; regression phụ thuộc chạy tay hoặc AI chạy lệnh. |
| **Ràng buộc trong rule** | Chưa nêu rõ "khi sửa Auth phải chạy đủ test cases (happy + edge) trước khi báo xong". |

---

## 2. Đề xuất giải pháp

### 2.1. Tài liệu test cases (bắt buộc, ít công)

- **Tạo file** `docs/de_xuat_trien_khai/B1_TEST_CASES.md` (hoặc bổ sung section vào `B1_JWT.md`) gồm **bảng test case** đầy đủ:
  - **Happy path:** TC-01 Login thành công, TC-02 Me với token hợp lệ, TC-03 Refresh thành công, TC-04 Logout thành công, TC-05 Logout rồi Me → 401, TC-06 Logout rồi Refresh → 401.
  - **Edge / negative:** TC-07 Login sai mật khẩu → 401, TC-08 Login thiếu username/password (hoặc body rỗng) → 400, TC-09 Me không có header Authorization → 401, TC-10 Me token sai/giả mạo → 401, TC-11 Refresh token sai/đã revoke → 401.
  - Mỗi dòng: **ID, Mô tả, Request (method, URL, body/header), Kỳ vọng (status, body shape), Lệnh chạy (PowerShell/curl)** để AI hoặc người kiểm thử chạy nhanh.
- **Cập nhật mục 7.1 "Kiểm tra cho AI"** trong `B1_JWT.md`: thêm bước **Logout + Me → 401**; tham chiếu `B1_TEST_CASES.md` và yêu cầu "chạy đủ test cases (happy + edge) hoặc tối thiểu danh sách tối giản trong 7.1".

**Lợi ích:** AI và người test có danh sách rõ ràng; khi sửa Auth chỉ cần chạy theo bảng, tránh bỏ sót case.

---

### 2.2. Rule: bắt buộc chạy đủ test cases khi sửa Auth (bắt buộc, ít công)

- **Cập nhật rule** `always-verify-after-work.mdc` (hoặc `bcdt-testing.mdc`): khi task **liên quan Auth / B1** (sửa login, refresh, logout, JWT, middleware), AI phải **chạy đủ test cases** theo `docs/de_xuat_trien_khai/B1_TEST_CASES.md` (hoặc checklist tối thiểu trong B1_JWT.md mục 7.1) **trước khi** báo hoàn thành; báo Pass/Fail từng case.
- Có thể thêm vào checklist nhanh: *"Nếu sửa Auth: đã chạy đủ B1 test cases (happy + edge)?"*

**Lợi ích:** Tránh sửa code xong báo xong mà không kiểm tra edge case (vd quên Login sai mật khẩu, Me sau logout).

---

### 2.3. Integration test tự động (tùy chọn, công trung bình)

- **Tạo project** `BCDT.Api.IntegrationTests` (hoặc `BCDT.Tests`) dùng xUnit + `WebApplicationFactory<Program>` (ASP.NET Core).
- **Test Auth:** Gửi HTTP request tới `/api/v1/auth/login`, `/me`, `/refresh`, `/logout` với body/header đúng/sai; assert status code và (nếu cần) body (success, errors).
  - Ví dụ: `Login_Returns200_When_ValidCredentials`, `Login_Returns401_When_InvalidPassword`, `Me_Returns401_When_NoBearerToken`, `Me_Returns401_When_TokenRevokedByLogout`, `Refresh_Returns401_When_RefreshTokenRevoked`.
- **Chạy:** `dotnet test` trong CI hoặc trước khi commit; rule nhắc "khi sửa Auth chạy `dotnet test`".

**Lợi ích:** Regression tự động; không phụ thuộc AI chạy tay từng lệnh.

**Nhược điểm:** Cần cấu hình TestServer/DB (in-memory hoặc test DB), bảo trì khi đổi API.

---

## 3. Khuyến nghị triển khai

| Ưu tiên | Hạng mục | Công | Ghi chú |
|---------|----------|------|--------|
| **P1** | Tài liệu test cases (B1_TEST_CASES.md) + cập nhật 7.1 (thêm Logout+Me 401, tham chiếu test cases) | Ít | Làm trước; AI và người test có danh sách đầy đủ. |
| **P2** | Rule: khi sửa Auth phải chạy đủ B1 test cases trước khi báo xong | Ít | Gắn với P1. |
| **P3** | Integration test (BCDT.Api.IntegrationTests) cho Auth | Trung bình | Làm sau khi P1/P2 ổn; tùy nguồn lực. |

---

## 4. Cần confirm

- **P1 + P2:** Bạn có đồng ý triển khai **tài liệu test cases (B1_TEST_CASES.md)**, **cập nhật mục 7.1** (thêm Logout+Me 401, tham chiếu B1_TEST_CASES), và **rule bắt buộc chạy đủ test cases khi sửa Auth**? (Đề xuất: Có.)
- **P3:** Bạn có muốn thêm **project integration test** cho Auth ngay bây giờ, hay để giai đoạn sau? (Đề xuất: giai đoạn sau.)

Sau khi bạn confirm, sẽ triển khai theo đúng P1/P2 (và P3 nếu chọn).
