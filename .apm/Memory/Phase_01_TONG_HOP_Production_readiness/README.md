# Phase 1 – Điều phối theo TONG_HOP và Production readiness

Phase đầu tiên của APM BCDT: điều phối công việc theo [Implementation Plan](../../Implementation_Plan.md), bám TONG_HOP 3.1/3.9 (ưu tiên Prod) và 3.7 (tùy chọn).

## Tasks

| Task | Title | Agent | Depends on |
|------|--------|-------|-------------|
| 1.1 | Theo dõi ưu tiên 1 (Prod) và thực hiện theo block Cách giao AI | Agent_Orchestration | — |
| 1.2 | Rà RUNBOOK 10 và REVIEW_PRODUCTION_CA_NUOC khi chuẩn bị go-live | Agent_Orchestration | Task 1.1 |
| 1.3 | (Tùy chọn) Thực hiện công việc tùy chọn từ TONG_HOP 3.7 | Agent_Orchestration | Task 1.1 |

## Memory logs

- [Task_1_1_Theo_doi_uu_tien_1_Prod.md](Task_1_1_Theo_doi_uu_tien_1_Prod.md)
- [Task_1_2_Ra_RUNBOOK_10_REVIEW_PRODUCTION.md](Task_1_2_Ra_RUNBOOK_10_REVIEW_PRODUCTION.md)
- [Task_1_3_Cong_viec_tuy_chon_TONG_HOP_3_7.md](Task_1_3_Cong_viec_tuy_chon_TONG_HOP_3_7.md)

## BCDT protocol (áp dụng mọi task)

- **Scope:** [AI_WORK_PROTOCOL](../../../memory/AI_WORK_PROTOCOL.md) §1 – chỉ sửa file trong phạm vi task (BE/FE/Docs/SQL).
- **MUST-ASK:** §2.1 – RLS, Middleware, Hangfire, Workbook flow, Dashboard/Replica, SQL production → dừng, impact analysis trước.
- **DECISIONS:** §2.2 & [DECISIONS.md](../../../memory/DECISIONS.md) §5 – thay đổi kiến trúc, RLS, workbook, Hangfire, replica, verify gate → ghi decision.
- **Verify:** §4 – build (tắt BCDT.Api trước), E2E nếu sửa FE, Postman nếu sửa API; §5 completion criteria.

## Nguồn sự thật

- [TONG_HOP](../../../docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) mục 3.1, 3.2, 3.7, 3.9
- [RUNBOOK](../../../docs/RUNBOOK.md) mục 6.1 (build), 10 (Production)
- [REVIEW_PRODUCTION_CA_NUOC](../../../docs/REVIEW_PRODUCTION_CA_NUOC.md)
- [project_state](../../../memory/project_state.md)
