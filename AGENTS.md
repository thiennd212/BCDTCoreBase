# Agent – Hướng dẫn cho AI (BCDT)

Tài liệu ngắn cho AI Agent. **Đọc kèm** [docs/AI_CONTEXT.md](docs/AI_CONTEXT.md), [.cursor/PROJECT_MEMORY.md](.cursor/PROJECT_MEMORY.md), rules `.cursor/rules/`. **Rule bcdt-memory** (alwaysApply) đã gói ghi nhớ + tự động. **Workflow:** Plan → Execute → Verify → Reflect (rule **bcdt-agentic-workflow**).

---

## Agentic workflow: Plan → Execute → Verify → Reflect

Tách **lập kế hoạch** và **thi hành** để giảm sai. Chi tiết: rule **bcdt-agentic-workflow** (alwaysApply).

| Phase | Hành động |
|--------|------------|
| **Plan** | Đọc ngữ cảnh (AI_CONTEXT, TONG_HOP 3.2, 3.3/3.5/3.7). Liệt kê: task con, bước, file/agent/skill, rủi ro, scope (làm gì / không làm gì). **Không** sửa code trước khi có bản kế hoạch. |
| **Execute** | Làm **đúng theo** từng bước trong Plan; không thêm scope ngoài kế hoạch. |
| **Verify** | Build (tắt BCDT.Api trước) + checklist "Kiểm tra cho AI" / Postman; **E2E** khi sửa FE: `npm run test:e2e` trong `src/bcdt-web` (BE tại 5080), báo Pass/Fail từng spec; báo Pass/Fail từng bước. Fail → sửa rồi Verify lại. |
| **Reflect** | Ghi ngắn lỗi/kinh nghiệm; cập nhật TONG_HOP (nếu task thuộc TONG_HOP); cập nhật "Cách giao AI" cho task tiếp; trả lời user. |

---

## Ghi nhớ (project memory)

- **Task map:** TONG_HOP 3.2 (bảng), 3.3/3.5/3.7 (block "Cách giao AI"). Chi tiết: [.cursor/PROJECT_MEMORY.md](.cursor/PROJECT_MEMORY.md).
- **Verify:** Luôn build + checklist trước khi báo xong; tắt BCDT.Api trước build BE.
- **Tự động:** Làm theo command/block **không hỏi xác nhận** trừ khi thiếu thông tin bắt buộc.

---

## Khi bắt đầu task

1. **Plan trước:** Đọc [docs/AI_CONTEXT.md](docs/AI_CONTEXT.md) và [docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) mục **3.2** (chọn task, tài liệu/rule/agent/skill), mục **3.3, 3.5, 3.7** (block "Cách giao AI"). **Liệt kê bản kế hoạch** (bước, file, rủi ro, scope) trước khi Execute.
2. **Execute:** Làm đúng theo block "Cách giao AI" và theo bản kế hoạch đã nêu.
3. **Verify:** Rule always-verify-after-work (build + checklist, báo Pass/Fail).
4. **Reflect:** Cập nhật TONG_HOP khi xong (bcdt-update-tong-hop-after-task); đề xuất tiếp (bcdt-next-work-ai-prompt).

**Rules luôn áp dụng:** bcdt-agentic-workflow, always-verify-after-work, bcdt-project, bcdt-update-tong-hop-after-task, bcdt-next-work-ai-prompt.

---

## Commands (workflow nhanh)

| Lệnh | Mục đích |
|------|----------|
| **/bcdt-task** | BCDT theo 4 phase: **Plan** (ngữ cảnh + bản kế hoạch) → **Execute** (theo block "Cách giao AI") → **Verify** → **Reflect** (cập nhật TONG_HOP nếu xong). |
| **/bcdt-verify** | Chạy phase **Verify**: build, test cases (Kiểm tra cho AI), Postman; báo Pass/Fail từng bước. |
| **/bcdt-next** | Đề xuất công việc tiếp theo (ưu tiên 1) và block "Cách giao AI" copy-paste. |
| **/review** | Rà soát nhanh: build, git diff, gợi ý bước kiểm tra. |
| **/bcdt-auto** | Tự động 4 phase: Plan (ưu tiên 1 từ TONG_HOP 3.7 + kế hoạch) → Execute → Verify → Reflect (một lệnh trọn chu kỳ). |

---

## Hooks (long-running loop)

- **Stop hook** (`.cursor/hooks.json` + `.cursor/hooks/grind.mjs`): Khi agent dừng, nếu chưa đánh dấu xong (`.cursor/scratchpad.md` chưa có "DONE" hoặc "VERIFY PASS") và chưa vượt số lần lặp, agent nhận followup để tiếp tục (chạy verify, sửa lỗi). Dùng khi user muốn "chạy đến khi mọi test pass".
- **Cách dùng:** Sau khi verify Pass, ghi vào `.cursor/scratchpad.md` dòng `DONE` hoặc `VERIFY PASS` để hook không lặp nữa.

---

## Agents & Skills

- **Agents** (subagent): `.cursor/agents/` – bcdt-auth-expert, bcdt-org-admin, bcdt-hierarchical-data, bcdt-form-structure-indicators, bcdt-workflow-designer, **bcdt-business-reviewer** (review nghiệp vụ), …
- **Skills:** `.cursor/skills/` – bcdt-entity-crud, bcdt-api-endpoint, bcdt-hierarchical-tree, bcdt-form-structure, bcdt-workflow-config, …
- Bảng **Task → Agent/Skill** đầy đủ: [AI_CONTEXT.md mục 6](docs/AI_CONTEXT.md) và TONG_HOP mục 3.2.

---

## Build & verify

- **Backend:** Trước `dotnet build` luôn tắt process BCDT.Api (RUNBOOK mục 6.1). PowerShell: `Get-Process -Name "BCDT.Api" -ErrorAction SilentlyContinue | Stop-Process -Force`.
- **Verify:** Không báo xong trước khi chạy đủ checklist "Kiểm tra cho AI" (hoặc *_TEST_CASES.md) và báo Pass/Fail từng bước (rule always-verify-after-work).

---

## Cách dùng cho dự án (user / lập trình viên)

| Tình huống | Lệnh / hành động |
|------------|-------------------|
| **Làm một task cụ thể** (vd B12 P7, B4) | Gõ **`/bcdt-task`** rồi nêu tên task (hoặc “làm ưu tiên 1”). AI sẽ Plan → Execute → Verify → Reflect. |
| **Để AI tự chọn task và làm trọn chu kỳ** | Gõ **`/bcdt-auto`**. AI lấy ưu tiên 1 từ TONG_HOP 3.7, chạy 4 phase, cập nhật TONG_HOP khi xong. |
| **Chỉ chạy kiểm tra** (đã sửa code, cần build + checklist) | Gõ **`/bcdt-verify`**. AI chạy phase Verify (build, “Kiểm tra cho AI”, Postman), báo Pass/Fail. |
| **Cần đề xuất việc tiếp + block giao AI** | Gõ **`/bcdt-next`**. AI đưa ra ưu tiên 1 và block “Cách giao AI” copy-paste cho task đó. |
| **Rà soát nhanh** (build, diff, gợi ý test) | Gõ **`/review`**. |

**Luồng gợi ý:** Mở dự án → **`/bcdt-next`** (xem việc nên làm) → **`/bcdt-task`** + tên task hoặc **`/bcdt-auto`** (làm task) → khi xong, AI sẽ gợi ý `/bcdt-next` hoặc `/bcdt-auto` lần nữa. Task nằm trong [TONG_HOP](docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) mục 3.2, 3.7; block “Cách giao AI” ở mục 3.3, 3.5, 3.7.
