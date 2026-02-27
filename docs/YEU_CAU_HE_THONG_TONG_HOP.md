# Yêu cầu hệ thống – Tổng hợp

Tài liệu **tổng hợp** yêu cầu BCDT: tham chiếu 104 yêu cầu MVP (01) và bổ sung **yêu cầu mở rộng** (R1–R11) cho cấu trúc biểu mẫu – chỉ tiêu cố định & động. Dùng cho rà soát và đối chiếu với giải pháp.

**Nguồn chi tiết:** [script_core/01.YEU_CAU_HE_THONG.md](script_core/01.YEU_CAU_HE_THONG.md) · [de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md)

---

## 1. Yêu cầu MVP (104) – Tóm tắt

| Nhóm | Số lượng | Mã / Ví dụ |
|------|----------|------------|
| Nghiệp vụ (Business) | 30 | BM-01→06 (biểu mẫu), EX-01→08 (Excel web), ORG-01→06 (tổ chức), WF-01→06 (workflow), CK-01→04 (chu kỳ) |
| Chức năng (Functional) | 22 | FR-BM-01→06 (quản lý biểu mẫu), FR-NL-01→06 (nhập liệu), FR-WF-01→05, FR-TH-01→03, FR-DB-01→02 |
| Phi chức năng (NFR) | 20 | NFR-P-01→05 (hiệu năng), NFR-S-01→04 (scale), NFR-A-01→03, NFR-SEC-01→05, NFR-O-01→03 |
| Khía cạnh hệ thống | 32 | Data Storage, Data Binding, Excel Generator, Workflow, Aggregation, Notification, API, DB, Security, … |

**Trạng thái MVP:** Phase 1–4 đã triển khai (Auth, Org, Form, Submission, Workflow, Reporting, Dashboard, Phase 4 Polish). Xem [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md).

---

## 2. Yêu cầu mở rộng – Cấu trúc biểu mẫu, chỉ tiêu cố định & động (R1–R11)

Áp dụng **sau MVP** (hoặc song song Week 16–17 trở đi). Giải pháp đầy đủ: [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md).

| # | Yêu cầu | Tóm tắt |
|---|---------|--------|
| **R1** | Người khởi tạo | Cấu trúc biểu mẫu do **System Admin** khởi tạo và quản lý. |
| **R2** | Nội dung cấu trúc | Form + sheet, cột, hàng, công thức, khóa, format, style, data binding, column mapping. |
| **R3** | Chỉ tiêu cố định | Cột/hàng định nghĩa sẵn; đơn vị chỉ nhập **giá trị**. |
| **R4** | Placeholder chỉ tiêu động | Có vùng placeholder cho **chỉ tiêu do đơn vị tự nhập** (tên + giá trị). |
| **R5** | Biểu mẫu đầy đủ | Biểu mẫu = **phần cố định** + **phần động** (tại placeholder). |
| **R6** | Tái sử dụng chỉ tiêu | Xây dựng biểu mẫu bằng cách **chọn chỉ tiêu từ danh mục** (catalog). |
| **R7** | Chỉ tiêu cố định áp dụng tất cả | Chỉ **System Admin** nhập chỉ tiêu cố định; áp dụng cho **tất cả** đơn vị. |
| **R8** | Chỉ tiêu động theo danh mục, dữ liệu theo đơn vị | Chỉ tiêu động theo **danh mục**; **dữ liệu** (giá trị) **theo từng đơn vị** (submission). |
| **R9** | Danh mục phát sinh & khởi tạo động | Danh mục chỉ tiêu động **có thể phát sinh**; **khởi tạo động** qua API/UI, **không cần deploy**. |
| **R10** | Phân cấp cha-con (chỉ tiêu) | **Chỉ tiêu cố định** và **chỉ tiêu động** đều có **phân cấp cha-con nhiều tầng**; hiển thị/chọn theo cây. |
| **R11** | Phân cấp cột/hàng trong biểu mẫu | **Cột/hàng** phân cấp cha-con (độc lập với chỉ tiêu). **Cột:** header merge = số con, cháu. **Hàng placeholder:** cấu hình **độ sâu đệ quy**. **Tạo Excel:** ưu tiên (1) cấu hình, (2) chỉ tiêu động. |

---

## 3. Ánh xạ R1–R11 ↔ Phase triển khai (gợi ý)

| Phase | Nội dung chính | Yêu cầu phủ |
|-------|----------------|-------------|
| **P1** | Authorization (FormStructureAdmin) | R1 |
| **P1b** | Danh mục chỉ tiêu (Indicator, IndicatorCatalog, ParentId), FormColumn.IndicatorId, FormDynamicRegion.IndicatorCatalogId, ReportDynamicIndicator.IndicatorId; API/FE tree, TreeSelect | R6, R7, R8, R9, R10 |
| **P2** | BCDT_FormDynamicRegion, BCDT_ReportDynamicIndicator, IndicatorExpandDepth | R4, R5 (phần placeholder) |
| **P2a** | FormColumn.ParentId, FormRow.ParentId; merge header; FormRow.FormDynamicRegionId; API tree columns/rows; FE cây cột/hàng, độ sâu đệ quy | R11 |
| **P3** | API CRUD FormDynamicRegion, GET/PUT dynamic-indicators | R4 |
| **P4** | Build workbook (thứ tự ưu tiên, merge header, IndicatorExpandDepth); Sync presentation → ReportDynamicIndicator | R5, R11 |
| **P5–P6** | FE FormConfig (vùng chỉ tiêu động), SubmissionDataEntry (chỉ tiêu động theo catalog) | R4, R8 |
| **P7** | Test E2E, RUNBOOK, tài liệu | — |

---

## 4. Đối chiếu nhanh: Đã đáp ứng chưa

- **MVP (104 yêu cầu):** Đã triển khai theo Phase 1–4 (xem TONG_HOP).
- **R1–R11:** Giải pháp đã thiết kế đầy đủ trong file giải pháp (mục 8 đối chiếu R↔Giải pháp). **Chưa triển khai code**; khi triển khai dùng TONG_HOP mục 3.2 (bảng), 3.3/3.5/3.7 (block Cách giao AI), mục 8 và block "Cách giao AI khi làm Cấu trúc biểu mẫu – Chỉ tiêu cố định & động".

---

**Version:** 1.0 · **Last updated:** 2026-02-06
