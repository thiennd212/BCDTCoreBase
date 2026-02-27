# Báo cáo Review nghiệp vụ – Module Workflow (B9)

**Ngày:** 2026-02-24  
**Agent:** bcdt-business-reviewer  
**Phạm vi:** Workflow 1–5 cấp (WF-*, FR-WF-*); cấu hình workflow, submit, approve/reject/revision, bulk approve.

---

## 1. Phạm vi review

- **Yêu cầu nguồn:** 01.YEU_CAU_HE_THONG (WF-01–WF-06, FR-WF-01–FR-WF-05), YEU_CAU_HE_THONG_TONG_HOP, B9_WORKFLOW.md.
- **Implementation:** WorkflowDefinitionsController, WorkflowStepsController, FormWorkflowConfigController, WorkflowInstancesController; SubmissionsController (submit, workflow-instance); IWorkflowDefinitionService, IWorkflowStepService, IFormWorkflowConfigService, IWorkflowExecutionService; BCDT_WorkflowDefinition, WorkflowStep, FormWorkflowConfig, WorkflowInstance, WorkflowApproval; FE WorkflowDefinitionsPage, nút Duyệt/Từ chối/Yêu cầu chỉnh sửa (Submissions/chi tiết).

---

## 2. Bảng đối chiếu (Yêu cầu ↔ Implementation)

| # | Yêu cầu | Nguồn | Implementation | Trạng thái |
|---|---------|-------|----------------|------------|
| 1 | Workflow phê duyệt 1–5 cấp theo biểu mẫu | WF-01, FR-WF-01 | WorkflowDefinition (TotalSteps 1–5); WorkflowStep (StepOrder, ApproverRoleId); FormWorkflowConfig (FormDefinitionId, WorkflowDefinitionId, OrganizationTypeId); API CRUD definitions, steps, form workflow config | **Đạt** |
| 2 | Reject / Revision (từ chối, yêu cầu sửa) | WF-02, FR-WF-02, FR-WF-03 | POST workflow-instances/{id}/reject → instance.Status=Rejected, submission.Status=Rejected; POST request-revision → submission.Status=Revision; WorkflowApproval ghi Action, Comments, ApproverId | **Đạt** |
| 3 | Approve (phê duyệt) | FR-WF-02 | POST workflow-instances/{id}/approve; tăng CurrentStep hoặc Completed; submission.Status=Approved khi đủ bước | **Đạt** |
| 4 | Bulk approve | FR-WF-04 | POST workflow-instances/bulk-approve (body WorkflowInstanceIds); BulkApproveAsync | **Đạt** |
| 5 | Submit submission (Draft → Submitted) | B9 | POST submissions/{id}/submit; tạo WorkflowInstance nếu form có config; submission.Status=Submitted | **Đạt** |
| 6 | Cấu hình workflow theo form | FR-WF-01 | FormWorkflowConfig CRUD; GET/POST/DELETE /forms/{formId}/workflow-config | **Đạt** |
| 7 | Lấy workflow instance của submission | B9 | GET submissions/{id}/workflow-instance | **Đạt** |
| 8 | Deadline tracking (theo dõi hạn nộp) | WF-03 | FormDefinition.DeadlineOffsetDays, AllowLateSubmission; kiểm tra khi submit (B10/ReportingPeriod); không thuộc riêng B9 | **Đạt** (phối hợp) |
| 9 | Auto-notification (thông báo) | WF-04 | Notification service (in-app, email mock); B11; có thể kích hoạt khi Pending/Approved/Rejected | **Một phần** (B11, không bắt buộc đủ trong B9) |
| 10 | Audit trail / Workflow history | WF-05, FR-WF-05 | BCDT_WorkflowApproval (Action, StepOrder, ApproverId, ApprovedAt, Comments); chưa có API GET lịch sử phê duyệt theo instance (vd GET workflow-instances/{id}/approvals) | **Một phần** (dữ liệu có, API đọc history chưa có) |
| 11 | FE WorkflowDefinitionsPage, nút duyệt/từ chối | TONG_HOP 4 | WorkflowDefinitionsPage (CRUD definition + steps); Form Config gắn workflow; Submissions/chi tiết có nút Duyệt/Từ chối/Yêu cầu chỉnh sửa | **Đạt** |
| 12 | Edge cases (form chưa config, status khác Draft) | B9 | Submit khi chưa config → 400; submit khi không Draft → 400; Approve/Reject khi không Pending → 400 | **Đạt** |

---

## 3. Gap

| Mức độ | Mô tả |
|--------|--------|
| **Minor** | **FR-WF-05 Workflow history (API đọc):** Bảng BCDT_WorkflowApproval đã ghi đầy đủ; chưa có endpoint GET trả về lịch sử phê duyệt (vd GET /api/v1/workflow-instances/{id}/approvals hoặc /history). FE muốn hiển thị "Ai duyệt, lúc nào, bước mấy" cần API này hoặc mở rộng WorkflowInstanceDto kèm danh sách approvals. |

Không có gap **Critical** hoặc **Major** đối với B9 và FR-WF-01–FR-WF-04 trong MVP.

---

## 4. Mâu thuẫn / Rủi ro

- **Không phát hiện mâu thuẫn** giữa tài liệu B9 và code (API, entity, luồng submit → approve/reject/revision).
- **Rủi ro nhỏ:** ApproverRoleId trong WorkflowStep – cần đảm bảo user hiện tại có role tương ứng mới được gọi approve; có thể đã kiểm tra trong WorkflowExecutionService hoặc policy.

---

## 5. Khuyến nghị

| Ưu tiên | Khuyến nghị |
|---------|-------------|
| **P2** | (Tùy chọn) Thêm API lịch sử phê duyệt: GET /api/v1/workflow-instances/{id}/approvals (hoặc /history) trả danh sách WorkflowApproval (StepOrder, Action, ApproverId, ApprovedAt, Comments) để FE hiển thị timeline. |
| **P3** | Giữ checklist "Kiểm tra cho AI" trong B9_WORKFLOW.md mục 7.1; khi sửa workflow tiếp tục chạy đủ bước và báo Pass/Fail. |

**Kết luận:** Module Workflow (B9) **đạt đủ yêu cầu MVP** cho WF-01, WF-02, FR-WF-01–FR-WF-04 và tích hợp submission status. Gap ở mức Minor (API đọc workflow history/approvals); không ảnh hưởng nghiệm thu Phase 3.
