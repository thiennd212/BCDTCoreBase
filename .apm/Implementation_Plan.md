# BCDT – APM Implementation Plan (Điều phối)

**Memory Strategy:** Dynamic-MD
**Last Modification:** Manager Agent 1 – Task 1.1 marked Completed (retroactive: Prod-1..15 done outside APM by 2026-02-26).
**Project Overview:** Plan điều phối công việc BCDT dựa trên snapshot và state hiện tại: ưu tiên theo TONG_HOP (theo dõi triển khai production cả nước, công việc tùy chọn 3.7); tuân thủ AI_WORK_PROTOCOL (scope, verify, DECISIONS); task → tài liệu + Agent/Skill theo TONG_HOP 3.2 và block "Cách giao AI" (3.3, 3.5, 3.7). Không khám phá lại repo — nguồn sự thật: docs/AI_PROJECT_SNAPSHOT.md, memory/AI_WORK_PROTOCOL.md, memory/DECISIONS.md, memory/project_state.md.

---

## Phase 1: Điều phối theo TONG_HOP và Production readiness

### Task 1.1 – Theo dõi ưu tiên 1 (Prod) và thực hiện theo block Cách giao AI – Agent_Orchestration

- **Objective:** Lấy ưu tiên 1 từ TONG_HOP 3.1/3.9 (triển khai production cả nước); thực hiện theo block "Cách giao AI" tương ứng trong TONG_HOP mục 3.9; tuân thủ AI_WORK_PROTOCOL; verify trước khi báo xong; cập nhật TONG_HOP khi xong (bcdt-update-tong-hop-after-task).
- **Output:** Công việc ưu tiên 1 hoàn thành (hoặc xác nhận đã xong); TONG_HOP cập nhật; checklist/verify Pass.
- **Guidance:** Đọc docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md mục 3.1, 3.2, 3.9. Trước khi sửa code: tắt process BCDT.Api (RUNBOOK 6.1). Khi sửa RLS/Hangfire/workbook/Dashboard: MUST-ASK per AI_WORK_PROTOCOL §2.1; thay đổi DECISION REQUIRED → ghi memory/DECISIONS.md. Verify: build (BE), E2E khi sửa FE (npm run test:e2e, BE 5080), Postman/checklist "Kiểm tra cho AI" theo task.

**Steps:**
1. Đọc TONG_HOP 3.1 (ưu tiên 1) và 3.9 (bảng Prod, block "Cách giao AI" Prod).
2. Xác định task cụ thể (theo dõi Prod = rà RUNBOOK 10 / REVIEW_PRODUCTION_CA_NUOC; hoặc task còn lại trong 3.9 nếu có).
3. Thực hiện theo block "Cách giao AI" tương ứng; bám scope AI_WORK_PROTOCOL §1 (allowed edits, disallowed, MUST-ASK).
4. Verify theo always-verify-after-work (build, checklist, E2E nếu sửa FE); báo Pass/Fail từng bước.
5. Khi xong: cập nhật TONG_HOP theo rule bcdt-update-tong-hop-after-task (mục 2.1, 2.2, 3, 4, 5, 8, Version).

---

### Task 1.2 – Rà RUNBOOK 10 và REVIEW_PRODUCTION_CA_NUOC khi chuẩn bị go-live – Agent_Orchestration

- **Objective:** Khi User/Stakeholder chuẩn bị go-live, rà docs/RUNBOOK.md mục 10 (Production) và docs/REVIEW_PRODUCTION_CA_NUOC.md; xác nhận checklist R1–R15 (Prod-1..Prod-15) và biến môi trường bắt buộc; ghi chú điểm cần User thao tác ngoài IDE (env, backup, LB).
- **Output:** Báo cáo/checklist ngắn xác nhận RUNBOOK 10 + REVIEW_PRODUCTION đã rà; liệt kê bước cần User/ops thực hiện.
- **Guidance:** Tham chiếu docs/AI_PROJECT_SNAPSHOT.md §7 (Active work), memory/project_state.md (Active sprint goal). **Depends on: Task 1.1 Output** (ưu tiên 1 đã xử lý hoặc xác nhận trạng thái).

**Steps:**
1. Đọc RUNBOOK mục 10 (10.1 biến môi trường, 10.2–10.5 checklist, backup, dữ liệu trong nước).
2. Đọc REVIEW_PRODUCTION_CA_NUOC (R1–R15); đối chiếu với trạng thái đã ghi trong TONG_HOP (Prod-1..Prod-15 đã xong).
3. Liệt kê bước còn lại hoặc cần xác nhận khi go-live (env, Hangfire/Redis, RLS, CORS, backup).
4. Ghi kết quả rà soát (file ngắn hoặc mục trong memory/project_state.md); nếu có hành động ngoài IDE thì ghi rõ cho User/Manager.

---

### Task 1.3 – (Tùy chọn) Thực hiện công việc tùy chọn từ TONG_HOP 3.7 – Agent_Orchestration

- **Objective:** Nếu User chọn công việc tùy chọn từ TONG_HOP mục 3.7 (bảng ưu tiên, block "Cách giao AI" tương ứng): thực hiện theo đúng tài liệu, Agent/Skill trong TONG_HOP 3.2; verify và cập nhật TONG_HOP khi xong.
- **Output:** Công việc tùy chọn hoàn thành; TONG_HOP cập nhật; verify Pass.
- **Guidance:** TONG_HOP 3.2 (bảng Task → Tài liệu · Rules · Agent · Skill); 3.7 (ưu tiên tùy chọn, block Cách giao AI). Áp dụng cùng AI_WORK_PROTOCOL và verify gates như Task 1.1. **Depends on: Task 1.1 Output** (ưu tiên 1 đã xử lý hoặc không áp dụng).

**Steps:**
1. Xác định công việc tùy chọn từ TONG_HOP 3.7 (vd. review nghiệp vụ module; task khác trong bảng).
2. Đọc tài liệu bắt buộc và block "Cách giao AI" tương ứng; gán đúng Agent/Skill theo TONG_HOP 3.2.
3. Thực hiện theo block; tuân thủ scope và MUST-ASK (AI_WORK_PROTOCOL).
4. Verify (build, E2E nếu FE, Postman/checklist); báo Pass/Fail từng bước.
5. Khi xong: cập nhật TONG_HOP theo bcdt-update-tong-hop-after-task.

---

## Cross-agent & process

- **Agent assignment:** Tất cả task Phase 1 gán **Agent_Orchestration** (điều phối theo TONG_HOP). Khi Task 1.3 chọn công việc cụ thể (vd. review nghiệp vụ), Manager có thể gán lại theo TONG_HOP 3.2 (vd. bcdt-business-reviewer).
- **Process requirements:** Mọi task phải tuân AI_WORK_PROTOCOL (scope §1, MUST-ASK §2.1, DECISIONS §2.2, verify §4); completion criteria §5 (traceability, file list, verify result, DECISIONS nếu có, project_state nếu >1 phiên).
- **Nguồn sự thật:** docs/AI_PROJECT_SNAPSHOT.md, docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md, memory/AI_WORK_PROTOCOL.md, memory/DECISIONS.md, memory/project_state.md.
