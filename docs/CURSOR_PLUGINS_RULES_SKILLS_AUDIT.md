# Rà soát Plugin, Rule, Skill, Agent – Cursor IDE & Project BCDT

**Ngày rà soát:** 2026-02-23  
**Phạm vi:** Cursor IDE (user + project BCDTCoreBase)

---

## 1. Tổng quan cài đặt

| Loại | Project (BCDTCoreBase) | User (Cursor) |
|------|-------------------------|---------------|
| **Plugins** | 1 (context7 trong `.cursor/settings.json`) | 2 (context7, parallel – từ cache) |
| **Rules** | 16 file `.mdc` trong `.cursor/rules/` (+ bcdt-postman-test-cases, **bcdt-memory**) | 1 rule từ plugin Parallel (citation-standards; plugin tắt ở project) |
| **Skills** | 15 (14 BCDT + ui-ux-pro-max) trong `.cursor/skills/` | 6 từ plugins (documentation-lookup, parallel-×4) + 5 trong `skills-cursor/` (create-rule, create-skill, create-subagent, update-cursor-settings, migrate-to-skills) |
| **Agents** | 16 trong `.cursor/agents/` (toàn BCDT domain) | (agents từ plugin nếu có – không thấy trong cache đã quét) |

**Ghi chú:** Skill/rule ở user còn có thể nằm ở `C:\Users\thien\.codex\skills\.system\` (skill-creator, skill-installer) – Cursor có thể load tùy cấu hình.

---

## 2. Plugins

### 2.1 Project – `.cursor/settings.json`

```json
{"plugins":{"context7-plugin":{"enabled":true}}}
```

- **context7-plugin:** bật – tra tài liệu thư viện (resolve-library-id, query-docs). Phù hợp khi cần docs React, .NET, v.v.

### 2.2 User (từ cache)

| Plugin | Nội dung chính |
|--------|-----------------|
| **context7** | Skill documentation-lookup; MCP Context7. Trùng với project (project bật ở scope project). |
| **parallel** | 4 skills: parallel-web-search, parallel-web-extract, parallel-deep-research, parallel-data-enrichment; 1 rule: citation-standards (trích dẫn khi dùng kết quả tìm kiếm). |

**Đánh giá:**

- **Phù hợp:** Context7 rất hợp với BCDT (stack .NET, React, DevExtreme, Excel) khi cần tra docs mới nhất.
- **Parallel:** Hữu ích khi cần research sâu hoặc enrich dữ liệu; rule citation-standards tránh “nói không nguồn”. Đã tắt ở project (`.cursor/settings.json`: `parallel-plugin.enabled: false`). Bật lại trong Cursor Settings → Features khi cần research; rule citation-standards không load khi plugin tắt.
- **Chồng chéo:** Context7 có ở cả project và user – không gây xung đột, chỉ lặp cấu hình.

---

## 3. Rules

### 3.1 Luôn áp dụng (alwaysApply: true)

| Rule | Mục đích |
|------|----------|
| **senior-fullstack-standards.mdc** | Chuẩn senior: SOLID, API, DB, test, security. |
| **bcdt-project.mdc** | Kiến trúc BCDT, naming, bảng chính, Don’t. |
| **bcdt-memory.mdc** | Ghi nhớ ngắn: stack, tắt BCDT.Api, TONG_HOP 3.2, verify trước xong, tự động không hỏi. (Tối ưu token.) |
| **always-verify-after-work.mdc** | Build + tự test trước khi báo xong; checklist; Postman; test cases. |
| **bcdt-update-tong-hop-after-task.mdc** | Khi xong task A/B/C → cập nhật TONG_HOP (mục 2.1–2.2, 3, 4, 5, 8, version). |
| **bcdt-next-work-ai-prompt.mdc** | Khi đề xuất công việc tiếp theo → bắt buộc có block “Cách giao AI” + test case + tự test. |

Hai rule cuối có `globs: docs/TONG_HOP*.md` nhưng vẫn alwaysApply → đúng ý: mỗi khi nói đến TONG_HOP hoặc “công việc tiếp theo” đều phải tuân thủ.

### 3.2 Theo ngữ cảnh (alwaysApply: false, có globs hoặc requestable)

| Rule | Globs / Ghi chú |
|------|------------------|
| **bcdt-ai-context.mdc** | (requestable) Đọc AI_CONTEXT + TONG_HOP mục 3.2, 3.3–3.5, 3.7 khi bắt đầu task. |
| **bcdt-frontend.mdc** | `**/*.tsx,**/*.ts` – React, Ant Design, DevExtreme, modal, tiếng Việt. |
| **bcdt-backend.mdc** | `**/*.cs` – EF Core, Dapper, Result, DisplayOrder. |
| **bcdt-api.mdc** | `**/Controllers/**/*.cs` – REST, ApiResponse, route. |
| **bcdt-database.mdc** | `**/*.sql` – BCDT_ prefix, cột bắt buộc, RLS, seed. |
| **bcdt-testing.mdc** | `**/*.Tests/**/*.cs`, `**/*.test.ts(x)`, `**/*.spec.tsx` – naming, A-A-A. |
| **bcdt-excel.mdc** | Excel/Spreadsheet paths, template, upload, hybrid. |
| **bcdt-hierarchical-data.mdc** | `**/*.tsx,**/*.ts,**/Controllers/**/*.cs,**/Services/**/*.cs` – all=true, buildTree, TreeSelect. |
| **bcdt-devexpress-nuget.mdc** | `nuget.config`, `**/*.csproj` – feed DevExpress công ty. |
| **bcdt-postman-test-cases.mdc** | `docs/postman/**`, `**/Controllers/**/*.cs`, `docs/de_xuat_trien_khai/*.md`, `**/*_TEST_CASES.md` – Postman collection (chuẩn bắt buộc), Test cases (checklist, *_TEST_CASES.md). Rule always-verify tham chiếu rule này. |

### 3.3 Rule từ plugin (user)

- **citation-standards.mdc** (Parallel): Khi trình bày kết quả web search → trích dẫn inline + Sources. alwaysApply: false.

### 3.4 Chồng chéo và phân vai

- **senior-fullstack-standards vs bcdt-backend / bcdt-api / bcdt-testing:** Senior là nguyên tắc chung (REST, DB, test); BCDT là chi tiết (route `/api/v1/`, BCDT_, FluentValidation). Bổ sung cho nhau, không trùng nội dung.
- **bcdt-backend (**.cs) vs bcdt-api (Controllers):** Cùng lúc áp dụng khi sửa Controller là chủ ý (backend = C#/service; api = REST/response).
- **bcdt-frontend vs always-verify:** Frontend mô tả cách làm (modal, DevTools, tiếng Việt); verify mô tả cách kiểm tra sau khi làm. Có nhắc lại DevTools/tiếng Việt nhưng vai trò khác nhau → chấp nhận được.
- **bcdt-update-tong-hop vs bcdt-next-work-ai-prompt:** Một cái “khi xong task thì cập nhật TONG_HOP”, một cái “khi đề xuất việc tiếp theo thì thêm Cách giao AI”. Bổ sung, không trùng.

**Kết luận rules:** Cấu trúc rõ, ít chồng chéo có hại. Số rule alwaysApply = 5 là hợp lý cho quy trình BCDT.

---

## 4. Skills

### 4.1 Project – BCDT domain

| Skill | Dùng khi |
|-------|----------|
| bcdt-api-endpoint | Tạo API / thêm endpoint REST. |
| bcdt-entity-crud | Tạo entity mới, CRUD đủ stack. |
| bcdt-form-builder | Định nghĩa form (FormDefinition, sheet, column, binding). |
| bcdt-form-structure | Form động, placeholder, merge header, IndicatorExpandDepth, lọc động (P8). |
| bcdt-hierarchical-tree | Hiển thị cây, all=true, buildTree, TreeSelect. |
| bcdt-react-page | Tạo trang React (DevExtreme, grid, hooks). |
| bcdt-sql-migration | Migration SQL (bảng, cột, index). |
| bcdt-seed-test-data | Seed dữ liệu test (Excel entry, MCP, PowerShell). |
| bcdt-test | Unit/integration test theo convention BCDT. |
| bcdt-hangfire-jobs | Hangfire, kỳ báo cáo, nhắc nộp. |
| bcdt-dashboard-charts | Dashboard, biểu đồ. |
| bcdt-external-api | Gọi API ngoài. |
| bcdt-workflow-config | Cấu hình workflow duyệt. |
| **ui-ux-pro-max** | UI/UX, design system (data CSV, nhiều stack). |

### 4.2 User – Plugin + skills-cursor

- **Context7:** documentation-lookup (tra docs thư viện).
- **Parallel:** parallel-web-search, parallel-web-extract, parallel-deep-research, parallel-data-enrichment.
- **skills-cursor:** create-rule, create-skill, create-subagent, update-cursor-settings, migrate-to-skills.

Không có trùng tên giữa project và user. BCDT = domain; user = công cụ chung (docs, research, cấu hình Cursor).

---

## 5. Agents (project)

Tất cả trong `.cursor/agents/`, tên trùng với subagent_type dùng trong MCP task:

- bcdt-form-structure-indicators, bcdt-excel-generator, bcdt-submission-processor  
- bcdt-data-binding, bcdt-hybrid-storage, bcdt-hierarchical-data, bcdt-org-admin  
- bcdt-digital-signature, bcdt-auth-extension, bcdt-notification, bcdt-reference-data  
- bcdt-auth-expert, bcdt-aggregation-builder, bcdt-form-analyst, bcdt-report-period, bcdt-workflow-designer, bcdt-business-reviewer  

Mỗi agent là “chuyên gia” một mảng, bên trong thường tham chiếu rule + skill (vd bcdt-form-structure-indicators → skill bcdt-form-structure; bcdt-hierarchical-data → rule bcdt-hierarchical-data + skill bcdt-hierarchical-tree). Rõ ràng, không chồng chéo vai trò.

---

## 6. Đánh giá tổng thể

### 6.1 Phù hợp

- **Quy trình:** always-verify + bcdt-update-tong-hop + bcdt-next-work-ai-prompt tạo vòng “làm → test → cập nhật TONG_HOP → đề xuất việc tiếp + Cách giao AI” rất nhất quán.
- **Domain:** Rules/Skills/Agents BCDT bám sát stack (.NET 8, React, DevExtreme, Excel, SQL Server) và tài liệu trong `docs/`, `de_xuat_trien_khai/`.
- **Phân tầng:** Rule (chuẩn) → Skill (workflow/code) → Agent (chuyên gia) rõ ràng; agent dùng skill, skill tham chiếu rule/doc.
- **Context7:** Rất phù hợp để tra docs .NET/React/DevExtreme khi implement hoặc refactor.

### 6.2 Chồng chéo (chấp nhận được)

- **Hierarchical:** Rule bcdt-hierarchical-data + skill bcdt-hierarchical-tree + agent bcdt-hierarchical-data: cùng chủ đề nhưng vai trò khác (convention / implementation / specialist). Giữ nguyên.
- **Form structure:** Skill bcdt-form-structure vs agent bcdt-form-structure-indicators: agent gọi skill. Đúng mô hình.
- **Backend/API/Testing:** Đã nêu ở mục 3.4.

### 6.3 Cải tiến đề xuất

1. **bcdt-ai-context:** Hiện “agent requestable”. Có thể trong **bcdt-project.mdc** (hoặc AI_CONTEXT.md) thêm một dòng: “Khi bắt đầu task BCDT, nên đọc docs/AI_CONTEXT.md và TONG_HOP mục 4.0 (rule bcdt-ai-context).” Để AI chủ động đọc ngữ cảnh hơn mà không cần user gọi rule.
2. **Chỉ mục Agent ↔ task:** Trong `docs/AI_CONTEXT.md` hoặc TONG_HOP mục 4.0, thêm bảng ngắn: Task B2 → bcdt-auth-expert; B6 → bcdt-org-admin; Form structure P8 → bcdt-form-structure-indicators; … Giúp chọn agent nhanh.
3. **Parallel plugin:** Nếu không dùng research/web-extract thường xuyên, có thể tắt plugin Parallel trong Cursor Settings → Features để giảm số skill/rule trong list; bật lại khi cần.
4. **Rule theo file:** Các rule globs đã gọn (backend/api/database/frontend/test/excel/hierarchical/devexpress). Nếu sau này thêm rule mới, ưu tiên glob hẹp (vd chỉ `**/Services/*Excel*.cs`) để tránh load dư.
5. **Kiểm tra trùng rule khi thêm:** Khi thêm rule mới, so nhanh với senior-fullstack-standards và bcdt-project để tránh lặp nguyên tắc chung (API, security, naming).

---

## 7. Agentic workflows (Cursor commands + hooks)

| Thành phần | Trạng thái | Mô tả |
|------------|------------|--------|
| **.cursor/commands/** | ✅ Đã cấu hình | `/bcdt-task`, `/bcdt-verify`, `/bcdt-next`, `/review`, **`/bcdt-auto`** (tự động ưu tiên 1→làm→verify→cập nhật TONG_HOP). Commands rút gọn, tham chiếu docs/rules (tối ưu token). |
| **.cursor/hooks.json** | ✅ Đã cấu hình | Stop-hook: gọi `node .cursor/hooks/grind.mjs` khi agent dừng; trả followup nếu chưa DONE/VERIFY PASS (tối đa 5 lần). |
| **.cursor/hooks/grind.mjs** | ✅ Đã cấu hình | Script Node: đọc `.cursor/scratchpad.md`; nếu chưa có "DONE"/"PASS"/"VERIFY PASS" thì trả followup_message để agent tiếp tục verify. |
| **AGENTS.md** | ✅ Đã tạo | Hướng dẫn + **Ghi nhớ** (project memory), **Tự động** (không hỏi lại). Link PROJECT_MEMORY.md. |
| **.cursor/rules/bcdt-memory.mdc** | ✅ Đã tạo | Rule alwaysApply, ~500 chars: stack, build tắt BCDT.Api, TONG_HOP 3.2, verify trước xong, **tự động không hỏi**. Tối ưu token. |
| **.cursor/PROJECT_MEMORY.md** | ✅ Đã tạo | Ghi nhớ 5 ý: nguồn task, verify, cập nhật TONG_HOP, đề xuất + Cách giao AI, commands. Đọc khi cần. |

**Token:** Commands ngắn (tham chiếu docs); bcdt-memory 1 đoạn; hook followup rút gọn. **Tự động:** Commands ghi "Không hỏi xác nhận"; /bcdt-auto chạy trọn chu kỳ. **Ghi nhớ:** bcdt-memory (always) + PROJECT_MEMORY.md (khi bắt đầu task).

**Cách dùng:** `/bcdt-task`, `/bcdt-verify`, `/bcdt-next`, `/review`, **`/bcdt-auto`**. Hook tự chạy khi agent stop; cần Node.js cho grind.mjs.

---

## 8. Checklist nhanh sau rà soát

- [x] Plugin: Context7 bật (project); Parallel tùy nhu cầu.
- [x] Rules: 5 alwaysApply phù hợp; 9 rule theo glob/requestable rõ ràng.
- [x] Skills: BCDT đủ domain; user skills không trùng tên.
- [x] Agents: 16 BCDT, map subagent_type; agent dùng skill/rule đúng.
- [ ] (Tùy chọn) Thêm gợi ý đọc AI_CONTEXT trong bcdt-project hoặc AI_CONTEXT.md.
- [ ] (Tùy chọn) Thêm bảng Task → Agent trong AI_CONTEXT hoặc TONG_HOP 4.0.
- [x] Parallel plugin tắt ở project (settings.json); bật lại trong Settings nếu cần.

---

## 9. Phân tích sâu và cải tiến tối ưu

### 9.1 Sai tham chiếu mục trong tài liệu (ưu tiên cao)

Trong **TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md** hiện tại:
- **Mục 3.2** = Bảng "Tài liệu · Rules · Agent · Skill"
- **Mục 3.3, 3.4, 3.5** = Các block "Cách giao AI khi làm [Task]"
- **Mục 3.7** = Đề xuất công việc tiếp theo (bảng ưu tiên + block copy-paste)
- **Mục 4** = Rà soát BE vs FE (không chứa bảng Agent/Skill hay block Cách giao AI)

Nhiều file đang tham chiếu **"mục 4.5"**, **"mục 4.6"** (không tồn tại trong TONG_HOP):
- **AI_CONTEXT.md:** "Mục 4.5", "Mục 4.6", "TONG_HOP mục 4.5 và 6" → cần sửa thành **3.2** (bảng), **3.3 / 3.5 / 3.7** (block Cách giao AI).
- **KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md**, **B12_CHI_TIEU_CO_DINH_DONG.md**, **YEU_CAU_AI_MO_RONG_...**, **README** de_xuat_trien_khai, **RA_SOAT_VA_PHUONG_AN_...**: đều ghi "TONG_HOP mục 4.6" → sửa thành **3.3, 3.5 hoặc 3.7** (block Cách giao AI cho B12/P8).

**Hành động:** Sửa tất cả tham chiếu "4.5" → "3.2", "4.6" → "3.3" (hoặc "3.5 / 3.7" tùy ngữ cảnh) để AI và người đọc tìm đúng mục.

---

### 9.2 Tải token từ rules (alwaysApply)

| Rule | Kích thước (ký tự) | Ghi chú |
|------|--------------------|---------|
| always-verify-after-work | ~11 700 | Lớn nhất; chứa bảng kiểm tra, Postman, test cases, DevTools. |
| bcdt-update-tong-hop-after-task | ~3 000 | Hợp lý. |
| bcdt-next-work-ai-prompt | ~2 700 | Hợp lý. |
| bcdt-project | ~1 500 | Ngắn, ổn. |
| senior-fullstack-standards | ~1 350 | Ngắn, ổn. |

**Tổng ~20k ký tự** cho 5 rule alwaysApply mỗi turn → ảnh hưởng token/chi phí.

**Đã áp dụng (2026-02-23):**
- **always-verify:** Đã tách phần "Postman collection" và "Test cases" sang rule **bcdt-postman-test-cases** (globs: `docs/postman/**`, `**/Controllers/**/*.cs`, `docs/de_xuat_trien_khai/*.md`, `**/*_TEST_CASES.md`). always-verify rút gọn, tham chiếu rule mới; giảm token mỗi turn.
- **Không** chuyển always-verify sang "Agent Decides" – giữ bắt buộc tự verify.

---

### 9.3 Rule theo glob – kích thước khi được kích hoạt

| Rule | Chars | Globs | Ghi chú |
|------|-------|-------|---------|
| bcdt-frontend | ~15 500 | **/*.tsx, **/*.ts | Rất lớn khi làm FE; nội dung modal, DevTools, tiếng Việt cần thiết. |
| bcdt-excel | ~4 800 | Excel/Spreadsheet, Services*Excel* | Ổn. |
| bcdt-hierarchical-data | ~3 500 | tsx, ts, Controllers, Services | Ổn. |
| bcdt-testing | ~3 100 | *Tests*, *test.ts(x), *spec.tsx | Ổn. |
| bcdt-update-tong-hop, bcdt-next-work | (always) | docs/TONG_HOP*.md | Đã tính ở 8.2. |

**Kết luận:** bcdt-frontend dài nhưng chỉ load khi mở file .tsx/.ts → chấp nhận được. Không nên cắt bớt nội dung checklist Modal/DevTools vì đây là yêu cầu chất lượng bàn giao.

---

### 9.4 Gap: Bảng tham chiếu AI (TONG_HOP 3.2) thiếu dòng

Bảng **3.2** hiện có: Week 16, Week 17, Refresh token FE, Phân cấp Menu. Thiếu:
- **Bổ sung Postman / Swagger** (ưu tiên 2 tùy chọn trong 3.7): chưa có dòng tương ứng với Tài liệu · Rules · Agent · Skill.

**Đề xuất:** Thêm một dòng vào bảng 3.2:
| Bổ sung Postman/Swagger | RUNBOOK, postman/README, B11/B10, mục 5.4–5.5 TONG_HOP | always-verify, bcdt-api | — | — |

---

### 9.5 Agent – kích thước và tham chiếu

| Agent | Chars | Ghi chú |
|-------|-------|---------|
| bcdt-data-binding | ~11 000 | Lớn nhất; nội dung binding 7 loại, Resolver. Giữ nguyên vì domain phức tạp. |
| bcdt-form-structure-indicators | ~4 600 | Rõ ràng, tham chiếu skill + doc. |
| bcdt-hierarchical-data | ~3 900 | Ổn. |
| Các agent còn lại | 1 600–2 800 | Ổn. |

Không cần tách agent; có thể sau này thêm "Phụ lục" link ra doc thay vì mở rộng nội dung trong agent.

---

### 9.6 Một nguồn sự thật cho "Cách giao AI"

Theo **RA_SOAT_VA_PHUONG_AN_CAU_TRUC_LAI_TAI_LIEU.md**, "Cách giao AI" nên ở **một nơi duy nhất** để tránh lặp và lệch. Hiện tại đúng là **TONG_HOP** đang là nơi đó (các block trong 3.3, 3.4, 3.5, 3.7). Các file khác (KE_HOACH_..., B12_..., YEU_CAU_AI_...) chỉ nên **trỏ tới** TONG_HOP (mục 3.2, 3.3, 3.5, 3.7), không copy nguyên block. Đã kiểm tra: các file đó đều ghi "Cách giao AI: TONG_HOP mục 4.6" → sau khi sửa thành "mục 3.3 / 3.5 / 3.7" sẽ thống nhất.

---

### 9.7 Bảng cải tiến ưu tiên (hành động cụ thể)

| Ưu tiên | Hành động | File / vị trí | Trạng thái đề xuất |
|---------|-----------|----------------|---------------------|
| **Cao** | Sửa tham chiếu mục sai (4.5/4.6 → 3.2/3.3, 3.5, 3.7) | AI_CONTEXT.md, bcdt-ai-context.mdc, CURSOR audit 3.2 | Áp dụng ngay |
| **Cao** | Thêm gợi ý rule bcdt-ai-context trong bcdt-project | bcdt-project.mdc dòng đầu | Áp dụng ngay |
| **Trung bình** | Thêm dòng "Bổ sung Postman/Swagger" vào bảng 3.2 | TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md | Áp dụng |
| **Trung bình** | Sửa "mục 4.6" → "mục 3.3 hoặc 3.5, 3.7" trong toàn bộ docs | KE_HOACH_..., B12_..., YEU_CAU_AI_..., README de_xuat, RÀ_SOÁT_..., DE_XUAT_TRIEN_KHAI_MO_RONG, RA_SOAT_DANH_GIA_... | Áp dụng (batch) |
| **Thấp** | ~~Rút gọn always-verify~~ | ~~always-verify-after-work.mdc~~ | ✅ **Đã xong:** rule bcdt-postman-test-cases tạo, always-verify rút gọn. |
| **Thấp** | ~~Tắt plugin Parallel~~ | `.cursor/settings.json` | ✅ **Đã xong:** `parallel-plugin.enabled: false`. Nếu không có hiệu lực (plugin id khác hoặc cấu hình user-level), tắt thủ công Cursor Settings → Features. |
| **Thấp** | Bảng Task → Agent đã có trong AI_CONTEXT mục 6 | Không thay đổi | Đã đủ |

---

*File này nằm trong repo để lần sau rà soát hoặc onboard AI/dev mới.*
