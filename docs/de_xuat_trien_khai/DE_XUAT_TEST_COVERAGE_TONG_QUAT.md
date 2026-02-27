# Đề xuất: Giải pháp test coverage tổng quát cho toàn hệ thống BCDT

**Mục đích:** Đảm bảo **mọi tính năng** (B1, B2, B3, B4, … API, DB, UI) đều có test cases rõ ràng và AI **tự động** không bỏ sót: tạo/cập nhật test case khi triển khai hoặc sửa, chạy đủ case trước khi báo xong.

**Phạm vi:** Toàn hệ thống (Auth, Organization, Form, Data, Workflow, …), không chỉ B1.

**Trạng thái:** Đề xuất – chờ confirm trước khi triển khai.

---

## 1. Nguyên tắc tổng quát

1. **Mỗi tính năng / nhóm API** có một **tài liệu test cases** (hoặc một mục “Test cases / Kiểm tra cho AI” trong file đề xuất triển khai của tính năng đó).
2. **AI bắt buộc:** Khi triển khai mới hoặc sửa code liên quan đến một tính năng:
   - **Kiểm tra** xem tính năng đó đã có test case doc (hoặc mục kiểm tra) chưa.
   - **Nếu chưa có:** tạo mới theo template chuẩn (happy path + edge cases tối thiểu).
   - **Nếu đã có:** cập nhật khi thêm endpoint / đổi request-response / đổi behavior.
   - **Chạy** toàn bộ test cases (hoặc checklist tối thiểu) **trước khi** báo hoàn thành; báo **Pass/Fail từng case**.
3. **Rule** được bổ sung/chuẩn hóa để AI luôn thực hiện bước “test cases” mà không cần user nhắc.

---

## 2. Cấu trúc test cases trong repo

### 2.1. Vị trí và tên file

| Cách tổ chức | Vị trí | Ví dụ |
|--------------|--------|--------|
| **A – File test case riêng** | `docs/de_xuat_trien_khai/{Mã_tính_năng}_TEST_CASES.md` | `B1_TEST_CASES.md`, `B4_ORGANIZATION_TEST_CASES.md` |
| **B – Gộp vào file đề xuất** | Mục **“7. Kiểm tra / Test cases”** và **“7.1. Kiểm tra cho AI”** trong `docs/de_xuat_trien_khai/{Mã}_*.md` | Như hiện tại `B1_JWT.md` mục 7, 7.1 |

**Đề xuất:** Dùng **kết hợp**:
- File đề xuất (vd `B1_JWT.md`) giữ mục **“7.1. Kiểm tra cho AI”** là **checklist tối thiểu** (số bước ít, lệnh cụ thể) để AI chạy nhanh mỗi lần.
- **Nếu** tính năng có nhiều case (happy + nhiều edge): thêm file `{Mã}_TEST_CASES.md` liệt kê **đầy đủ** theo template; trong file đề xuất ghi: *“Test cases đầy đủ: xem [B1_TEST_CASES.md](B1_TEST_CASES.md)”* và yêu cầu AI chạy đủ hoặc chạy checklist 7.1 + “các case quan trọng trong _TEST_CASES”.

### 2.2. Template chuẩn cho test case doc (khi tạo mới)

Mỗi file `*_TEST_CASES.md` (hoặc mục Test cases) nên có cấu trúc:

```markdown
# Test cases – [Tên tính năng] (vd: B1 Auth)

## Phạm vi
- API / DB / UI: ...

## Happy path
| ID | Mô tả | Request / Hành động | Kỳ vọng | Lệnh chạy (gợi ý) |
|----|--------|----------------------|----------|--------------------|
| TC-01 | ... | ... | Status, body | PowerShell/curl |

## Edge / Negative
| ID | Mô tả | Request / Hành động | Kỳ vọng | Lệnh chạy (gợi ý) |
|----|--------|----------------------|----------|--------------------|
| TC-07 | ... | ... | 401/400, errors | ... |

## Kiểm tra cho AI (checklist tối thiểu)
1. Build
2. [Bước 2]
3. ...
```
```

- **Happy path:** Các luồng thành công (200, đúng body).
- **Edge / Negative:** Sai mật khẩu, thiếu token, token hết hạn/revoke, body thiếu/ sai, quyền không đủ, v.v. (401, 400, 403, errors).
- **Kiểm tra cho AI:** Danh sách ngắn bước + lệnh để AI chạy mỗi lần (có thể trùng với một phần bảng trên).

### 2.3. Áp dụng cho từng loại công việc

| Loại công việc | Test case doc / Checklist | AI phải làm |
|----------------|---------------------------|-------------|
| **API mới (vd B2, B4)** | File đề xuất có mục 7 + 7.1; có thể thêm `*_TEST_CASES.md` | Tạo/cập nhật test cases (happy + edge tối thiểu); chạy checklist 7.1 (và case quan trọng trong _TEST_CASES nếu có); cập nhật Postman. |
| **Sửa API / behavior** | File đề xuất tương ứng (vd B1_JWT.md) | Cập nhật test case nếu đổi contract/behavior; chạy lại toàn bộ checklist 7.1; báo Pass/Fail. |
| **DB (migration, script)** | Có thể nằm trong file đề xuất hoặc README script | Test case = query kiểm tra (bảng, cột, dữ liệu mẫu); AI chạy query và đối chiếu. |
| **UI (trang, form)** | File đề xuất frontend (vd B6) | Test case = mở trang, thao tác, gọi API đúng; checklist 7.1 tương ứng. |
| **Chỉ sửa doc / config** | Không bắt buộc file test case mới | Kiểm tra theo loại (vd config → khởi động app, gọi /health). |

---

## 3. Rule cần thiết để AI tự động đảm bảo không thiếu test case

### 3.1. Rule chung (always-verify-after-work hoặc rule riêng)

Bổ sung (hoặc tạo rule mới) với nội dung tương đương:

1. **Khi triển khai hoặc sửa một tính năng (API, DB, UI):**
   - Xác định **file đề xuất** tương ứng (vd `docs/de_xuat_trien_khai/B1_JWT.md`, `B4_*.md`).
   - Kiểm tra file đó có mục **“Kiểm tra cho AI”** hoặc **“Test cases”** (hoặc file `*_TEST_CASES.md` tương ứng) chưa.
   - **Nếu chưa có:** tạo mục checklist tối thiểu (happy path + ít nhất 1–2 edge case quan trọng) theo template trên; ghi rõ Request, Kỳ vọng, Lệnh chạy (PowerShell/curl).
   - **Nếu đã có:** khi behavior/API thay đổi, cập nhật test case (thêm case mới hoặc sửa kỳ vọng).

2. **Trước khi báo hoàn thành task:**
   - Chạy **đủ** các bước trong “Kiểm tra cho AI” (hoặc danh sách case trong _TEST_CASES tương ứng).
   - Báo **Pass/Fail từng bước/case**; nếu Fail thì ghi rõ lỗi và không báo “đã xong” cho đến khi sửa hoặc ghi rõ để xử lý sau.

3. **Tạo/sửa API:** Ngoài test case, vẫn áp dụng quy định hiện tại: Postman collection, build, tắt process BCDT.Api nếu build lock.

### 3.2. Checklist nhanh (trong rule) – thêm dòng

- *“Đã kiểm tra/cập nhật **test cases** cho tính năng vừa làm (file đề xuất mục 7.1 hoặc *_TEST_CASES.md)? Đã **chạy đủ** và báo Pass/Fail?”*

### 3.3. Vị trí rule

- **Ưu tiên:** Bổ sung vào `.cursor/rules/always-verify-after-work.mdc` (vì đã có “tự test trước khi báo xong”, chỉ cần gắn thêm “test cases” vào).
- **Tùy chọn:** Tạo `.cursor/rules/bcdt-test-coverage.mdc` (globs: `**/de_xuat_trien_khai/**`, `**/*Controller*.cs`) với mô tả chi tiết; rule chính vẫn nhắc “xem bcdt-test-coverage khi sửa API/tính năng”.

---

## 4. Luồng AI tự động (tóm tắt)

1. User giao task: “Triển khai B4” / “Sửa login trả 400 khi thiếu password”.
2. AI triển khai code theo file đề xuất.
3. AI kiểm tra: B4 (hoặc B1) đã có mục “Kiểm tra cho AI” / file B4_TEST_CASES chưa?
   - Chưa → tạo checklist (và nếu nhiều case thì tạo B4_TEST_CASES.md) theo template.
   - Đã có → nếu đổi behavior thì cập nhật test case.
4. AI chạy build (và tắt BCDT.Api nếu lock); chạy lần lượt từng bước trong checklist (và case quan trọng trong _TEST_CASES nếu có).
5. AI báo: “1. Build: Pass. 2. TC-01 Login: Pass. 3. TC-07 Login sai pass: Pass. …” (hoặc Fail + lỗi).
6. Chỉ khi đã chạy và báo xong → AI mới trả lời user “đã hoàn thành”.

Như vậy **không thiếu test case** một cách tự động nhờ: (a) bắt buộc có checklist/test case doc, (b) bắt buộc chạy trước khi báo xong, (c) báo Pass/Fail từng case.

---

## 5. Tùy chọn: Integration test (code)

- **Vị trí:** Project `BCDT.Api.IntegrationTests` (hoặc `BCDT.Tests`) dùng xUnit + WebApplicationFactory.
- **Nội dung:** Test HTTP từng nhóm API (Auth, Organization, …) theo từng tính năng; naming theo `bcdt-testing.mdc` (vd `Login_Returns401_When_InvalidPassword`).
- **Khi nào thêm:** Sau khi tính năng ổn định, có thể bổ sung test code cho tính năng đó; rule có thể nhắc “nếu đã có integration test cho tính năng X thì chạy `dotnet test`”.
- **Không thay thế** tài liệu test case: doc test case vẫn là nguồn chính để AI và người test chạy tay; integration test là lớp bổ sung cho regression.

---

## 6. Cần confirm

1. **Cấu trúc:** Đồng ý với cách tổ chức “file đề xuất có mục 7.1 + (tùy chọn) *_TEST_CASES.md” và template test case như trên?
2. **Rule:** Đồng ý bổ sung vào rule (vd `always-verify-after-work`) nội dung: **khi triển khai/sửa tính năng phải có test case (hoặc checklist 7.1), phải chạy đủ và báo Pass/Fail trước khi báo xong**?
3. **Phạm vi:** Áp dụng cho **mọi** tính năng mới hoặc sửa (B1, B2, B3, B4, B5, B6, Form, Data, …), không chỉ B1?
4. **Rule riêng:** Có cần tạo thêm rule riêng `bcdt-test-coverage.mdc` chi tiết, hay chỉ bổ sung vào `always-verify-after-work` là đủ?

Sau khi bạn confirm (từng mục hoặc tổng thể), sẽ triển khai: cập nhật rule, bổ sung template vào doc (vd README `de_xuat_trien_khai`), và (nếu chọn) tạo mẫu B1_TEST_CASES.md để làm chuẩn cho các tính năng khác.
