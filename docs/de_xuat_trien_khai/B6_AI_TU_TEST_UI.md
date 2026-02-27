# Cách AI tự test UI khi FE đã ghép BE

Tài liệu hướng dẫn **AI** tự kiểm thử giao diện (login, trang list, form CRUD) khi frontend đã kết nối backend. Có **hai cách**; ưu tiên **Cách 1 (Playwright)** để có kết quả Pass/Fail tự động.

**Điều kiện:** API BCDT chạy tại `http://localhost:5080`, frontend chạy tại `http://localhost:5173` (hoặc port Vite báo). Seed có user `admin` / `Admin@123`.

---

## Cách 1: Chạy E2E với Playwright (khuyến nghị)

Playwright được cấu hình trong `src/bcdt-web` (file `playwright.config.ts`, thư mục `e2e/`). Nếu chưa cài: `cd src/bcdt-web && npm i -D @playwright/test && npx playwright install chromium`. Thêm script `"test:e2e": "playwright test"` vào `package.json` nếu chưa có. AI chạy một lệnh để tự test UI và báo Pass/Fail.

### Chuẩn bị

1. **API đang chạy:** `dotnet run --project src/BCDT.Api --launch-profile http`
2. **Frontend đang chạy:** `npm run dev` trong `src/bcdt-web` (hoặc dùng `webServer` trong Playwright config nếu đã bật)

### Lệnh AI cần chạy

```bash
cd src/bcdt-web
npm run test:e2e
```

- **Pass:** Tất cả test (login, redirect, list đơn vị, list user, protected route) đều xanh.
- **Fail:** AI đọc output lỗi, báo từng test Fail và nguyên nhân (vd. selector không tìm thấy, API 500, timeout).

### Nội dung test E2E (đã viết trong `e2e/`)

| Test | Mô tả |
|------|--------|
| Login page | GET /login, có form username/password, nút đăng nhập |
| Login thành công | Fill admin / Admin@123, submit → redirect /organizations (hoặc /) |
| Trang đơn vị | Có bảng, nút "Thêm đơn vị", không 401 |
| Trang user | Có bảng, nút "Thêm người dùng", không 401 |
| Protected route | Chưa login vào /organizations → redirect /login |
| Logout | Sau login, bấm Đăng xuất → redirect /login |

AI **bắt buộc** chạy `npm run test:e2e` khi được giao "tự test UI B6" hoặc "chạy checklist 7.1" và báo **Pass** hoặc **Fail** từng test.

---

## Cách 2: AI dùng MCP Browser (khi chưa có Playwright hoặc cần test thủ công từng bước)

Khi dự án chưa có Playwright hoặc cần kiểm tra chi tiết từng bước (form Modal, Sửa/Xóa), AI có thể dùng **MCP cursor-ide-browser** (hoặc cursor-browser-extension) để:

1. **Mở trang:** `browser_navigate` → `http://localhost:5173/login`
2. **Kiểm tra form:** `browser_snapshot` → xác nhận có ô username, password, nút đăng nhập
3. **Điền form:** `browser_fill` / `browser_type` cho username `admin`, password `Admin@123`
4. **Submit:** `browser_click` nút đăng nhập
5. **Chờ redirect:** Đợi 2–3s, `browser_snapshot` → kiểm tra URL chuyển sang /organizations (hoặc có menu/header đã đăng nhập)
6. **Trang đơn vị:** `browser_navigate` → `/organizations` → snapshot kiểm tra có bảng, nút "Thêm đơn vị"
7. **Trang user:** `browser_navigate` → `/users` → snapshot kiểm tra có bảng, "Thêm người dùng"
8. **Protected route:** Mở tab ẩn danh hoặc xóa token, navigate `/organizations` → kỳ vọng redirect về /login
9. **Logout:** Click nút Đăng xuất → snapshot kiểm tra về /login

**Báo kết quả:** Với mỗi bước tương ứng checklist 7.1 (5–9), AI ghi **Pass** hoặc **Fail** và mô tả ngắn (vd. "Bước 5 Login thành công: Pass – redirect đến /organizations").

**Lưu ý:** Cần bật MCP server cursor-ide-browser; thứ tự đúng là navigate → lock (nếu cần) → thao tác → unlock.

---

## Ánh xạ với checklist 7.1 (B6_FRONTEND.md)

| Bước 7.1 | Cách 1 (Playwright) | Cách 2 (MCP Browser) |
|----------|---------------------|------------------------|
| 1. Build | `npm run build` (riêng) | — |
| 2. API chạy | Script/CI hoặc thủ công | Thủ công |
| 3. FE chạy | `webServer` trong config hoặc thủ công | Thủ công |
| 4. Trang đăng nhập | Test "Login page" | navigate /login → snapshot |
| 5. Login thành công | Test "Login thành công" | fill + click → snapshot URL |
| 6. Trang đơn vị | Test "Trang đơn vị" | navigate /organizations → snapshot |
| 7. Trang user | Test "Trang user" | navigate /users → snapshot |
| 7a/7b Form CRUD | Có thể thêm test mở Modal, fill, submit | navigate → click Thêm → fill → click Tạo → snapshot |
| 8. Chưa login → redirect | Test "Protected route" | tab ẩn danh /organizations → snapshot /login |
| 9. Logout | Test "Logout" | click Đăng xuất → snapshot |

---

## Tóm tắt cho AI

- **Khi được giao "tự test UI B6" hoặc "chạy checklist 7.1":**
  1. Đảm bảo API (5080) và FE (5173) đang chạy.
  2. **Ưu tiên:** Chạy `npm run test:e2e` trong `src/bcdt-web` → báo Pass/Fail từng test.
  3. **Nếu chưa có test:e2e hoặc cần từng bước:** Dùng MCP browser theo Cách 2, thực hiện lần lượt bước 4→9 và ghi Pass/Fail.
  4. Báo cáo: liệt kê bước (4–9, 7a/7b) kèm Pass/Fail; nếu Fail ghi rõ lỗi.

- **Sau khi sửa code FE/BE:** Chạy lại test E2E (hoặc MCP flow) và chỉ báo "đã xong" khi test Pass hoặc đã ghi rõ Fail và hướng xử lý.
