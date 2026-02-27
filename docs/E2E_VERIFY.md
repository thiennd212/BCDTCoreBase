# E2E trong phase Verify (agentic workflow)

Tài liệu này mô tả **khi nào** và **cách** chạy E2E trong phase Verify để đảm bảo chức năng FE được test đầy đủ và đúng.

---

## 1. Khi nào chạy E2E

- **Task có đụng FE** (tạo/sửa trang, component, API client, route): trong phase **Verify** bắt buộc chạy E2E (toàn bộ hoặc spec liên quan), báo Pass/Fail từng file spec.
- **Task chỉ BE/DB/doc**: không bắt buộc E2E; vẫn chạy build FE nếu có sửa code FE.

---

## 2. Điều kiện trước khi chạy

- **BE API** đang chạy tại `http://localhost:5080` (E2E gọi login + API).  
  Nếu chưa: `dotnet run --project src/BCDT.Api/BCDT.Api.csproj --launch-profile http` (có thể chạy nền).
- **Thư mục:** Mọi lệnh E2E chạy từ **`src/bcdt-web`** (hoặc từ repo root với `--prefix` tương ứng).  
  Lệnh chuẩn: `npm run test:e2e` (Playwright tự start dev server nếu chưa có, trừ CI).

---

## 3. Danh sách spec và phạm vi

| File spec | Phạm vi (chức năng được test) |
|-----------|-------------------------------|
| `e2e/login.spec.ts` | Đăng nhập, logout, redirect khi chưa auth |
| `e2e/pages.spec.ts` | Trang đơn vị, trang user (bảng + nút Thêm) |
| `e2e/reference-entity-types.spec.ts` | CRUD Loại thực thể (checklist 10.3: mở trang, Thêm, Sửa, Xóa) |
| `e2e/b12-p7-formconfig-submission.spec.ts` | B12 P7 – form config & submission |
| `e2e/workflow-definitions.spec.ts` | Quy trình phê duyệt (WorkflowDefinitionsPage: bảng quy trình, Thêm quy trình, Các bước duyệt, Thêm bước) |

**Chạy toàn bộ:** `npm run test:e2e` trong `src/bcdt-web` → chạy tất cả file trên.

**Chạy theo file (vd chỉ Loại thực thể):**  
`npx playwright test e2e/reference-entity-types.spec.ts` trong `src/bcdt-web`.

---

## 4. Trong phase Verify (AI / agentic)

1. **Nếu task đụng FE:**  
   Chạy `npm run test:e2e` trong `src/bcdt-web` (đảm bảo BE đang chạy tại 5080).  
   Báo **Pass** hoặc **Fail** **từng file spec** (vd: `login.spec.ts: Pass`, `pages.spec.ts: Pass`, `reference-entity-types.spec.ts: Pass`, …).  
   Nếu Fail: ghi rõ lỗi (vd test name, assertion), sửa rồi Verify lại; không báo xong đến khi Pass (hoặc đã ghi rõ skip có lý do).

2. **Nếu task chỉ BE/DB:**  
   E2E không bắt buộc; vẫn build FE nếu có thay đổi code FE.

3. **Sau khi E2E Pass:**  
   Ghi vào `.cursor/scratchpad.md` dòng `DONE` hoặc `VERIFY PASS` nếu dùng stop-hook (grind), để hook không lặp nữa.

---

## 5. Kiểm tra cho AI (checklist chạy E2E toàn bộ)

| Bước | Nội dung | Kỳ vọng |
|------|----------|---------|
| 1 | BE API chạy tại 5080 | **Bắt buộc trước khi chạy E2E.** Nếu chưa: `dotnet run --project src/BCDT.Api/BCDT.Api.csproj --launch-profile http` (có thể nền). Đợi vài giây cho API lắng nghe. |
| 2 | Chạy E2E | `npm run test:e2e` trong `src/bcdt-web`. |
| 3 | Báo từng spec | login.spec.ts, pages.spec.ts, reference-entity-types.spec.ts, b12-p7-formconfig-submission.spec.ts, workflow-definitions.spec.ts: Pass/Fail/Skip từng file. **Tổng:** 21 tests (17 passed, 0 skipped). Đã sửa FE ReferenceEntityTypesPage (handleSubmit mutateAsync + validateFields theo mode) → Bước 4 Pass. |

---

## 6. Tham chiếu

- Playwright config: `src/bcdt-web/playwright.config.ts`
- Rule Verify: **always-verify-after-work**, **bcdt-agentic-workflow**
- Checklist FE Loại thực thể: `docs/de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md` mục 10.3
