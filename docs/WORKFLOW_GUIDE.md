# BCDT Development Workflow Guide

Hướng dẫn quy trình phát triển dự án BCDT với AI Agent.

---

## 1. Tổng quan Workflows

| Workflow | Khi nào dùng | Thời gian | Subagents |
|----------|--------------|-----------|-----------|
| `feature-complete` | Tính năng mới end-to-end | 30-60 phút | 2-3 |
| `crud-entity` | Thêm entity + CRUD | 15-30 phút | 1-2 |
| `form-report` | Tạo biểu mẫu mới | 20-40 phút | 1-2 |
| `bug-fix` | Fix bug có hệ thống | 10-30 phút | 1 |
| `refactor` | Cải tiến code | 15-45 phút | 1-2 |
| `api-integration` | Tích hợp API ngoài | 30-60 phút | 1-2 |

### Cursor commands (agentic workflows)

Trong ô chat Agent, gõ `/` rồi chọn lệnh để chạy workflow có sẵn:

| Lệnh | Mục đích |
|------|----------|
| **/bcdt-task** | Bắt đầu công việc BCDT: đọc AI_CONTEXT + TONG_HOP mục 3.2, làm theo block "Cách giao AI", verify, cập nhật TONG_HOP nếu xong. |
| **/bcdt-verify** | Chạy kiểm tra đầy đủ: build, test cases (Kiểm tra cho AI), Postman; báo Pass/Fail từng bước. |
| **/bcdt-next** | Đề xuất công việc tiếp theo (ưu tiên 1) và block "Cách giao AI" copy-paste. |
| **/review** | Rà soát nhanh: build, git diff, gợi ý bước kiểm tra. |
| **/bcdt-auto** | Tự động: ưu tiên 1 từ TONG_HOP → làm task → verify → cập nhật TONG_HOP (một lệnh). |

**Hooks (long-running):** Khi agent dừng, hook có thể gửi followup để lặp lại (vd chạy verify đến khi Pass). Ghi `DONE` hoặc `VERIFY PASS` vào `.cursor/scratchpad.md` để kết thúc vòng lặp. Chi tiết: [AGENTS.md](../AGENTS.md).

---

## 2. Workflow: Feature Complete

### Khi nào dùng
- Thêm tính năng mới hoàn chỉnh
- Cần cả backend + frontend + database

### Cách kích hoạt
```
User: "Tạo tính năng quản lý sản phẩm"
User: "Implement product management feature"
```

### Steps

#### Step 1: Analyze & Design
```
Prompt: "Phân tích yêu cầu tính năng [X], xác định:
- Tables cần tạo/sửa
- APIs cần implement
- UI screens cần tạo
- Liên kết với modules hiện có"
```

**Output mong đợi:**
- Danh sách tables với columns
- Danh sách API endpoints
- Wireframe UI (text-based)

#### Step 2: Database
```
Prompt: "Tạo SQL migration cho tính năng [X] theo danh sách:
- Table: BCDT_Product (Id, Code, Name, CategoryId, Price...)
- Table: BCDT_ProductCategory (Id, Code, Name...)
- Indexes và constraints"
```

**Sử dụng skill:** `bcdt-sql-migration`

#### Step 3: Backend
```
Prompt: "Tạo backend code cho [X]:
- Entity classes
- DTOs (Dto, Request, Response)
- FluentValidation validators
- Service interface + implementation
- Controller với CRUD endpoints
- Register DI"
```

**Sử dụng skill:** `bcdt-entity-crud`, `bcdt-api-endpoint`

#### Step 4: Frontend
```
Prompt: "Tạo frontend cho [X]:
- API client (axios)
- Custom hooks (React Query)
- List page với DataGrid
- Detail/Edit page
- Routes"
```

**Sử dụng skill:** `bcdt-react-page`

**Nếu entity có ParentId (dữ liệu phân cấp):** Dùng thêm **skill bcdt-hierarchical-tree** và tuân theo [HIERARCHICAL_DATA_BASE_AND_RULE.md](de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md): list endpoint hỗ trợ `all=true`; FE dùng `utils/treeUtils.ts` (buildTree, treeExcludeSelfAndDescendants); list page dùng **Table tree** (dataSource = treeData); form trường "cha" dùng **TreeSelect**; khi sửa loại trừ bản thân + con. **Agent:** bcdt-hierarchical-data.

#### Step 5: Verify
```
Prompt: "Kiểm tra và fix:
- Lint errors
- Build errors
- Test API với Swagger
- Test UI flow"
```

**Trước khi build Backend:** Kiểm tra và **hủy process BCDT.Api** nếu đang chạy để tránh lỗi file/DLL bị lock (xem [RUNBOOK.md](RUNBOOK.md) mục 6.1). Ví dụ PowerShell: `Get-Process -Name "BCDT.Api" -ErrorAction SilentlyContinue | Stop-Process -Force` rồi mới chạy `dotnet build`.

---

## 3. Workflow: CRUD Entity

### Khi nào dùng
- Thêm entity đơn giản
- CRUD cơ bản, không logic phức tạp

### Cách kích hoạt
```
User: "Tạo CRUD cho Supplier"
User: "Create entity Notification"
```

### Quick Steps
```
Step 1: "Tạo SQL table BCDT_Supplier với columns: Code, Name, Phone, Email, Address"
        → Skill: bcdt-sql-migration

Step 2: "Tạo full backend CRUD cho Supplier"
        → Skill: bcdt-entity-crud

Step 3: "Tạo React pages cho Supplier: list + detail"
        → Skill: bcdt-react-page

Step 4: "Check lints và fix errors"
```

---

## 4. Workflow: Form Report

### Khi nào dùng
- Tạo biểu mẫu báo cáo mới
- Cấu hình Excel template

### Cách kích hoạt
```
User: "Tạo biểu mẫu báo cáo nhân sự tháng"
User: "Create form BC_NHANSU_T"
```

### Steps

#### Step 1: Gather Requirements
```
Prompt: "Tôi cần tạo biểu mẫu [Tên]. Hãy hỏi:
- Các cột cần có (tên, kiểu dữ liệu, có bắt buộc không)
- Cột nào được nhập, cột nào tự động
- Nguồn dữ liệu cho cột tự động
- Chu kỳ báo cáo
- Cần workflow phê duyệt bao nhiêu cấp"
```

#### Step 2: Generate Form SQL
```
Prompt: "Tạo SQL cho FormDefinition với:
- Code: BC_NHANSU_T
- Name: Báo cáo nhân sự tháng
- Columns: STT, Họ tên, Phòng ban, Số ngày công, Ghi chú
- Bindings: Phòng ban từ Organization
- Frequency: Monthly"
```

**Sử dụng skill:** `bcdt-form-builder`

#### Step 3: Configure Workflow
```
Prompt: "Tạo workflow 2 cấp cho form BC_NHANSU_T:
- Cấp 1: Trưởng phòng duyệt (UNIT_ADMIN)
- Cấp 2: Giám đốc duyệt (FORM_ADMIN)"
```

**Sử dụng skill:** `bcdt-workflow-config`

#### Step 4: Test
```
Prompt: "Test form generation:
- Gọi API /api/v1/forms/BC_NHANSU_T/generate
- Kiểm tra Excel output
- Test submit workflow"
```

---

## 5. Workflow: Bug Fix

### Khi nào dùng
- Fix bug được report
- Lỗi cần trace

### Cách kích hoạt
```
User: "Fix bug: Không lưu được submission"
User: "Lỗi 500 khi approve workflow"
```

### Steps

#### Step 1: Analyze
```
Prompt: "Phân tích bug:
- Error message: [paste error]
- Steps to reproduce: [steps]
Hãy xác định nguyên nhân có thể"
```

#### Step 2: Locate
```
Prompt: "Tìm code liên quan đến [feature/endpoint]
- Service method
- Database operation
- Validation logic"
```

#### Step 3: Fix
```
Prompt: "Sửa bug tại [file]:
- Root cause: [explanation]
- Fix: [description]
Đảm bảo không break code khác"
```

#### Step 4: Verify
```
Prompt: "Verify fix:
- Test original bug scenario
- Test related scenarios
- Check for regressions"
```

---

## 6. Workflow: Refactor

### Khi nào dùng
- Cải tiến code quality
- Extract common logic
- Performance optimization

### Cách kích hoạt
```
User: "Refactor SubmissionService để dễ test hơn"
User: "Extract common validation logic"
```

### Steps

#### Step 1: Analyze Current State
```
Prompt: "Phân tích code hiện tại của [component]:
- Structure
- Dependencies
- Issues (duplication, complexity, coupling)"
```

#### Step 2: Plan Refactor
```
Prompt: "Đề xuất refactor plan:
- Changes cần làm
- Order of changes
- Risk assessment
- Backward compatibility"
```

#### Step 3: Implement
```
Prompt: "Thực hiện refactor theo plan:
- Step-by-step changes
- Maintain functionality
- Update tests if needed"
```

---

## 7. Workflow: API Integration

### Khi nào dùng
- Tích hợp external API
- Lấy dữ liệu từ hệ thống khác

**Sử dụng skill:** `bcdt-external-api`

### Cách kích hoạt
```
User: "Tích hợp API exchange rate từ NHNN"
User: "Connect to external HR system"
```

### Steps

#### Step 1: API Analysis
```
Prompt: "Phân tích external API:
- Endpoint: [URL]
- Authentication: [type]
- Request/Response format
- Rate limits"
```

#### Step 2: Create Client
```
Prompt: "Tạo API client cho [service]:
- HttpClient wrapper
- Request/Response DTOs
- Error handling
- Retry policy (Polly)"
```

#### Step 3: Integration Service
```
Prompt: "Tạo integration service:
- IExternalXxxService interface
- Implementation với caching
- Fallback strategy
- Logging"
```

#### Step 4: Data Binding
```
Prompt: "Kết nối với Form Data Binding:
- Thêm binding type nếu cần
- Cấu hình cache duration
- Test với form generation"
```

---

## 8. Subagent Usage Patterns

### Pattern 1: Parallel Execution
```
Khi backend và frontend độc lập:

Main Agent:
├── Task 1 (generalPurpose): Backend implementation
└── Task 2 (generalPurpose): Frontend implementation
    ↓
Main Agent: Integrate and verify
```

**Ví dụ prompt:**
```
"Tạo tính năng Product Management.
Chạy song song:
1. Backend: Entity, Service, Controller cho Product
2. Frontend: Pages, hooks, API client cho Product
Sau đó verify integration."
```

### Pattern 2: Explore then Implement
```
Khi cần hiểu codebase trước:

Main Agent:
├── Task 1 (explore): "Tìm hiểu cách workflow engine hoạt động"
    ↓
└── Task 2 (generalPurpose): "Implement custom workflow step"
```

### Pattern 3: Sequential with Context
```
Khi step sau phụ thuộc step trước:

Step 1: Create SQL → Get table structure
Step 2: Create Entity (using table structure)
Step 3: Create Service (using entity)
Step 4: Create Controller (using service)
```

---

## 9. Best Practices

### DO ✅
- **Trước khi build BE:** Kiểm tra và hủy process API (BCDT.Api) nếu đang chạy để tránh lỗi file locked (RUNBOOK mục 6.1).
- Mô tả rõ ràng yêu cầu
- Cung cấp context (table names, endpoints)
- Review output trước khi continue
- Test từng step

### DON'T ❌
- Yêu cầu quá nhiều trong 1 prompt
- Skip verify step
- Ignore lint errors
- Commit code chưa test

---

## 10. Quick Reference

### Trigger Phrases

| Phrase | Workflow |
|--------|----------|
| "Tạo tính năng", "Implement feature" | feature-complete |
| "Tạo CRUD", "Create entity" | crud-entity |
| **"Dữ liệu phân cấp", "hiển thị cây", "tree table", "TreeSelect"** | **Skill: bcdt-hierarchical-tree / Agent: bcdt-hierarchical-data** |
| "Tạo biểu mẫu", "Create form" | form-report |
| "Fix bug", "Lỗi" | bug-fix |
| "Refactor", "Cải tiến" | refactor |
| "Tích hợp API", "Connect to" | api-integration |

### Skills Quick Reference

| Task | Skill |
|------|-------|
| Tạo SQL table/column | bcdt-sql-migration |
| Tạo backend CRUD | bcdt-entity-crud |
| Tạo API endpoint | bcdt-api-endpoint |
| Tạo React page | bcdt-react-page |
| **Dữ liệu phân cấp (tree)** | **bcdt-hierarchical-tree** (API all=true, treeUtils, Table tree, TreeSelect) |
| Tạo form definition | bcdt-form-builder |
| Cấu hình workflow (1-5 cấp) | bcdt-workflow-config hoặc Agent: bcdt-workflow-designer |
| Viết unit/integration test | bcdt-test |
| Tích hợp API ngoài | bcdt-external-api |

---

## 11. Khi nào dùng Skill vs Agent

- **Skill:** Dùng khi cần **tạo mới** theo workflow + template (API, entity, form, page, migration, job, dashboard, test). AI làm theo từng bước và sinh code theo mẫu.
- **Agent:** Dùng khi cần **context chuyên gia** cho một domain (phân tích, thiết kế, sửa bug, refactor). AI dùng kiến thức schema/pattern của domain đó, không nhất thiết theo một workflow tạo mới cố định.

### Task → Công cụ (Skill / Agent)

| Task / Mục đích | Công cụ |
|------------------|---------|
| Tạo CRUD entity đầy đủ | Skill: **bcdt-entity-crud** |
| Thêm API endpoint mới | Skill: **bcdt-api-endpoint** |
| Tạo biểu mẫu (FormDefinition, Sheet, Column, Binding) | Skill: **bcdt-form-builder** |
| Data Binding Resolver, fill template theo BindingType | Agent: **bcdt-data-binding** hoặc **bcdt-excel-generator**; IDataBindingResolver, GET template?fillBinding=true |
| Submission upload Excel, test full flow (template + upload + presentation) | Skill: **bcdt-api-endpoint**, **bcdt-form-builder**; script `docs/script_core/test-submission-upload.ps1` (API chạy trước, 10/10 Pass) |
| Tạo trang React (list/detail, grid, hooks, API client) | Skill: **bcdt-react-page** |
| Hiển thị list phân cấp dạng cây (Table tree, TreeSelect, API all=true) | Skill: **bcdt-hierarchical-tree** hoặc Agent: **bcdt-hierarchical-data** |
| Thêm bảng/cột, migration SQL | Skill: **bcdt-sql-migration** |
| Tạo job Hangfire (kỳ báo cáo, nhắc hạn) | Skill: **bcdt-hangfire-jobs** |
| Dashboard, biểu đồ, task list | Skill: **bcdt-dashboard-charts** |
| Viết unit/integration test | Skill: **bcdt-test** |
| Cấu hình workflow 1–5 cấp (WorkflowDefinition, Step, FormWorkflowConfig) | Skill: **bcdt-workflow-config** hoặc Agent: **bcdt-workflow-designer** |
| Phân tích/thiết kế data binding, 7 loại nguồn | Agent: **bcdt-data-binding** |
| Thiết kế lưu Excel (3 layer, SaveOrchestrator) | Agent: **bcdt-hybrid-storage** |
| Phân quyền RBAC, RLS, policy | Agent: **bcdt-auth-expert** |
| Phân tích/thiết kế cấu trúc form (FormDefinition, cột, binding) | Agent: **bcdt-form-analyst** |
| **Review nghiệp vụ** (đối chiếu yêu cầu–code–DB, gap analysis) | Agent: **bcdt-business-reviewer** |
| Generate workbook từ definition, DevExpress | Agent: **bcdt-excel-generator** |
| Tổng hợp, ReportSummary, công thức | Agent: **bcdt-aggregation-builder** |
| Thông báo, SignalR, Email, BCDT_Notification | Agent: **bcdt-notification** |
| Tổ chức 5 cấp, UserOrganization | Agent: **bcdt-org-admin** |
| **Dữ liệu phân cấp (tree table, TreeSelect, buildTree)** | Agent: **bcdt-hierarchical-data** hoặc Skill: **bcdt-hierarchical-tree** |
| Kỳ báo cáo, ReportingPeriod, Hangfire schedule | Agent: **bcdt-report-period** |
| Submission lifecycle, lock, workflow | Agent: **bcdt-submission-processor** |
| Dữ liệu tham chiếu (EAV, Reference entity) | Agent: **bcdt-reference-data** |
| Auth mở rộng (SSO, LDAP, 2FA) | Agent: **bcdt-auth-extension** |
| Chữ ký số (Audit-based, VGCA) | Agent: **bcdt-digital-signature** |
| Tích hợp API ngoài (HttpClient, Polly, DTO, cache) | Skill: **bcdt-external-api** |

---

**Version:** 1.0  
**Last Updated:** 2026-02-03  

**Changelog:** Cập nhật lịch sử thay đổi tại [CHANGELOG.md](../CHANGELOG.md) khi phát hành phiên bản hoặc thay đổi đáng chú ý (theo format Keep a Changelog).
