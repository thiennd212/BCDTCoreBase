# Kế hoạch: Cột/hàng định nghĩa biểu mẫu từ danh mục chỉ tiêu dùng chung

**Mục đích:** Tổng hợp đầy đủ phương án tối ưu và cung cấp **COMMAND (block giao AI)** để giao cho AI phát triển.  
**Ngày:** 2026-02-24  
**Tham chiếu:** [DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md](DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md), [REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md](REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md), [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md), [B12_CHI_TIEU_CO_DINH_DONG.md](B12_CHI_TIEU_CO_DINH_DONG.md).

---

## 1. Tổng hợp phương án tối ưu

### 1.1. Lựa chọn tổng thể

- **Cột:** Phase 1 (ưu tiên UI "chọn từ danh mục") → Phase 2a/2b chỉ khi nghiệp vụ xác nhận.
- **Hàng:** Phase 3 chỉ khi có yêu cầu rõ "danh mục hàng"; không triển khai trong kế hoạch hiện tại.

### 1.2. Các phase và phạm vi

| Phase | Nội dung | Schema | Scope kỹ thuật |
|-------|----------|--------|-----------------|
| **Phase 1** | UI ưu tiên "chọn từ danh mục" khi thêm cột. Luồng mặc định: chọn Indicator (TreeSelect/danh sách); nút "Tạo cột mới" cho ngoại lệ. **Không** bắt buộc IndicatorId. | Không đổi | FE: FormConfig "Thêm cột" – luồng mặc định + nút Tạo mới. BE: API cột đã hỗ trợ indicatorId (optional); kiểm tra copy metadata từ Indicator khi có. |
| **Phase 2a** (tùy chọn) | Validation theo policy: cột "dữ liệu" (DataType ≠ Header/Formula…) bắt buộc IndicatorId khi policy bật. API từ chối 400 nếu thiếu. | Không đổi (IndicatorId vẫn nullable) | BE: validation trong POST/PUT column; config/policy. |
| **Phase 2b** (tùy chọn) | FormColumn.IndicatorId NOT NULL + migration gán IndicatorId cho cột hiện có. | Migration | BE: migration, API bắt buộc indicatorId. |
| **Phase 3** (sau này) | FormRow.IndicatorId hoặc danh mục hàng. | Mở rộng | Làm rõ nghiệp vụ trước. |

### 1.3. Điều kiện tiên quyết (trước khi triển khai Phase 1)

1. Nghiệp vụ đã xác nhận nhu cầu (tăng tỷ lệ cột từ danh mục hoặc "có thể chọn" là đủ).
2. Danh mục chỉ tiêu đã rà soát; trách nhiệm quản lý danh mục đã giao.
3. Quy ước ngoại lệ đã thống nhất: cột Header, Formula, Stub, Ghi chú không bắt buộc Indicator; nút "Tạo cột mới" luôn có.
4. Hướng dẫn/tooltip đã chuẩn bị; chỉ số theo dõi đã định nghĩa (vd. % cột mới có IndicatorId).

### 1.4. Xử lý nhược điểm và chỉ số theo dõi (tóm tắt)

- **Danh mục chưa đủ:** Rà soát trước Phase 1; có "Đề xuất thêm chỉ tiêu" hoặc link sang IndicatorCatalog; review định kỳ.
- **Ngoại lệ:** Giữ "Tạo cột mới"; Phase 2a chỉ validate cột dữ liệu, không ép Header/Formula.
- **Vận hành:** Phân quyền sửa danh mục; tài liệu hướng dẫn; audit log.
- **Thói quen:** UX đơn giản; tooltip + đào tạo ngắn; đo tỷ lệ dùng danh mục sau 3–6 tháng.

**Chỉ số:** Tỷ lệ cột mới từ danh mục (> 50% sau 3–6 tháng); độ phủ danh mục; số cột "Tạo mới"; sự cố/khiếu nại.

*(Chi tiết: DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md mục 5.6.)*

---

## 2. Kiểm tra sau khi triển khai (checklist kỹ thuật)

Khi AI triển khai **Phase 1**, bắt buộc chạy đủ và báo **Pass/Fail** từng bước:

| # | Bước | Hành động | Kỳ vọng |
|---|------|------------|---------|
| 1 | Build BE | Tắt BCDT.Api (RUNBOOK 6.1). `dotnet build src/BCDT.Api/BCDT.Api.csproj` | Build succeeded. |
| 2 | API cột + indicatorId | POST .../columns với body có **indicatorId** (optional) | 200/201; cột có IndicatorId, metadata copy từ Indicator. |
| 3 | API cột không indicatorId | POST .../columns không gửi indicatorId | 200/201; cột tạo với IndicatorId = null. |
| 4 | FE – Luồng mặc định | FormConfig "Thêm cột": mặc định chọn từ danh mục (TreeSelect/danh sách Indicator); nút "Tạo cột mới" chuyển sang nhập trực tiếp. | Luồng chọn từ danh mục là bước đầu; "Tạo mới" vẫn tồn tại. |
| 5 | FE – Build | `npm run build` trong `src/bcdt-web` | Build succeeded. |
| 6 | Postman | Validate JSON collection | Không lỗi parse. |
| 7 | DevTools | Mở Console + Issues; không error/warning. Text UI tiếng Việt. | Không error/warning; label/placeholder tiếng Việt. |

---

## 3. COMMAND giao AI – Triển khai Phase 1 (copy-paste)

Dùng block dưới đây làm **COMMAND** giao cho AI khi triển khai Phase 1. Copy toàn bộ vào chat hoặc task.

```
Task: Triển khai Phase 1 – Cột định nghĩa biểu mẫu ưu tiên "chọn từ danh mục chỉ tiêu".

Mục tiêu: Khi người dùng bấm "Thêm cột" trên FormConfig, luồng mặc định là chọn chỉ tiêu từ danh mục (Indicator); vẫn giữ nút "Tạo cột mới" (nhập trực tiếp) cho ngoại lệ. Không đổi schema DB; FormColumn.IndicatorId vẫn optional.

Tài liệu bắt buộc đọc:
- docs/de_xuat_trien_khai/KE_HOACH_COT_HANG_TU_DANH_MUC_CHI_TIEU.md (kế hoạch đầy đủ)
- docs/de_xuat_trien_khai/DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md (đề xuất, mục 4.3 Phase 1, mục 6 checklist)
- docs/de_xuat_trien_khai/B12_CHI_TIEU_CO_DINH_DONG.md (ngữ cảnh B12, FormConfig)
- docs/AI_CONTEXT.md

Rules: bcdt-project, bcdt-agentic-workflow, always-verify-after-work.

Yêu cầu thực hiện:

1. Plan: Liệt kê bước – (1) Kiểm tra API BE đã hỗ trợ POST/PUT FormColumn với indicatorId (optional) và copy metadata từ Indicator khi có; (2) FE FormConfig: xác định vị trí "Thêm cột", thiết kế luồng: mặc định mở bước chọn Indicator (TreeSelect hoặc danh sách từ IndicatorCatalog/Indicators), sau khi chọn gửi indicatorId khi gọi API tạo cột; nút "Tạo cột mới" chuyển sang form nhập trực tiếp (giữ hành vi hiện tại); (3) Tooltip/ghi chú ngắn: "Nên chọn từ danh mục để thống nhất; dùng Tạo cột mới cho cột tiêu đề, công thức hoặc đặc biệt." Không đổi schema; không bắt buộc IndicatorId.

2. Execute: Làm đúng theo Plan. BE: nếu API chưa copy metadata từ Indicator khi có indicatorId thì bổ sung; FE: đổi luồng "Thêm cột" theo mục 1.2 Phase 1; giữ nút "Tạo cột mới"; thêm tooltip/help ngắn. Tất cả text hiển thị cho user phải tiếng Việt.

3. Kiểm tra cho AI (bắt buộc chạy đủ, báo Pass/Fail từng bước):
   - Build BE (tắt BCDT.Api trước): dotnet build src/BCDT.Api/BCDT.Api.csproj → Build succeeded.
   - API: POST columns với indicatorId → 200/201, cột có IndicatorId và metadata từ Indicator; POST columns không indicatorId → 200/201, IndicatorId null.
   - FE: FormConfig "Thêm cột" – mặc định chọn từ danh mục; nút "Tạo cột mới" có và chuyển sang nhập trực tiếp.
   - Build FE: npm run build trong src/bcdt-web → Build succeeded.
   - Postman: validate JSON collection không lỗi parse.
   - DevTools Console + Issues: không error, không warning; label/placeholder tiếng Việt.

4. Khi xong: Cập nhật TONG_HOP (nếu task nằm trong TONG_HOP) theo rule bcdt-update-tong-hop-after-task; ghi ngắn kết quả verify (Pass/Fail từng bước).
```

---

## 4. COMMAND giao AI – Phase 2a (validation, tùy chọn – dùng sau)

Chỉ dùng khi nghiệp vụ đã xác nhận cần validation "cột dữ liệu bắt buộc IndicatorId". Copy khi cần.

```
Task: Triển khai Phase 2a – Validation "cột dữ liệu bắt buộc IndicatorId" theo policy.

Mục tiêu: Khi policy bật, API POST/PUT FormColumn từ chối (400) nếu cột có DataType là dữ liệu (Number, Text, Date, …) mà không có indicatorId. Cột Header, Formula, Stub, Ghi chú không bắt buộc. FormColumn.IndicatorId vẫn nullable trong DB.

Tài liệu: docs/de_xuat_trien_khai/KE_HOACH_COT_HANG_TU_DANH_MUC_CHI_TIEU.md, DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md (Phase 2a). Rules: bcdt-project, bcdt-agentic-workflow, always-verify-after-work.

Yêu cầu: (1) Plan: Thêm/config policy (vd. form-level hoặc global); validation trong service hoặc validator khi Create/Update column. (2) Execute: Chỉ validate khi DataType thuộc nhóm "dữ liệu"; bỏ qua Header/Formula/Stub. (3) Verify: Gọi POST column không indicatorId, DataType = Number, policy bật → 400 với message rõ; policy tắt hoặc DataType = Formula → 200. Báo Pass/Fail từng bước.

**Kiểm tra cho AI (Phase 2a):** Config key `FormStructure:RequireIndicatorForDataColumns` (appsettings). Chạy đủ và báo Pass/Fail từng bước: (1) Build BE (tắt BCDT.Api trước). (2) Policy = false: POST column DataType=Number, không indicatorId → 200. (3) Policy = true: POST column DataType=Number, không indicatorId → 400, message "Cột dữ liệu bắt buộc chọn chỉ tiêu từ danh mục.". (4) Policy = true: POST column DataType=Formula, không indicatorId → 200. (5) Policy = true: POST column DataType=Number, có indicatorId → 200. (6) PUT column (policy = true, DataType=Number, bỏ indicatorId) → 400.
```

---

## 5. Tài liệu liên quan

| Tài liệu | Nội dung |
|----------|-----------|
| [DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md](DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md) | Đề xuất đầy đủ: hiện trạng, phương án (a)(b)(c), đánh giá ưu nhược, xử lý rủi ro, chỉ số, checklist. |
| [REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md](REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md) | Review thiết kế: cột/hàng nhập trực tiếp vs danh mục; gap. |
| [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) | R3, R6, R8, R9; mục 4.6 FormColumn.IndicatorId. |
| [B12_CHI_TIEU_CO_DINH_DONG.md](B12_CHI_TIEU_CO_DINH_DONG.md) | Ngữ cảnh B12, FormConfig, checklist 7.1. |
| [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) | Bảng ưu tiên, task Cột/hàng từ danh mục, block Cách giao AI (mục 3.7). |

---

**Version:** 1.0 · **Last updated:** 2026-02-24
