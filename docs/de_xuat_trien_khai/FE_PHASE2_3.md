# FE Phase 2–3 – Trang Biểu mẫu, Báo cáo, Workflow, Kỳ báo cáo, Dashboard

Bổ sung Frontend cho Phase 2–3 theo [TONG_HOP mục 9](..//TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md). Backend đã đủ API; chỉ triển khai FE (React, Vite, Ant Design) trong `src/bcdt-web`.

---

## 1. Phạm vi

| Nhóm | Trang / Tính năng | API (BE đã có) |
|------|--------------------|----------------|
| Kỳ báo cáo | Trang Kỳ báo cáo: list, tạo, sửa, xóa; lọc theo frequency, year, status | GET/POST/PUT/DELETE /api/v1/reporting-periods, GET /api/v1/reporting-frequencies |
| Dashboard | Trang Dashboard: thống kê admin (số submission theo trạng thái/kỳ/form), nhiệm vụ user (drafts, deadlines, pending approvals) | GET /api/v1/dashboard/admin/stats, GET /api/v1/dashboard/user/tasks |
| Biểu mẫu | Trang Biểu mẫu: list form definitions, xem versions | GET /api/v1/forms, GET /api/v1/forms/{id}/versions |
| Báo cáo / Submissions | Trang Báo cáo: list submissions (filter form, org, period, status), tạo submission, upload Excel, Gửi duyệt | GET/POST/PUT /api/v1/submissions, POST /api/v1/submissions/{id}/upload-excel, POST /api/v1/submissions/{id}/submit |
| Workflow UI | Trên Báo cáo hoặc màn riêng: Duyệt, Từ chối, Yêu cầu chỉnh sửa (cho instance Pending) | POST /api/v1/workflow-instances/{id}/approve, reject, request-revision |

---

## 2. Convention FE

- **Locale:** vi_VN (Ant Design ConfigProvider).
- **Layout:** AppLayout sidebar + menu (Quản lý đơn vị, Quản lý người dùng, **Kỳ báo cáo**, **Dashboard**, **Biểu mẫu**, **Báo cáo**).
- **Bảng:** Ant Design Table, cột Thao tác (Sửa, Xóa hoặc Gửi duyệt, Duyệt…).
- **Form trong Modal:** MODAL_FORM (constants/modalSizes), useFocusFirstInModal, useScrollPageTopWhenModalOpen; không gọi form.resetFields() khi !modalOpen (tránh warning useForm).
- **Text:** Tất cả label, placeholder, nút, message tiếng Việt.
- **Console:** Không warning (deprecated, useForm not connected).

---

## 3. API client (gợi ý)

- `api/reportingPeriodsApi.ts` – getList, getById, getCurrent, create, update, delete.
- `api/reportingFrequenciesApi.ts` – getList (seed).
- `api/dashboardApi.ts` – getAdminStats, getUserTasks.
- `api/formsApi.ts` – getList, getById, getVersions.
- `api/submissionsApi.ts` – getList, getById, create, update, submit, uploadExcel, getWorkflowInstance.
- `api/workflowInstancesApi.ts` – approve, reject, requestRevision.

---

## 4. Routes

- `/reporting-periods` – Kỳ báo cáo
- `/dashboard` – Dashboard (có thể 2 tab hoặc 2 block: Thống kê admin / Nhiệm vụ của tôi)
- `/forms` – Biểu mẫu
- `/submissions` – Báo cáo (Submissions)

---

## 5. Kiểm tra cho AI (7.1)

**AI sau khi triển khai FE Phase 2–3 chạy lần lượt và báo Pass/Fail.**

1. **Build FE**
   - Lệnh: `npm run build` trong `src/bcdt-web`.
   - Kỳ vọng: Build succeeded.

2. **API đang chạy**
   - Backend: `dotnet run --project src/BCDT.Api --launch-profile http` (http://localhost:5080).

3. **Chạy FE:** `npm run dev` trong `src/bcdt-web`. Mở http://localhost:5173.

4. **Đăng nhập:** admin / Admin@123. Kỳ vọng: redirect sau login.

5. **Menu**
   - Kỳ báo cáo, Dashboard, Biểu mẫu, Báo cáo có trong menu; bấm lần lượt không lỗi 401.

6. **Trang Kỳ báo cáo**
   - Vào /reporting-periods. Kỳ vọng: Bảng danh sách kỳ (có thể rỗng); nút Thêm kỳ; Modal tạo/sửa (PeriodCode, PeriodName, Year, Frequency, StartDate, EndDate, Deadline). Tạo/sửa/xóa (nếu có dữ liệu) → Pass.

7. **Trang Dashboard**
   - Vào /dashboard. Kỳ vọng: Hiển thị thống kê (số submission theo trạng thái, theo kỳ, theo form) và/hoặc nhiệm vụ user (drafts, deadlines, pending approvals). Không lỗi console.

8. **Trang Biểu mẫu**
   - Vào /forms. Kỳ vọng: Bảng danh sách biểu mẫu (GET /api/v1/forms). Có thể xem versions (GET /api/v1/forms/{id}/versions).

9. **Trang Báo cáo (Submissions)**
   - Vào /submissions. Kỳ vọng: Bảng danh sách submission (filter form, org, period, status); nút Tạo báo cáo (Modal: chọn Form, Đơn vị, Kỳ); với bản ghi Draft: nút Gửi duyệt; Upload Excel (input file + POST submissions/{id}/upload-excel) nếu có.

10. **Workflow (nếu có instance Pending)**
    - Trên trang Báo cáo hoặc màn duyệt: với submission đã Submitted, user có quyền thấy nút Duyệt / Từ chối / Yêu cầu chỉnh sửa; bấm Duyệt → gọi approve → cập nhật trạng thái. Kỳ vọng: 200, list cập nhật.

11. **Console**
    - Mở DevTools Console. Kỳ vọng: Không warning (deprecated, useForm). Text giao diện tiếng Việt.

12. **Edge: Chưa đăng nhập vào /reporting-periods**
    - Xóa token, vào /reporting-periods. Kỳ vọng: Redirect về /login.

---

**Version:** 1.0  
**Ngày:** 2026-02-06
