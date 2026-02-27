# Ngữ cảnh dự án BCDT – Cho AI

Tài liệu **một trang** giúp AI nắm nhanh dự án, tìm đúng tài liệu và tránh tốn token. **Đọc file này trước** khi bắt đầu task.

---

## 1. Dự án là gì

- **BCDT:** Hệ thống báo cáo điện tử động. Biểu mẫu Excel (định nghĩa động), nhập liệu web, workflow phê duyệt, tổng hợp, dashboard.
- **Stack:** .NET 8 API, React (Vite, Ant Design), SQL Server, hybrid storage (JSON + relational).
- **MVP 17 tuần:** Phase 1–4 đã hoàn tất (Auth, Org, Form, Submission, Workflow, Reporting, Dashboard, Phase 4 Polish). Chi tiết: [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md).

---

## 2. Tìm yêu cầu ở đâu

| Nhu cầu | Tài liệu | Ghi chú |
|--------|----------|--------|
| **104 yêu cầu hệ thống (MVP)** | [script_core/01.YEU_CAU_HE_THONG.md](script_core/01.YEU_CAU_HE_THONG.md) | Nghiệp vụ (30), Chức năng (22), NFR (20), Khía cạnh (32). |
| **Tổng hợp yêu cầu + mở rộng** | [YEU_CAU_HE_THONG_TONG_HOP.md](YEU_CAU_HE_THONG_TONG_HOP.md) | Tóm tắt 01 + yêu cầu mở rộng (R1–R11: cấu trúc biểu mẫu, chỉ tiêu cố định/động, phân cấp). |
| **Giải pháp chỉ tiêu cố định & động (R1–R11)** | [de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) | Đầy đủ: yêu cầu, gap, kiến trúc, data model, API, FE, phase P1–P7; mục 8 đối chiếu R↔Giải pháp. |
| **Lọc động theo trường + placeholder cột** | [de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md) | DataSource, FilterDefinition, FormPlaceholderOccurrence (dòng), FormDynamicColumnRegion, FormPlaceholderColumnOccurrence (cột); P8a–P8f. |
| **Kế hoạch cấu hình biểu mẫu mở rộng (B12 + P8)** | [de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md) | Trạng thái, thứ tự, chi tiết từng phần (P2a, P4 mở rộng, P7, P8a–P8f); checklist nghiệm thu. Cách giao AI: TONG_HOP mục 3.3, 3.5 hoặc 3.7 (block B12/P8). |

---

## 3. Tiến độ và công việc tiếp theo

- **Nguồn chính:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md).
- **Mục 3.2:** Bảng **Tài liệu · Rules · Agent · Skill** theo từng công việc → chọn tài liệu đọc, rule áp dụng, agent/skill.
- **Mục 3.3, 3.4, 3.5, 3.7:** Block **"Cách giao AI khi làm [Task]"** (copy-paste) cho từng task → có đủ Tài liệu, Rules, yêu cầu test.
- **Mục 8:** Đề xuất công việc tiếp theo + Cách giao AI. Khi ưu tiên 1 đổi → cập nhật TONG_HOP theo rule **bcdt-update-tong-hop-after-task**.

**Tiến độ gần đây (2026-02-06):** B12 P1–P6 (Chỉ tiêu cố định & động) đã xong: P1–P3 (policy, DB, API), P4 (Build workbook + Sync → ReportDynamicIndicator), **P5–P6** (FE FormConfig block "Vùng chỉ tiêu động", SubmissionDataEntry block "Chỉ tiêu động" + PUT dynamic-indicators). Chi tiết: [B12_CHI_TIEU_CO_DINH_DONG.md](de_xuat_trien_khai/B12_CHI_TIEU_CO_DINH_DONG.md).

**Ưu tiên hiện tại:** Week 16–17 (Performance, Security, Demo) hoặc B12 P7 (E2E, tài liệu). **Mở rộng:** B12 P2a, P4 mở rộng, P7; **P8** (P8a–P8f). Kế hoạch chi tiết: [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md).

---

## 4. Rules bắt buộc (luôn áp dụng)

| Rule | Khi nào |
|------|--------|
| **bcdt-agentic-workflow** | Mọi task: **Plan** (liệt kê bước, file, rủi ro, scope) trước → **Execute** theo kế hoạch → **Verify** (build + checklist) → **Reflect** (cập nhật TONG_HOP, gợi ý tiếp). Tách lập kế hoạch và thi hành để giảm sai. |
| **always-verify-after-work** | Sau mọi task: build (khi sửa code), chạy checklist/test; **khi sửa FE** chạy E2E (`npm run test:e2e` trong src/bcdt-web), báo Pass/Fail từng spec. Chi tiết: [E2E_VERIFY.md](E2E_VERIFY.md). |
| **bcdt-update-tong-hop-after-task** | Khi **hoàn thành** một công việc trong danh sách TONG_HOP: cập nhật mục 2.1, 2.2, 3, 4, 5, 8 và Version/Ngày. |
| **bcdt-next-work-ai-prompt** | Khi đề xuất công việc tiếp theo: thêm block **"Cách giao AI"** (copy-paste) cho ưu tiên 1, có yêu cầu viết test case + tự test. |
| **bcdt-project** | Convention: API `/api/v1/`, bảng `BCDT_`, DTO, Result pattern, RLS. |

Build BE: trước khi `dotnet build` **hủy process BCDT.Api** (RUNBOOK mục 6.1).

---

## 5. Kỹ thuật nhanh

- **Cấu trúc code:** [CẤU_TRÚC_CODEBASE.md](CẤU_TRÚC_CODEBASE.md). API response, layered, naming.
- **Chạy & kiểm tra:** [RUNBOOK.md](RUNBOOK.md). DB, appsettings, build, mục 6.1 (tắt process API trước build).
- **API HTTP & mã nghiệp vụ:** [API_HTTP_AND_BUSINESS_STATUS.md](API_HTTP_AND_BUSINESS_STATUS.md).

---

## 6. Agent / Skill theo công việc (tóm tắt)

| Công việc | Agent | Skill |
|-----------|-------|--------|
| Auth, RBAC, RLS | bcdt-auth-expert | bcdt-api-endpoint |
| Tổ chức, User | bcdt-org-admin | bcdt-entity-crud |
| Dữ liệu phân cấp (tree) | bcdt-hierarchical-data | bcdt-hierarchical-tree |
| Workflow | bcdt-workflow-designer | bcdt-workflow-config |
| **Cấu trúc biểu mẫu, chỉ tiêu cố định/động (R1–R11)** | **bcdt-form-structure-indicators** | **bcdt-form-structure**, bcdt-entity-crud, bcdt-hierarchical-tree |
| **B12 P2a/P4 mở rộng/P7, P8 (lọc động, placeholder cột)** | **bcdt-form-structure-indicators** | bcdt-form-structure, bcdt-entity-crud, bcdt-hierarchical-tree; đọc [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md), [GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md). |
| Tạo biểu mẫu (FormDefinition, cột, binding) | bcdt-form-analyst | bcdt-form-builder |
| **Review nghiệp vụ** (đối chiếu yêu cầu–code–DB, gap analysis) | **bcdt-business-reviewer** | — |
| Excel, submission | bcdt-excel-generator | — |

**Đầy đủ:** TONG_HOP mục **3.2** (bảng), **3.3–3.5, 3.7** (block Cách giao AI), mục **6** (rà soát tài liệu).

---

**Workflow (bắt buộc):** Plan → Execute → Verify → Reflect. Rule **bcdt-agentic-workflow**: tách lập kế hoạch và thi hành; Plan trước (liệt kê bước, file, rủi ro, scope), rồi Execute theo đúng kế hoạch; Verify (build + checklist + **E2E khi sửa FE**, xem [E2E_VERIFY.md](E2E_VERIFY.md)) trước khi báo xong; Reflect (cập nhật TONG_HOP, gợi ý tiếp).

**Cách dùng:** Khi nhận task → **Plan:** đọc AI_CONTEXT.md (file này) + TONG_HOP 3.2, 3.3/3.5/3.7 → liệt kê bản kế hoạch → **Execute** theo block "Cách giao AI" → **Verify** (always-verify-after-work) → **Reflect** (cập nhật TONG_HOP nếu xong).

**Lệnh:** `/bcdt-task` (4 phase), `/bcdt-verify` (Verify), `/bcdt-next` (đề xuất), **`/bcdt-auto`** (tự động 4 phase). Ghi nhớ: rule **bcdt-memory** + [.cursor/PROJECT_MEMORY.md](.cursor/PROJECT_MEMORY.md). [AGENTS.md](../AGENTS.md).
