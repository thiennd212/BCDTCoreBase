# Cách AI tự kiểm tra sau khi làm việc

Tài liệu hướng dẫn **AI** tự chạy bước kiểm tra sau khi hoàn thành một task và **báo kết quả (Pass/Fail)**.

---

## Nguyên tắc

1. **Sau khi hoàn thành task**, AI đọc mục **"Kiểm tra cho AI"** (hoặc tương đương) trong file đề xuất tương ứng (vd `docs/de_xuat_trien_khai/B1_JWT.md` cho B1).
2. **Chạy lần lượt** các lệnh/query trong mục đó (build, gọi API, MCP execute_sql nếu có).
3. **Báo kết quả** cho user: liệt kê từng bước kèm **Pass** hoặc **Fail** (và nội dung lỗi nếu có). Ví dụ: *"1. Build: Pass. 2. Login: Pass. 3. Me: Pass. …"*

---

## File đề xuất có mục "Kiểm tra cho AI"

| File | Task | Nội dung kiểm tra |
|------|------|-------------------|
| [de_xuat_trien_khai/B1_JWT.md](de_xuat_trien_khai/B1_JWT.md) | B1 JWT | Build, Login, Me, Refresh, Logout, MCP kiểm tra PasswordHash, **tạo/cập nhật Postman collection** (`docs/postman/`) |
| [de_xuat_trien_khai/B6_FRONTEND.md](de_xuat_trien_khai/B6_FRONTEND.md) | B6 Frontend | Build, API/FE chạy, checklist 7.1. **Tự test UI (FE đã ghép BE):** [B6_AI_TU_TEST_UI.md](de_xuat_trien_khai/B6_AI_TU_TEST_UI.md) – chạy `npm run test:e2e` trong `src/bcdt-web` (Playwright E2E) hoặc dùng MCP browser theo từng bước; báo Pass/Fail từng test/bước. |

*Các file đề xuất khác (B2, B3, …) khi có sẽ bổ sung mục "Kiểm tra cho AI" tương tự.*

## Postman collection (kiểm thử thủ công)

Khi task **liên quan API** (vd B1, thêm endpoint mới), AI nên **tạo hoặc cập nhật** Postman collection trong `docs/postman/` (chi tiết trong rule [always-verify-after-work](.cursor/rules/always-verify-after-work.mdc), mục "Postman collection"). Collection dùng biến `baseUrl`, `accessToken`, `refreshToken` và script Tests trong Login để lưu token, giúp người kiểm thử chạy thủ công mà không cần copy token tay.

---

## Nếu file đề xuất không có mục "Kiểm tra cho AI"

Áp dụng **checklist trong rule** [always-verify-after-work](.cursor/rules/always-verify-after-work.mdc):

- Chạy **build** (vd `dotnet build ...`).
- Với API: gọi endpoint liên quan (curl / Invoke-RestMethod) và kiểm tra status + response.
- Với DB: dùng MCP mssql (nếu có) chạy SELECT mẫu và đối chiếu.
- Báo ngắn gọn: Pass/Fail và lỗi (nếu có).

---

## Tóm tắt cho AI

- **Khi nào:** Sau khi hoàn thành một công việc (triển khai B1, chạy script, …).
- **Làm gì:** Mở file đề xuất tương ứng → tìm mục **"Kiểm tra cho AI"** → chạy lần lượt lệnh/query → **nếu liên quan API: tạo/cập nhật Postman collection** trong `docs/postman/` → ghi nhận Pass/Fail.
- **Báo cáo:** Trả lời user với danh sách bước và kết quả (Pass/Fail, lỗi cụ thể nếu Fail; nếu đã cập nhật Postman thì ghi rõ file/đường dẫn).
