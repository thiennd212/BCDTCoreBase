# AI Work Protocol – BCDT (STRICT)

Giao thức bắt buộc cho AI khi làm việc trên repo. Nếu không phát hiện thông tin thì ghi **Not detected**.
**Mục tiêu:** ngăn sửa sai lane (RLS/Hangfire/workbook/dashboard), ngăn refactor lan rộng, đảm bảo có verify trước khi báo xong.

---

## 0. Task Contract (luật số 1)

- Mọi thay đổi **PHẢI** bám theo **Task File** (vd. `/docs/speckit/<ticket>_tasks.md`) hoặc mô tả ticket/PR đã được Claude (Planner) chốt.
- Nếu Task File **không nêu rõ** phạm vi/file cần sửa → **DỪNG**, yêu cầu Claude cập nhật Task File (không tự suy diễn).
- Mỗi commit/PR phải trace được về **Task ID** (ghi trong commit message hoặc PR description).

---

## 1. Scope of allowed edits (khóa phạm vi)

### 1.1 Allowed (chỉ trong phạm vi task)
AI chỉ được sửa **các file đúng trong danh sách của Task File**, và **tối đa** theo 1 trong 3 nhóm sau:

1) **Code BE**: `src/BCDT.*`  
2) **Code FE**: `src/bcdt-web/src`  
3) **Docs/Test/Tools**: `docs/`, `docs/postman/`, `memory/`, script SQL trong `docs/script_core/sql/`

> Quy tắc: **Không được “đi săn” file khác** ngoài scope chỉ vì “có vẻ liên quan”.

### 1.2 Disallowed (cấm tuyệt đối nếu không có “explicit approval”)
Cấm thực hiện các việc sau nếu Task File không yêu cầu rõ + Claude không approve:

- Refactor diện rộng (rename hàng loạt, format toàn repo, đổi structure folder).
- Thay đổi **middleware order** / pipeline request.
- Thay đổi cơ chế Auth/JWT, RateLimit, CORS, Compression.
- Thay đổi schema DB / RLS policy / session-context SP theo kiểu “tiện tay”.
- Thêm dependency lớn hoặc đổi major version package.

### 1.3 Secrets
- **Cấm** commit secrets (connection string, JWT secret, API keys).
- `appsettings.Development.json` **không** commit (theo RUNBOOK). (Nếu cần mẫu, tạo `appsettings.Development.sample.json` và không chứa secrets).

### 1.4 Branching / PR
- Not detected.

---

## 2. Change control (must-ask / stop rules)

### 2.1 MUST-ASK (phải hỏi Claude trước khi sửa)
Nếu task chạm một trong các vùng sau, AI Implementer (Cursor) **phải dừng** và yêu cầu Claude (Planner/QC) làm impact analysis trước:

- **RLS / Session context** (middleware, sp_SetUserContext/sp_SetSystemContext, policy/filter).
- **Middleware**: SessionContextMiddleware, RequestTrace, RateLimit, Auth/CORS.
- **Hangfire jobs**: job mới hoặc sửa job có đọc/ghi bảng RLS.
- **Workbook flow**: BuildWorkbookFromSubmissionService, SyncFromPresentationService, DataBindingResolver, endpoints `workbook-data`, `report-presentations`.
- **Dashboard/Reporting**: bất kỳ thay đổi dùng ReadReplica / AppReadOnlyDbContext.
- **SQL scripts** trong `docs/script_core/sql/` ảnh hưởng production migration.

### 2.2 DECISION REQUIRED (bắt buộc ghi DECISIONS.md)
Bắt buộc thêm entry vào `/memory/DECISIONS.md` nếu thay đổi thuộc loại:

- thay đổi kiến trúc/biên module,
- thay đổi RLS/session-context behavior,
- thay đổi workflow nhập liệu workbook (contract/format, ordering, consistency),
- thay đổi cách chạy Hangfire trong Prod,
- thay đổi nguyên tắc dùng replica/DbContext,
- thay đổi verify gate (bỏ E2E/Postman/build).

---

## 3. Hard rules (không được vi phạm)

### 3.1 RLS & Session Context
- Mọi request HTTP phải qua **SessionContextMiddleware** để set UserId/OrganizationId cho RLS áp dụng đúng.
- Khi **SetUserContext throw**: trả **503** + SESSION_CONTEXT_FAILED và **KHÔNG** gọi `_next()`.
- Không được “bypass” RLS bằng cách gọi thẳng AppDbContext/SQL mà thiếu context (trừ trường hợp SystemContext đã được thiết kế và được Claude approve).

### 3.2 Hangfire & RLS
- Job chạy ngoài HTTP không có session context. Mọi job đọc/ghi bảng có **RLS** phải gọi **sp_SetSystemContext** và cuối cùng **sp_ClearUserContext**.
- Nếu tạo job mới: phải copy đúng pattern của job hiện tại (vd. AggregateSubmissionJob/Prod-8 như tài liệu nội bộ).

### 3.3 Workbook flow (Excel nhập liệu)
- Thứ tự bắt buộc: Form config → **BuildWorkbookFromSubmissionService** → GET **workbook-data** → FE Fortune-sheet → PUT **report-presentations** → **SyncFromPresentationService** → ReportDataRow + ReportSummary.
- Không đảo thứ tự ghi (presentation trước, sync sau) và không đổi contract payload nếu không có plan + migration note.

### 3.4 Dashboard & Read Replica
- Dashboard/aggregate **không** dùng **AppReadOnlyDbContext/ReadReplica** khi RLS bật; phải dùng **AppDbContext**.

---

## 4. Verification rules (bắt buộc trước khi báo xong)

### 4.1 Backend build (khi sửa BE)
- Trước `dotnet build`: tắt process **BCDT.Api** để tránh lock DLL  
  PowerShell:
  `Get-Process -Name "BCDT.Api" -ErrorAction SilentlyContinue | Stop-Process -Force`
- Build:
  `dotnet build src/BCDT.Api/BCDT.Api.csproj`
- Chỉ báo xong khi build **PASS**.

### 4.2 Frontend E2E (khi sửa FE hoặc chạm workbook flow)
- BE API chạy `http://localhost:5080`
- Từ `src/bcdt-web` chạy: `npm run test:e2e`
- Báo Pass/Fail **từng spec**; Fail → fix → chạy lại (không “báo xong” khi còn fail).

### 4.3 Postman smoke (khi sửa/thêm API)
- Chạy requests liên quan trong Postman collection (`docs/postman/`) và xác nhận response format đúng (`success/data/errors`).

### 4.4 Task chỉ doc/SQL
- Nếu chỉ doc/SQL: không bắt buộc build/E2E, nhưng phải tự-verify theo loại (vd. SQL có script order rõ, không chứa secrets).

---

## 5. Completion criteria (điều kiện “được phép báo xong”)

Một task chỉ được coi là DONE khi có đủ:

- Link/ID task (traceability).
- Danh sách file đã sửa (ngắn gọn).
- Kết quả verify (build/E2E/Postman) hoặc lý do skip.
- Nếu thuộc loại DECISION REQUIRED → đã cập nhật `/memory/DECISIONS.md`.
- Cập nhật `/memory/project_state.md` (Done/In progress/How to verify) nếu task kéo dài > 1 phiên.

---

## 6. Tài liệu tham chiếu

- RUNBOOK: `docs/RUNBOOK.md` (6.1 build, 7 E2E, 10 Production)
- E2E verify: `docs/E2E_VERIFY.md`
- Task & block giao AI: `docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md`