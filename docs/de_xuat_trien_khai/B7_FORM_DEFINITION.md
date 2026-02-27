# B7 – Form Definition (CRUD biểu mẫu)

**Phase 2 – Week 5–6** theo [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md).  
**Mục tiêu:** API CRUD cho biểu mẫu (BCDT_FormDefinition, BCDT_FormVersion). Bước đầu chỉ CRUD FormDefinition; Sheet/Column/Row/Cell/DataBinding/ColumnMapping triển khai sau.

---

## 1. Tham chiếu

| Tài liệu / Rule | Nội dung |
|-----------------|----------|
| [04.form_definition.sql](../script_core/sql/v2/04.form_definition.sql) | 8 bảng: FormDefinition, FormVersion, FormSheet, FormColumn, FormRow, FormCell, FormDataBinding, FormColumnMapping |
| [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md) | Phase 2 Week 5–6: Form Definition API, Form structure builder, Data Binding Engine, Template management |
| **bcdt-entity-crud** | Skill tạo CRUD theo template dự án |
| **bcdt-api-endpoint** | Skill tạo endpoint REST |
| **always-verify-after-work** | Build, test cases, báo Pass/Fail |

---

## 2. Schema (trích từ 04.form_definition.sql)

### 2.1. BCDT_FormDefinition

| Cột | Kiểu | Ghi chú |
|-----|------|---------|
| Id | INT IDENTITY | PK |
| Code | NVARCHAR(50) | UNIQUE, mã biểu mẫu |
| Name | NVARCHAR(200) | Tên biểu mẫu |
| Description | NVARCHAR(1000) | Mô tả |
| FormType | NVARCHAR(20) | Input, Aggregate (CHECK) |
| CurrentVersion | INT | Mặc định 1 |
| ReportingFrequencyId | INT NULL | FK → BCDT_ReportingFrequency (07) |
| DeadlineOffsetDays | INT | Mặc định 5 |
| AllowLateSubmission | BIT | Mặc định 1 |
| RequireApproval | BIT | Mặc định 1 |
| AutoCreateReport | BIT | Mặc định 0 |
| TemplateFile | VARBINARY(MAX) | Excel template (tùy chọn bước đầu) |
| TemplateFileName | NVARCHAR(255) | |
| Status | NVARCHAR(20) | Draft, Published, Archived (CHECK) |
| PublishedAt, PublishedBy | DATETIME2, INT | |
| IsActive | BIT | Mặc định 1 |
| CreatedAt, CreatedBy, UpdatedAt, UpdatedBy | Audit | |
| IsDeleted | BIT | Soft delete |

### 2.2. BCDT_FormVersion

| Cột | Kiểu | Ghi chú |
|-----|------|---------|
| Id | INT IDENTITY | PK |
| FormDefinitionId | INT | FK → BCDT_FormDefinition |
| VersionNumber | INT | UNIQUE(FormDefinitionId, VersionNumber) |
| VersionName | NVARCHAR(100) | |
| ChangeDescription | NVARCHAR(1000) | |
| TemplateFile, TemplateFileName | VARBINARY(MAX), NVARCHAR(255) | |
| StructureJson | NVARCHAR(MAX) | JSON snapshot |
| IsActive | BIT | |
| CreatedAt, CreatedBy | | |

**Giai đoạn 1 (B7):** Chỉ CRUD **FormDefinition**. FormVersion dùng để liệt kê phiên bản theo form (GET /api/v1/forms/{id}/versions) – không tạo/sửa Version qua API trong B7.

---

## 3. Đề xuất Entity (Domain)

### 3.1. FormDefinition

```csharp
// src/BCDT.Domain/Entities/Form/FormDefinition.cs
namespace BCDT.Domain.Entities.Form;

public class FormDefinition
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string FormType { get; set; } = "Input";       // Input, Aggregate
    public int CurrentVersion { get; set; } = 1;
    public int? ReportingFrequencyId { get; set; }
    public int DeadlineOffsetDays { get; set; } = 5;
    public bool AllowLateSubmission { get; set; } = true;
    public bool RequireApproval { get; set; } = true;
    public bool AutoCreateReport { get; set; }
    public byte[]? TemplateFile { get; set; }
    public string? TemplateFileName { get; set; }
    public string Status { get; set; } = "Draft";         // Draft, Published, Archived
    public DateTime? PublishedAt { get; set; }
    public int? PublishedBy { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    public bool IsDeleted { get; set; }
}
```

### 3.2. FormVersion (dùng cho list versions, không CRUD trong B7)

```csharp
// src/BCDT.Domain/Entities/Form/FormVersion.cs
namespace BCDT.Domain.Entities.Form;

public class FormVersion
{
    public int Id { get; set; }
    public int FormDefinitionId { get; set; }
    public int VersionNumber { get; set; }
    public string? VersionName { get; set; }
    public string? ChangeDescription { get; set; }
    public string? StructureJson { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
```

---

## 4. Đề xuất DTO (Application)

### 4.1. FormDefinitionDto

```csharp
public class FormDefinitionDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string FormType { get; set; } = "Input";
    public int CurrentVersion { get; set; }
    public int? ReportingFrequencyId { get; set; }
    public string? ReportingFrequencyCode { get; set; }   // optional, từ join
    public int DeadlineOffsetDays { get; set; }
    public bool AllowLateSubmission { get; set; }
    public bool RequireApproval { get; set; }
    public bool AutoCreateReport { get; set; }
    public string? TemplateFileName { get; set; }
    public string Status { get; set; } = "Draft";
    public DateTime? PublishedAt { get; set; }
    public int? PublishedBy { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
```

### 4.2. CreateFormDefinitionRequest

- Code, Name, Description (optional), FormType (Input | Aggregate), ReportingFrequencyId (optional), DeadlineOffsetDays, AllowLateSubmission, RequireApproval, AutoCreateReport.  
- Không gửi TemplateFile trong B7 (có thể thêm endpoint upload sau).

### 4.3. UpdateFormDefinitionRequest

- Giống Create, tất cả field có thể cập nhật (trừ Code nếu quy ước Code immutable; hoặc cho phép sửa Code với ràng buộc unique).  
- Status: chỉ cho phép chuyển Draft ↔ Published/Archived theo quy tắc (tùy nghiệp vụ).

### 4.4. FormVersionDto (cho GET /forms/{id}/versions)

- Id, FormDefinitionId, VersionNumber, VersionName, ChangeDescription, IsActive, CreatedAt, CreatedBy.

---

## 5. Đề xuất API (REST)

| Method | Route | Mô tả |
|--------|-------|-------|
| GET | /api/v1/forms | Danh sách biểu mẫu (filter: status, formType, includeInactive). Trả List&lt;FormDefinitionDto&gt;. |
| GET | /api/v1/forms/{id} | Chi tiết một biểu mẫu. Trả FormDefinitionDto. |
| GET | /api/v1/forms/code/{code} | Lấy theo Code (unique). Trả FormDefinitionDto. |
| POST | /api/v1/forms | Tạo biểu mẫu. Body: CreateFormDefinitionRequest. Trả FormDefinitionDto. |
| PUT | /api/v1/forms/{id} | Cập nhật biểu mẫu. Body: UpdateFormDefinitionRequest. Trả FormDefinitionDto. |
| DELETE | /api/v1/forms/{id} | Xóa mềm (IsDeleted = 1). Trả 200. |
| GET | /api/v1/forms/{id}/versions | Danh sách phiên bản (FormVersion). Trả List&lt;FormVersionDto&gt;. (B7: chỉ đọc) |

**Response:** Theo chuẩn BCDT: `{ "success": true, "data": ... }` hoặc `ApiErrorResponse` (400, 404, 409).

**Authorization:** [Authorize] – cần JWT. Có thể áp dụng policy (vd chỉ FORM_ADMIN được tạo/sửa/xóa) sau.

---

## 6. Service (Application)

- **IFormDefinitionService**
  - GetByIdAsync(int id)
  - GetByCodeAsync(string code)
  - GetListAsync(status?, formType?, includeInactive?)
  - CreateAsync(CreateFormDefinitionRequest, int createdBy)
  - UpdateAsync(int id, UpdateFormDefinitionRequest, int updatedBy)
  - DeleteAsync(int id, int deletedBy) – soft delete
  - GetVersionsAsync(int formDefinitionId) – trả danh sách FormVersionDto

- **FormDefinitionService** (Infrastructure): dùng AppDbContext, Result&lt;T&gt;, map Entity ↔ DTO. Kiểm tra Code unique khi Create/Update; kiểm tra ReportingFrequencyId tồn tại nếu gửi.

---

## 7. Validation (FluentValidation)

- **CreateFormDefinitionRequest:** Code Required, MaxLength(50); Name Required, MaxLength(200); FormType phải thuộc Input | Aggregate; DeadlineOffsetDays >= 0.
- **UpdateFormDefinitionRequest:** Giống Create (Code có thể bỏ qua nếu immutable, hoặc cùng rule).

---

## 8. Kiểm tra cho AI (7.1)

**AI sau khi triển khai B7 chạy lần lượt và báo Pass/Fail.**

1. **Build**
   - Trước khi build: hủy process BCDT.Api nếu đang chạy (RUNBOOK 6.1).
   - Lệnh: `dotnet build src/BCDT.Api/BCDT.Api.csproj`
   - Kỳ vọng: Build succeeded.

2. **API đang chạy** (khởi động API, đợi vài giây).

3. **GET /api/v1/forms** (Bearer token admin)
   - Kỳ vọng: 200, `success: true`, `data` là mảng (có thể rỗng).

4. **POST /api/v1/forms** – tạo biểu mẫu
   - Body: `{ "code": "BC_TEST_01", "name": "Biểu mẫu test", "formType": "Input", "deadlineOffsetDays": 5, "allowLateSubmission": true, "requireApproval": true, "autoCreateReport": false }`
   - Kỳ vọng: 200, `data` có Id, Code, Name, Status = Draft.

5. **GET /api/v1/forms/{id}** – lấy chi tiết
   - Kỳ vọng: 200, `data` khớp bản ghi vừa tạo.

6. **GET /api/v1/forms/code/BC_TEST_01**
   - Kỳ vọng: 200, `data.Code` = "BC_TEST_01".

7. **PUT /api/v1/forms/{id}** – cập nhật (đổi name, status nếu cho phép)
   - Kỳ vọng: 200, `data` đã cập nhật.

8. **GET /api/v1/forms/{id}/versions**
   - Kỳ vọng: 200, `data` là mảng (có thể rỗng hoặc có version 1 nếu tạo version khi tạo form).

9. **POST /api/v1/forms** – tạo trùng Code
   - Body cùng code "BC_TEST_01"
   - Kỳ vọng: 409 Conflict hoặc 400 (Code đã tồn tại).

10. **DELETE /api/v1/forms/{id}**
    - Kỳ vọng: 200. GET /api/v1/forms/{id} sau đó: 404 hoặc 200 với IsDeleted (tùy API thiết kế: ẩn luôn hay trả về có cờ).

**Báo kết quả:** Liệt kê từng bước (1–10) kèm **Pass** hoặc **Fail**.

---

### Kết quả chạy checklist 7.1 (2026-02-05)

| Bước | Nội dung | Kết quả |
|------|----------|---------|
| 1 | Build (trước đó đã Pass) | Pass |
| 2 | API + Login | Pass |
| 3 | GET /api/v1/forms | Pass |
| 4 | POST /api/v1/forms (tạo BC_TEST_01) | Pass |
| 5 | GET /api/v1/forms/{id} | Pass |
| 6 | GET /api/v1/forms/code/BC_TEST_01 | Pass |
| 7 | PUT /api/v1/forms/{id} (cập nhật name) | Pass |
| 8 | GET /api/v1/forms/{id}/versions | Pass |
| 9 | POST trùng Code (expect 409) | Pass |
| 10 | DELETE /api/v1/forms/{id} | Pass |

**Script:** [docs/script_core/test-b7-checklist.ps1](../script_core/test-b7-checklist.ps1) (chạy khi API đang chạy trên http://localhost:5080). **E2E FE:** 6/6 Pass (không regression).

---

## 9. Cách giao AI khi triển khai B7

```
Triển khai B7 Form Definition CRUD theo B7_FORM_DEFINITION.md: (1) Domain entities FormDefinition, FormVersion; (2) DTOs FormDefinitionDto, CreateFormDefinitionRequest, UpdateFormDefinitionRequest, FormVersionDto; (3) IFormDefinitionService + FormDefinitionService; (4) FormDefinitionsController route api/v1/forms với GET list, GET by id, GET by code, POST, PUT, DELETE, GET {id}/versions; (5) AppDbContext DbSet FormDefinitions, FormVersions + cấu hình EF; (6) FluentValidation cho Create/Update; (7) Đăng ký DI. Trước khi build: hủy process BCDT.Api (RUNBOOK 6.1). Chạy checklist 7.1 và báo Pass/Fail.
```

---

**Version:** 1.0  
**Ngày:** 2026-02-05
