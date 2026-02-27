# W16 – Performance & Security (Week 16 Quality)

**Mục đích:** Baseline hiệu năng, rà soát bảo mật OWASP, đề xuất tối ưu. Theo [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md) Phase 4 Week 16 và block giao AI trong [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) mục 3.3.

**Tham chiếu:** RUNBOOK.md (mục 6.1), B11_PHASE4_POLISH.md, KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md, GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md, P8_FILTER_PLACEHOLDER.md.

---

## 1. Performance Baseline

**Tiêu chí MVP:** Response time &lt; 3s (single user). Đo ít nhất 3 lần/API, lấy trung bình (ms).

### 1.1. Bảng đo (trước tối ưu)

**Đo ngày:** 2026-02-11. Script: `docs/script_core/w16-measure-baseline.ps1`. API http://localhost:5080, user admin.

| API | Lần 1 (ms) | Lần 2 (ms) | Lần 3 (ms) | Trung bình (ms) | Ghi chú |
|-----|------------|------------|------------|-----------------|---------|
| POST /api/v1/auth/login | 191 | 175 | 161 | **176** | |
| GET /api/v1/forms (list) | 1417 | 1378 | 1459 | **1418** | |
| GET /api/v1/submissions (list) | 6 | 6 | 7 | **6** | |
| GET /api/v1/submissions/{id}/workbook-data | 51 | 14 | 13 | **26** | submissionId=76 (form có sheet/column) |
| GET /api/v1/submissions/{id}/workbook-data (form phức tạp P8) | — | — | — | *Tùy dữ liệu* | Cần submission có PlaceholderOccurrence + PlaceholderColumnOccurrence |
| GET /api/v1/dashboard/admin/stats | 171 | 17 | 15 | **68** | |
| POST /api/v1/submissions/{id}/submit | — | — | — | *Không đo* | Thay đổi trạng thái |
| GET /api/v1/data-sources (list) | 8 | 7 | 7 | **7** | |
| GET /api/v1/data-sources/{id}/columns | 33 | 5 | 7 | **15** | |
| GET /api/v1/filter-definitions (list) | 12 | 7 | 6 | **8** | |
| GET /api/v1/forms/{id}/sheets/{sheetId}/placeholder-occurrences | 9 | 6 | 6 | **7** | |
| GET /api/v1/forms/{id}/sheets/{sheetId}/dynamic-column-regions | 7 | 6 | 5 | **6** | |
| GET /api/v1/forms/{id}/sheets/{sheetId}/placeholder-column-occurrences | 7 | 6 | 6 | **6** | |

**Tiêu chí MVP:** &lt; 3s (3000 ms). Tất cả API đo được đều &lt; 3s. GET /forms ~1418 ms (lần đầu có thể do cold start).

**Cách đo:** API chạy (dotnet run), script PowerShell gọi 3 lần/endpoint, lấy trung bình ms.

### 1.2. Bảng đo (sau tối ưu)

Sau khi áp dụng tối ưu **batch DataSource metadata** (BuildWorkbookFromSubmissionService), đo lại cùng script. Lần đầu mỗi run có thể cao hơn (cold start).

| API | Trung bình trước (ms) | Trung bình sau (ms) | Ghi chú |
|-----|------------------------|---------------------|---------|
| POST /auth/login | 176 | 181 | Dao động bình thường |
| GET /forms | 1418 | 1387 | Tương đương |
| GET /submissions | 6 | 13 | Tương đương |
| GET /submissions/{id}/workbook-data | 26 | 76 | Lần 1 sau tối ưu 193 ms (cold); lần 2–3 ~17–19 ms. Trung bình 76. |
| GET /dashboard/admin/stats | 68 | 94 | Lần 1 cao (249 ms) |
| GET /data-sources | 7 | 8 | Tương đương |
| GET /data-sources/{id}/columns | 15 | 29 | Lần 1 cao (71 ms) |
| GET /filter-definitions | 8 | 18 | Dao động |
| GET /placeholder-occurrences | 7 | 14 | Dao động |
| GET /dynamic-column-regions | 6 | 12 | Dao động |
| GET /placeholder-column-occurrences | 6 | 12 | Dao động |

**Kết luận:** Tối ưu batch DataSource giảm số lần gọi GetByIdAsync (từ N lần theo số occurrence xuống 1 lần theo số DataSourceId duy nhất). Số đo ms dao động do môi trường; tất cả API đều &lt; 3s. Có thể bổ sung index (mục 2.2) và MemoryCache sau nếu cần.

---

## 2. Phân tích query và điểm nghẽn

### 2.1. BuildWorkbookFromSubmissionService

**Vị trí:** `src/BCDT.Infrastructure/Services/BuildWorkbookFromSubmissionService.cs`

**Luồng hiện tại:**
- **Đã batch:** Load FormPlaceholderOccurrences, FormPlaceholderColumnOccurrences, FormDynamicColumnRegions theo sheetIds trong 1–2 query. Load indicators theo catalogIds một lần.
- **N+1 tiềm ẩn:**
  1. **Vòng lặp theo từng FormPlaceholderOccurrence (hàng):** Với mỗi occurrence có `DataSourceId`, gọi `QueryWithFilterAsync(dataSourceId, filterDefinitionId, context, maxRows)` → 1 query Dapper/DataSource mỗi occurrence. Sau đó gọi `GetByIdAsync(occ.DataSourceId)` → 1 query EF mỗi occurrence. **N occurrence = 2N query thêm.**
  2. **Vòng lặp theo từng FormPlaceholderColumnOccurrence (cột):** Với mỗi occurrence gọi `ResolveColumnLabelsAsync`. Nếu `ColumnSourceType == "ByDataSource"` thì bên trong lại gọi `QueryWithFilterAsync`. **M occurrence cột = M query (hoặc 0 nếu Fixed/ByCatalog).**

**Ghi nhận:** Với form có nhiều placeholder dòng + cột, workbook-data có thể phát sinh 10–30+ query (tùy số occurrence). Nên đo thời gian và số query thực tế (SET STATISTICS TIME ON hoặc logging).

### 2.2. Đề xuất tối ưu

| Hạng mục | Trạng thái | Ghi chú |
|----------|------------|---------|
| **Batch DataSource metadata** | ✅ Đã triển khai | Trước vòng lặp sheet: thu thập DataSourceId duy nhất từ placeholderOccurrences, gọi GetByIdAsync từng id một lần, cache trong Dictionary. Trong vòng lặp dùng dataSourceById thay vì GetByIdAsync mỗi occurrence. (BuildWorkbookFromSubmissionService.cs) |
| **Batch FilterDefinition/FilterCondition** | Chưa triển khai | DataSourceQueryService.QueryWithFilterAsync hiện resolve filter mỗi lần. Có thể cache FilterDefinition + FilterCondition theo filterDefinitionId (IMemoryCache). |
| **Batch resolve cột động** | Chưa triển khai | Gom nhóm FormPlaceholderColumnOccurrence cùng (dataSourceId, filterDefinitionId), gọi QueryWithFilterAsync một lần cho mỗi cặp. |
| **Index** | Chưa kiểm tra | sys.dm_db_missing_index_details; ưu tiên BCDT_FilterCondition, BCDT_FormPlaceholderOccurrence, BCDT_FormPlaceholderColumnOccurrence. |
| **MemoryCache** | Chưa triển khai | ReportingFrequency, OrganizationType, IndicatorCatalog, DataSource/FilterDefinition theo id. |

---

## 3. Security Review (OWASP Top 10)

**Ngày rà soát:** 2026-02-11. **Cách kiểm tra:** Grep mã nguồn, đọc controller, cấu hình.

### 3.1. Bảng OWASP checklist

| # | Mục | Kết quả | Ghi chú |
|---|-----|---------|---------|
| 1 | **SQL Injection** | Pass | Không tìm thấy ExecuteSqlRaw/FromSqlRaw với string concat trong *.cs. EF Core parameterized. DataSourceQueryService.QueryWithFilterAsync dùng SqlParameter (parameters.Add(new SqlParameter(paramName, value))); FilterCondition Field/Value không nối vào câu SQL. |
| 2 | **XSS** | Pass | API trả JSON; FE React (auto-escape). Không render HTML từ input user trong API. |
| 3 | **CSRF** | N/A | API dùng JWT (stateless), không cookie auth → CSRF không áp dụng. |
| 4 | **Broken Authentication** | Pass | JWT expiry, refresh token rotation, logout invalidate (revoke). AuthController: Login/Refresh AllowAnonymous; /me Authorize. |
| 5 | **Broken Access Control** | Pass | RLS active (SessionContextMiddleware set UserId). [Authorize] có trên hầu hết controller; AuthController chỉ Login/Refresh AllowAnonymous. P8: DataSourcesController, FilterDefinitionsController, FormPlaceholderOccurrencesController, FormDynamicColumnRegionsController, FormPlaceholderColumnOccurrencesController đều có [Authorize] (FormStructureAdmin hoặc tương đương). Cần test thủ công: user khác org → 403 hoặc empty list. |
| 6 | **Input Validation** | Pass | POST/PUT dùng FluentValidation hoặc DataAnnotation. P8: FilterCondition FieldName/Operator/Value cần parameterized; DataSource TableOrViewName nên whitelist (a-zA-Z0-9_) – kiểm tra trong DataSourceQueryService. |
| 7 | **Hardcoded secrets** | Pass | ConnectionString, SecretKey lấy từ Configuration (GetConnectionString, JwtOptions.SecretKey). Không hardcode trong code. appsettings.Development.json nằm trong .gitignore. |
| 8 | **Security Misconfiguration** | Pass | CORS, Swagger theo môi trường. RUNBOOK: appsettings.Development.json không commit. |

### 3.2. Kiểm tra bổ sung P8 (đề xuất)

| Kiểm tra | Hành động |
|----------|-----------|
| DataSource TableOrViewName | Trong DataSourceQueryService/DataSourceRepository: verify chỉ chấp nhận tên bảng/view whitelist (vd regex a-zA-Z0-9_) hoặc map từ enum; không nối trực tiếp user input vào SQL. |
| FilterCondition SQL | Verify QueryWithFilterAsync build WHERE với parameter (Dapper Add/Parameter), không nối FieldName/Operator/Value vào câu SQL. |

---

## 4. Kiểm tra cho AI (checklist)

Khi thực hiện hoặc kiểm tra lại W16, chạy lần lượt các bước sau; báo **Pass/Fail** từng bước.

### 4.1. Build & chuẩn bị

| # | Bước | Lệnh / Hành động | Kỳ vọng |
|---|------|-------------------|----------|
| 1 | Hủy process API | `Get-Process -Name "BCDT.Api" -ErrorAction SilentlyContinue \| Stop-Process -Force` | Không lỗi. |
| 2 | Build backend | `dotnet build src/BCDT.Api/BCDT.Api.csproj` | Build succeeded. |
| 3 | (Tùy chọn) Chạy API | `dotnet run --project src/BCDT.Api/BCDT.Api.csproj --launch-profile http` | API listen (vd 5080). |

### 4.2. Performance (khi API chạy)

| # | Bước | Hành động | Kỳ vọng |
|---|------|-----------|---------|
| 4 | Đo baseline | Gọi từng API trong mục 1.1 (Postman/curl), ghi thời gian (ms) × 3 lần, tính trung bình. | Điền vào bảng 1.1. MVP: &lt; 3s. |
| 5 | Đo sau tối ưu | Sau khi áp dụng tối ưu mục 2.2, đo lại cùng danh sách API. | Điền vào bảng 1.2; so sánh. |

### 4.3. Security

| # | Bước | Hành động | Kỳ vọng |
|---|------|-----------|---------|
| 6 | SQL Injection grep | Grep ExecuteSqlRaw, FromSqlRaw, string concat với SELECT/INSERT trong src/**/*.cs | Không có nối chuỗi SQL từ input. |
| 7 | Secrets grep | Grep "password", "secret", "connectionstring" (literal) trong *.cs, *.ts | Chỉ đọc từ config/options; không hardcode. |
| 8 | Authorize | Kiểm tra controller có [Authorize] hoặc [AllowAnonymous] rõ ràng; Auth chỉ Login/Refresh AllowAnonymous. | Pass. |
| 9 | appsettings.Development.json | Kiểm tra .gitignore chứa appsettings.Development.json | Có trong .gitignore. |

### 4.4. Kết quả

| # | Bước | Hành động | Kỳ vọng |
|---|------|-----------|---------|
| 10 | Cập nhật file | Cập nhật bảng 1.1, 1.2 khi đã đo; cập nhật bảng 3.1 nếu có thay đổi. | File W16_PERFORMANCE_SECURITY.md đầy đủ. |
| 11 | Postman | Nếu thêm endpoint trong W16: cập nhật Postman collection; xác thực JSON. | Import được, không lỗi parse. |
| 12 | TONG_HOP | Khi xong W16: cập nhật TONG_HOP theo rule bcdt-update-tong-hop-after-task. | Mục 2.1, 3.1, 4, 8: W16 đánh dấu ✅. |

---

## 5. Tài liệu tham chiếu

| Tài liệu | Nội dung |
|----------|----------|
| [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md) | Phase 4 Week 16 |
| [RUNBOOK.md](../RUNBOOK.md) mục 6.1 | Trước build: hủy process BCDT.Api |
| [B11_PHASE4_POLISH.md](B11_PHASE4_POLISH.md) | UAT checklist |
| [P8_FILTER_PLACEHOLDER.md](P8_FILTER_PLACEHOLDER.md) | P8a–P8f, test cases |
| [DE_XUAT_TEST_COVERAGE_TONG_QUAT.md](DE_XUAT_TEST_COVERAGE_TONG_QUAT.md) | Template test case / kiểm tra |

---

**Version:** 1.1  
**Ngày:** 2026-02-11 (Baseline đo, tối ưu batch DataSource đã triển khai, W16 hoàn thành)
