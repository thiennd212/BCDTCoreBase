# BCDT – Sprint Roadmap (Post-MVP, Pre-Go-Live)

**Lập bởi:** PM Agent | **Ngày:** 2026-02-27
**Bối cảnh:** Dự án đang trong giai đoạn tối ưu nghiệp vụ, UX/UI, hiệu năng, bảo mật trước go-live.
**Nguồn:** TONG_HOP 3.7/3.9 + project_state.md + business review gaps (8 module)

---

## Tổng quan Roadmap

| Sprint | Tên | Trụ cột | Thời gian ước | Effort |
|--------|-----|---------|--------------|--------|
| **Sprint 1** | Bảo mật & Nền tảng kiểm thử | Bảo mật + Quality | ~2 tuần | L |
| **Sprint 2** | Nghiệp vụ – Fix Minor Gaps | Nghiệp vụ | ~2 tuần | M |
| **Sprint 3** | UX/UI Overhaul | UX/UI | ~2 tuần | L |
| **Sprint 4** | Hiệu năng & Stress Test | Hiệu năng | ~1.5 tuần | M |

**Thứ tự bắt buộc:** Sprint 1 (bảo mật) → Sprint 2+3 có thể song song (khác layer) → Sprint 4 sau khi Sprint 2+3 ổn định.

---

## Sprint 1 – Bảo mật & Nền tảng kiểm thử

**Goal:** Khắc phục rủi ro bảo mật tồn tại (JWT localStorage) + xây dựng quality gate tự động (CI/CD + unit tests) trước khi phát triển thêm feature.

**Nguồn rủi ro:** `memory/project_state.md` – explicitly flagged.

| # | Task | Effort | Agent | MUST-ASK |
|---|------|--------|-------|----------|
| S1.1 | Fix JWT token storage: localStorage → memory/httpOnly cookie | M | Agent_Security + Agent_Backend + Agent_Frontend | ⚠️ YES |
| S1.2 | Fix Auth Minor gaps: policy permission + refresh token rotation (B1-B3 review) | S | Agent_Backend | — |
| S1.3 | CI/CD pipeline: GitHub Actions – build BE + build FE + E2E gate | M | Agent_DevOps | — |
| S1.4 | Backend unit tests: cover FormService, WorkflowService, SubmissionService | L | Agent_Backend | — |

**Dependencies:** S1.1 phải xong trước S1.2 (cùng auth flow). S1.3 + S1.4 song song được.
**Quality gate:** TechLead → Security (bắt buộc S1.1) → QA → Docs

---

## Sprint 2 – Nghiệp vụ: Fix Minor Gaps

**Goal:** Xử lý các gap Minor từ business review + thêm tính năng nghiệp vụ thiếu.

**Nguồn:** Business review reports 8/8 module (2026-02-24).

| # | Task | Effort | Agent | Gap source |
|---|------|--------|-------|-----------|
| S2.1 | B10: CK-02 – Auto-create reporting period cho form có lịch | S | Agent_Backend | B10 review |
| S2.2 | B10: FR-TH-02/03 – Tổng hợp theo kỳ và theo đơn vị con | M | Agent_Backend | B10 review |
| S2.3 | Submission: Validation trước submit (kiểm tra required cells) | S | Agent_Backend | Submission review |
| S2.4 | Form: Nhân bản form (Clone FormDefinition + Sheets + Columns) | M | Agent_Backend + Agent_Frontend | B7-B8 review |
| S2.5 | ORG-05: UserDelegation – thiết kế + implement | L | Agent_BA → Agent_SA → Agent_Backend + Agent_Frontend | B4-B5 review |

**Dependencies:** S2.1 + S2.2 song song. S2.3 + S2.4 song song. S2.5 cần Agent_BA → Agent_SA trước.
**Ghi chú:** S2.5 (UserDelegation) có thể chuyển sang Sprint sau nếu effort lớn hơn dự kiến.

---

## Sprint 3 – UX/UI Overhaul

**Goal:** Cải thiện trải nghiệm người dùng trên các màn hình phức tạp nhất.

**Nguồn:** FormConfigPage.tsx (111KB), SubmissionDataEntryPage, Dashboard feedback.

| # | Task | Effort | Agent | Lý do |
|---|------|--------|-------|-------|
| S3.1 | FormConfigPage split: tách 111KB thành sub-components | L | Agent_Frontend | Performance + maintainability |
| S3.2 | SubmissionDataEntryPage UX: loading state, error recovery Fortune Sheet | M | Agent_Frontend | Fragile area |
| S3.3 | Dashboard UX: filter theo kỳ báo cáo, export Excel/PDF | M | Agent_Frontend + Agent_Backend | Business value |
| S3.4 | Error handling UX: thông báo lỗi user-friendly toàn app (500, 401, 403, 422) | S | Agent_Frontend | UX consistency |
| S3.5 | Loading & empty states: skeleton, empty page khi không có dữ liệu | S | Agent_Frontend | UX polish |

**Dependencies:** S3.1 phải trước S3.2 (cùng FormConfig area). S3.3 + S3.4 + S3.5 song song.
**Sprint 3 có thể chạy song song Sprint 2** (khác layer: FE vs BE).

---

## Sprint 4 – Hiệu năng & Stress Test

**Goal:** Xác nhận hiệu năng với tải thực tế nhiều người dùng + tối ưu điểm yếu còn lại.

| # | Task | Effort | Agent | Mục tiêu |
|---|------|--------|-------|----------|
| S4.1 | Load test: concurrent users (10-50) trên API nặng (workbook-data, submit, aggregate) | M | Agent_QA + Agent_DevOps | Xác nhận < 3s p95 |
| S4.2 | BuildWorkbookFromSubmissionService: profiling + tối ưu thêm nếu bottleneck | M | Agent_Backend | Fragile area |
| S4.3 | Fortune Sheet rendering: performance với form có >100 dòng/cột | M | Agent_Frontend | UX + perf |
| S4.4 | Dashboard: performance với dữ liệu lớn (>1000 submissions) | S | Agent_Backend | Scale test |

**Dependencies:** Sprint 4 sau Sprint 2+3 (cần feature ổn định để test đúng).

---

## Backlog (chưa schedule)

| Item | Effort | Ghi chú |
|------|--------|---------|
| FormRow.IndicatorId Phase 3 – hàng từ danh mục chỉ tiêu | M | Tùy nghiệp vụ quyết định cần không |
| Chữ ký số (Digital Signature module) | L | Module đã định nghĩa trong Domain nhưng chưa implement |
| Email notification thật (hiện là mock) | M | Cần SMTP config + template |
| Form preview độc lập (không cần submit) | S | Gap từ B7-B8 review |

---

## Risk Register

| Rủi ro | Severity | Mitigation |
|--------|----------|-----------|
| JWT localStorage fix ảnh hưởng FE auth flow | 🔴 HIGH | MUST-ASK + Agent_Security review + E2E full re-run |
| UserDelegation (S2.5) phức tạp hơn dự kiến | 🟡 MEDIUM | Agent_SA design trước; tách phase nếu cần |
| FormConfigPage split làm lỗi Form Config UX | 🟡 MEDIUM | E2E tests + UAT riêng cho Form Config |
| Load test phát hiện bottleneck mới | 🟡 MEDIUM | Có Sprint 4 dự phòng để xử lý |
