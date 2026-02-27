# BCDT – APM Memory Root

**Memory Strategy:** Dynamic-MD  
**Project Overview:** Plan điều phối BCDT theo snapshot/state: ưu tiên TONG_HOP (production cả nước, tùy chọn 3.7); tuân AI_WORK_PROTOCOL; task → tài liệu + Agent/Skill theo TONG_HOP 3.2 và block "Cách giao AI". Nguồn sự thật: [AI_PROJECT_SNAPSHOT](../../docs/AI_PROJECT_SNAPSHOT.md), [TONG_HOP](../../docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [AI_WORK_PROTOCOL](../../memory/AI_WORK_PROTOCOL.md), [DECISIONS](../../memory/DECISIONS.md), [project_state](../../memory/project_state.md).

---

## Index

| Mục | Mô tả |
|-----|--------|
| [Implementation Plan](../Implementation_Plan.md) | Plan điều phối (Phase 1, Tasks 1.1–1.3) |
| [BCDT rules](#bcdt-rules--protocol) | Scope, MUST-ASK, verify (AI_WORK_PROTOCOL) |
| [Decision triggers](#decision-triggers) | Khi nào ghi DECISIONS.md |
| [Phase 1](#phase-1--điều-phối-theo-tong_hop-và-production-readiness) | Điều phối TONG_HOP & Production readiness |

---

## BCDT rules & protocol

Mọi task APM phải tuân [memory/AI_WORK_PROTOCOL.md](../../memory/AI_WORK_PROTOCOL.md):

- **Scope (§1):** Chỉ sửa file trong phạm vi task (BE `src/BCDT.*`, FE `src/bcdt-web/src`, Docs `docs/`, `memory/`, SQL `docs/script_core/sql/`). Cấm refactor diện rộng, đổi middleware/Auth/RLS/schema “tiện tay”.
- **MUST-ASK (§2.1):** Nếu chạm RLS/session context, Middleware, Hangfire jobs, Workbook flow, Dashboard/Replica, SQL production → dừng, yêu cầu impact analysis trước khi sửa.
- **DECISION REQUIRED (§2.2):** Thay đổi kiến trúc, RLS, workbook workflow, Hangfire Prod, replica/DbContext, verify gate → bắt buộc ghi [memory/DECISIONS.md](../../memory/DECISIONS.md).
- **Verify (§4):** Trước khi báo xong: build BE (tắt BCDT.Api trước); nếu sửa FE → E2E `npm run test:e2e` (BE 5080); Postman khi sửa API. Completion (§5): task ID, file list, verify result, DECISIONS nếu có, project_state nếu >1 phiên.

---

## Decision triggers

Ghi entry vào [memory/DECISIONS.md](../../memory/DECISIONS.md) khi thay đổi thuộc nhóm (theo DECISIONS.md §5):

- RLS / session context (middleware, SP, policy, 503)
- Hangfire jobs đọc/ghi bảng RLS hoặc đổi context pattern
- Workbook flow (contract, thứ tự sync, resolver/binding)
- Dashboard / replica / DbContext strategy
- Production/deployment (env, timeout, rate limit, CORS, JWT, secrets)
- Verify gates (build/E2E/Postman)
- DB schema/migrations có rủi ro production

---

## Phase 1 – Điều phối theo TONG_HOP và Production readiness

| Task | Mô tả | Log |
|------|--------|-----|
| Task 1.1 | Theo dõi ưu tiên 1 (Prod), block Cách giao AI 3.9, verify, cập nhật TONG_HOP | [Task_1_1_Theo_doi_uu_tien_1_Prod.md](Phase_01_TONG_HOP_Production_readiness/Task_1_1_Theo_doi_uu_tien_1_Prod.md) |
| Task 1.2 | Rà RUNBOOK 10 & REVIEW_PRODUCTION_CA_NUOC khi go-live (Depends on 1.1) | [Task_1_2_Ra_RUNBOOK_10_REVIEW_PRODUCTION.md](Phase_01_TONG_HOP_Production_readiness/Task_1_2_Ra_RUNBOOK_10_REVIEW_PRODUCTION.md) |
| Task 1.3 | (Tùy chọn) Công việc tùy chọn TONG_HOP 3.7 (Depends on 1.1) | [Task_1_3_Cong_viec_tuy_chon_TONG_HOP_3_7.md](Phase_01_TONG_HOP_Production_readiness/Task_1_3_Cong_viec_tuy_chon_TONG_HOP_3_7.md) |

**Phase summary:** *(sẽ cập nhật khi kết thúc Phase 1)*
