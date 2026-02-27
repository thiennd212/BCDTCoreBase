# Đề xuất: Cột/hàng định nghĩa biểu mẫu từ danh mục chỉ tiêu dùng chung

**Ngày:** 2026-02-24  
**Phạm vi:** FormColumn, FormRow vs danh mục chỉ tiêu (BCDT_Indicator, BCDT_IndicatorCatalog).  
**Tham chiếu:** [REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md](REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md), [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md), [B12_CHI_TIEU_CO_DINH_DONG.md](B12_CHI_TIEU_CO_DINH_DONG.md).

---

## 1. Tóm tắt hiện trạng

Trong định nghĩa biểu mẫu, **cột (FormColumn)** và **hàng (FormRow)** hiện chủ yếu là dữ liệu nhập trực tiếp theo từng form/sheet: mỗi cột có ColumnCode, ColumnName, DataType… lưu tại FormColumn; FormColumn.IndicatorId là **nullable** và tùy chọn (R6 – tái sử dụng chỉ tiêu đã có nhưng không bắt buộc). Hàng cố định (FormRow) hoàn toàn cấu hình per-sheet (label, thứ tự, ParentRowId), **không có** tham chiếu danh mục chỉ tiêu hay "danh mục hàng". Chỉ **vùng chỉ tiêu động** (FormDynamicRegion) bắt buộc gắn danh mục (IndicatorCatalogId). Nếu nghiệp vụ kỳ vọng phần lớn hoặc toàn bộ cột/hàng cố định lấy từ danh mục dùng chung thì hiện tại có gap: chưa bắt buộc chọn Indicator khi tạo/sửa cột, và hàng cố định chưa có mô hình "từ danh mục".

---

## 2. Các phương án đã xem xét

| # | Phương án | Mô tả ngắn |
|---|-----------|------------|
| **(a)** | **Ưu tiên UI "chọn từ danh mục"** | Luồng "Chọn từ danh mục chỉ tiêu" thành **luồng mặc định** khi thêm cột; "Tạo mới" (nhập trực tiếp) dành cho ngoại lệ. Không đổi schema. Có thể bổ sung rule nghiệp vụ: validation API từ chối lưu cột "dữ liệu" nếu IndicatorId null (tùy policy). |
| **(b)** | **FormColumn.IndicatorId NOT NULL** | Chuyển FormColumn.IndicatorId thành **NOT NULL**; mọi cột mới bắt buộc gắn một chỉ tiêu trong danh mục. Migration: gán IndicatorId cho cột hiện có (tạo Indicator "ảo" hoặc map từng cột). |
| **(c)** | **FormRow.IndicatorId / danh mục hàng** | Mở rộng thiết kế: **FormRow.IndicatorId** (nullable, FK → BCDT_Indicator) để hàng cố định cũng tham chiếu chỉ tiêu dùng chung; hoặc định nghĩa "danh mục hàng" (bảng riêng hoặc dùng Indicator với loại "row"). |

---

## 3. Phân tích từng phương án

### 3.1. Phương án (a) – Ưu tiên UI "chọn từ danh mục"

| Khía cạnh | Đánh giá |
|-----------|----------|
| **Ưu điểm** | Không thay đổi schema, không migration; triển khai nhanh; tăng tỷ lệ dùng danh mục qua trải nghiệm người dùng; vẫn giữ ngoại lệ "tạo cột mới" khi cần. |
| **Nhược điểm** | Không đảm bảo 100% cột từ danh mục; nếu không thêm validation thì vẫn có thể tạo nhiều cột "thủ công". |
| **Rủi ro** | Thấp: chỉ chỉnh FE (luồng mặc định) và có thể thêm validation API theo policy. |
| **R6/R3/R8/R9** | R6 (tái sử dụng): đáp ứng tốt nhờ luồng mặc định. R3 (chỉ tiêu cố định): vẫn cho phép "định nghĩa sẵn" có hoặc không từ catalog. R8/R9: không đổi (placeholder đã bắt buộc danh mục). |
| **Tác động** | **Schema:** Không. **API:** Có thể thêm validation (vd. "cột dữ liệu bắt buộc IndicatorId" theo role/form). **FE:** Đổi luồng "Thêm cột" → mặc định mở chọn Indicator, nút "Tạo mới" cho nhập trực tiếp. **Dữ liệu hiện có:** Không ảnh hưởng. |

### 3.2. Phương án (b) – FormColumn.IndicatorId NOT NULL

| Khía cạnh | Đánh giá |
|-----------|----------|
| **Ưu điểm** | Mọi cột đều gắn với chỉ tiêu trong danh mục; chuẩn hóa triệt để; truy vết và báo cáo theo chỉ tiêu thống nhất. |
| **Nhược điểm** | Migration phức tạp: cột hiện có IndicatorId NULL cần gán (tạo Indicator "ảo" hoặc map từng cột); mất linh hoạt cho ngoại lệ (cột header, cột phụ không muốn gắn Indicator). |
| **Rủi ro** | Trung bình–cao: migration sai có thể làm hỏng form hiện có; cần quy ước rõ cột "đặc biệt" (Header, Formula…) có dùng Indicator chung hay không. |
| **R6/R3/R8/R9** | R6: đáp ứng đầy đủ. R3: chỉ tiêu cố định = luôn từ danh mục. R8/R9: không đổi. |
| **Tác động** | **Schema:** FormColumn.IndicatorId NOT NULL; migration bắt buộc. **API:** POST/PUT column bắt buộc indicatorId (hoặc gán mặc định). **FE:** Bắt buộc chọn Indicator khi tạo/sửa cột. **Dữ liệu hiện có:** Cần script gán IndicatorId cho mọi FormColumn hiện có (tạo Indicator hoặc map). |

### 3.3. Phương án (c) – FormRow.IndicatorId / danh mục hàng

| Khía cạnh | Đánh giá |
|-----------|----------|
| **Ưu điểm** | Hàng cố định có thể chuẩn hóa tên/thứ tự giữa nhiều biểu mẫu; tái sử dụng "chỉ tiêu hàng" tương tự cột. |
| **Nhược điểm** | Thay đổi lớn: FormRow hiện không có FK tới Indicator; cần làm rõ nghiệp vụ "danh mục hàng" (dùng chung BCDT_Indicator với loại row, hay bảng riêng). |
| **Rủi ro** | Trung bình: scope và thiết kế chưa được xác nhận từ nghiệp vụ; có thể trùng/khác với chỉ tiêu động (placeholder đã dùng catalog). |
| **R6/R3/R8/R9** | R6: có thể mở rộng cho hàng. R3: hàng cố định "từ danh mục" nếu có yêu cầu. R8/R9: không thay đổi (đã áp dụng cho vùng placeholder). |
| **Tác động** | **Schema:** Thêm FormRow.IndicatorId (nullable) hoặc mô hình "danh mục hàng" riêng. **API:** GET/POST/PUT rows hỗ trợ indicatorId; có thể API danh mục hàng. **FE:** Chọn chỉ tiêu hàng khi thêm/sửa hàng. **Dữ liệu hiện có:** FormRow hiện có để IndicatorId NULL. |

---

## 4. Phương án đề xuất (tối ưu)

### 4.1. Lựa chọn: Kết hợp (a) → (b) có điều kiện; (c) làm sau khi có yêu cầu rõ

- **Cột:** Ưu tiên **Phase 1: Phương án (a)** – UI ưu tiên "chọn từ danh mục" (luồng mặc định khi thêm cột, không đổi schema). Sau khi nghiệp vụ xác nhận và dữ liệu/form ổn định, **Phase 2 (tùy chọn):** áp dụng **(b)** dưới dạng **validation** (API từ chối lưu cột dữ liệu thiếu IndicatorId theo policy) hoặc, nếu nghiệp vụ yêu cầu chuẩn hóa triệt để, chuyển sang **FormColumn.IndicatorId NOT NULL** kèm migration.
- **Hàng:** **Phương án (c)** không triển khai ngay; chỉ **đề xuất làm sau** khi nghiệp vụ làm rõ nhu cầu "danh mục hàng" (hàng cố định có cần chuẩn hóa tên/đơn vị giữa nhiều form không) và thống nhất thiết kế (FormRow.IndicatorId vs bảng riêng).

### 4.2. Lý do

1. **Giảm rủi ro và chi phí:** (a) không đổi schema, không migration, triển khai nhanh và dễ rollback; vẫn đáp ứng R6 nhờ luồng mặc định.
2. **Có đường nâng cấp:** Nếu sau này nghiệp vụ xác nhận "mọi cột dữ liệu phải từ danh mục", có thể thêm validation (Phase 2a) hoặc NOT NULL + migration (Phase 2b) mà không phải đảo ngược thiết kế.
3. **Hàng cố định:** R3/R8/R9 hiện không yêu cầu hàng cố định từ danh mục; FormDynamicRegion đã phủ chỉ tiêu động. Tránh thiết kế (c) khi chưa có yêu cầu rõ, tránh scope creep.

### 4.3. Thứ tự triển khai đề xuất

| Phase | Nội dung | Ghi chú |
|-------|----------|---------|
| **Phase 1** | **(a) UI ưu tiên "chọn từ danh mục"** – FormConfig "Thêm cột": luồng mặc định mở modal/tab "Chọn từ danh mục chỉ tiêu" (TreeSelect/danh sách Indicator); nút "Tạo cột mới" (nhập trực tiếp) cho ngoại lệ. Không đổi schema, không bắt buộc IndicatorId. | Ưu tiên triển khai. |
| **Phase 2a (tùy chọn)** | **Validation theo policy:** Rule nghiệp vụ "cột dữ liệu (DataType ≠ Header/…) bắt buộc có IndicatorId" → API POST/PUT column kiểm tra và từ chối nếu thiếu (khi policy bật). Vẫn giữ IndicatorId nullable trong DB. | Sau khi nghiệp vụ xác nhận. |
| **Phase 2b (tùy chọn)** | **FormColumn.IndicatorId NOT NULL + migration:** Chỉ khi nghiệp vụ yêu cầu chuẩn hóa triệt để; migration gán IndicatorId cho mọi FormColumn hiện có (tạo Indicator hoặc map); schema NOT NULL. | Phụ thuộc quyết định nghiệp vụ. |
| **Phase 3 (sau này)** | **FormRow.IndicatorId / danh mục hàng (c):** Chỉ khi có yêu cầu rõ "hàng cố định từ danh mục"; thiết kế chi tiết (FormRow.IndicatorId nullable hoặc danh mục hàng riêng) và triển khai. | Làm rõ nghiệp vụ trước. |

---

## 5. Đánh giá ưu nhược điểm thay đổi nghiệp vụ (trước khi triển khai)

Phần này đánh giá **bản thân thay đổi nghiệp vụ** (đẩy cột/hàng định nghĩa biểu mẫu “từ danh mục chỉ tiêu dùng chung”) – có hiệu quả và tối ưu hay không.

### 5.1. Ưu điểm của thay đổi

| Khía cạnh | Lợi ích |
|-----------|---------|
| **Chuẩn hóa dữ liệu** | Cột (và sau này có thể hàng) gắn với chỉ tiêu trong danh mục → tên, mã, đơn vị thống nhất giữa nhiều biểu mẫu; giảm trùng lặp và lỗi nhập tay. |
| **Tái sử dụng (R6)** | Chỉ tiêu đã định nghĩa trong catalog dùng lại cho nhiều form → bảo trì danh mục một nơi, cập nhật áp dụng cho mọi form tham chiếu. |
| **Truy vết & báo cáo** | Báo cáo tổng hợp, so sánh theo “chỉ tiêu” dễ hơn khi mọi cột dữ liệu map về cùng danh mục; hỗ trợ audit và đối chiếu. |
| **Trải nghiệm người dùng** | Chọn từ danh mục thường nhanh hơn nhập tay; giảm sai sót mã/tên không thống nhất. |

### 5.2. Nhược điểm / rủi ro

| Khía cạnh | Rủi ro / Hạn chế |
|-----------|-------------------|
| **Danh mục chưa đủ** | Nếu danh mục chỉ tiêu (IndicatorCatalog/Indicator) chưa đầy đủ hoặc cập nhật chậm, người dùng vẫn phải “tạo cột mới” nhiều → lợi ích chuẩn hóa giảm. |
| **Ngoại lệ nghiệp vụ** | Một số cột (header, cột phụ, formula) có thể không phù hợp gắn với chỉ tiêu; bắt buộc quá mức sẽ gây gượng ép hoặc tạo chỉ tiêu “ảo” vô nghĩa. |
| **Chi phí vận hành** | Duy trì danh mục chỉ tiêu chất lượng tốt đòi hỏi quy trình (ai được phép thêm/sửa, phê duyệt); nếu không có thì danh mục dễ loạn. |
| **Thay đổi thói quen** | Người quen nhập trực tiếp có thể thấy thêm bước “chọn từ danh mục” là phiền; cần hướng dẫn và có lối thoát “Tạo cột mới” cho ngoại lệ. |

### 5.3. Thay đổi có hiệu quả không?

- **Có hiệu quả** nếu:
  - Nghiệp vụ thực sự cần **thống nhất chỉ tiêu** giữa nhiều biểu mẫu / đơn vị và **truy vết theo chỉ tiêu**.
  - Danh mục chỉ tiêu đã hoặc sẽ được **quản lý đầy đủ** (đủ chỉ tiêu, cập nhật kịp thời).
  - Phase 1 (ưu tiên UI “chọn từ danh mục”) được triển khai → **tăng tỷ lệ dùng danh mục** mà không ép bắt buộc ngay, có thể đo lường (ví dụ % cột mới có IndicatorId) trước khi quyết định Phase 2.

- **Hiệu quả thấp** nếu:
  - Nghiệp vụ **không** yêu cầu chuẩn hóa giữa form; mỗi form độc lập, ít khi so sánh theo chỉ tiêu → thay đổi chủ yếu “theo quy định” chứ ít giá trị thực.
  - Danh mục nghèo nàn hoặc không được bảo trì → người dùng lựa chọn “Tạo cột mới” là chính, thay đổi gần như vô tác dụng.

### 5.4. Thay đổi có tối ưu không?

- **Cách triển khai đề xuất (Phase 1 → Phase 2 có điều kiện) là tối ưu** về mặt **kỹ thuật & quản lý rủi ro**:
  - **Phase 1:** Chỉ đổi luồng UI, không đổi schema, không migration → chi phí thấp, rollback dễ; vẫn đạt phần lớn lợi ích (tăng dùng danh mục qua mặc định).
  - **Phase 2:** Chỉ áp dụng khi nghiệp vụ xác nhận và có số liệu (vd. đa số cột đã từ danh mục) → tránh ép bắt buộc sớm khi nhu cầu chưa rõ.
  - **Hàng (Phase 3):** Làm sau khi có yêu cầu rõ “danh mục hàng” → tránh scope creep và thiết kế thừa.

- **Tối ưu nghiệp vụ** phụ thuộc vào:
  - Việc **làm rõ với nghiệp vụ**: có thực sự cần “cột/hàng chủ yếu từ danh mục” không, hay chỉ cần “có thể chọn từ danh mục” (hiện trạng đã đáp ứng). Nếu chỉ cần “có thể” thì Phase 1 (ưu tiên UI) đủ; nếu cần “bắt buộc” thì sau Phase 1 mới cân nhắc Phase 2a/2b.

### 5.5. Kết luận đánh giá

| Câu hỏi | Kết luận |
|---------|----------|
| **Thay đổi có ưu điểm rõ không?** | Có: chuẩn hóa, tái sử dụng, truy vết tốt hơn khi danh mục được dùng rộng rãi. |
| **Có nhược điểm/rủi ro đáng kể không?** | Có nhưng có thể kiểm soát: phụ thuộc chất lượng danh mục và ngoại lệ; Phase 1 không bắt buộc nên rủi ro thấp. |
| **Có hiệu quả không?** | Có hiệu quả **nếu** nhu cầu chuẩn hóa và truy vết theo chỉ tiêu là thật, và danh mục được duy trì tốt; nếu không thì hiệu quả thấp. |
| **Cách triển khai có tối ưu không?** | Có: Phase 1 (ưu tiên UI) tối ưu chi phí–rủi ro–lợi ích; Phase 2/3 có điều kiện tránh làm quá sớm hoặc quá cứng. |

**Khuyến nghị:** Triển khai **Phase 1** là hợp lý; trước đó nên **xác nhận với nghiệp vụ** (1) có yêu cầu tăng tỷ lệ cột từ danh mục không, (2) danh mục chỉ tiêu hiện có đủ dùng chưa. Sau Phase 1, đo lường (vd. % cột mới có IndicatorId) rồi mới quyết định có cần Phase 2a/2b hay không.

### 5.6. Xử lý nhược điểm, kiểm soát rủi ro và đạt hiệu quả tốt nhất

Bảng dưới gắn **từng nhược điểm/rủi ro** với **hành động cụ thể** và **chỉ số theo dõi** để kiểm soát và tối đa hóa hiệu quả.

| Nhược điểm / Rủi ro | Cách xử lý / Kiểm soát | Cách đạt hiệu quả tốt nhất |
|--------------------|------------------------|----------------------------|
| **Danh mục chưa đủ** | **(1) Trước Phase 1:** Rà soát danh mục chỉ tiêu hiện có (số catalog, số indicator, phủ các nhóm chỉ tiêu hay chưa). **(2) Trong Phase 1:** Có nút/link "Đề xuất thêm chỉ tiêu" hoặc chuyển sang trang quản lý IndicatorCatalog để người dùng yêu cầu bổ sung. **(3) Quy trình:** Định kỳ (vd. quý) review danh mục: chỉ tiêu thiếu, trùng, lỗi tên/đơn vị. | Ưu tiên **làm đầy danh mục** trước hoặc song song Phase 1: bổ sung chỉ tiêu thường dùng theo phản hồi đơn vị; gắn trách nhiệm một bên (vd. Ban chỉ đạo/Phòng Kế hoạch) "sở hữu" danh mục. |
| **Ngoại lệ nghiệp vụ** | **(1) Quy ước rõ:** Liệt kê loại cột được phép **không** gắn Indicator: Header, Stub (nhãn), Formula (công thức), Ghi chú. **(2) Phase 1:** Luôn giữ nút "Tạo cột mới" (nhập trực tiếp) cho các trường hợp này. **(3) Phase 2a (nếu có):** Validation chỉ áp dụng cho cột "dữ liệu" (DataType = Number, Text, Date…), **không** bắt buộc Indicator cho Header/Formula. | Trong UI, ghi chú ngắn khi chọn "Tạo cột mới": "Dùng cho cột tiêu đề, công thức hoặc cột đặc biệt". Tránh tạo chỉ tiêu ảo; nếu Phase 2b (NOT NULL) thì cho phép một vài Indicator "đặc biệt" (vd. Header, Formula) trong danh mục. |
| **Chi phí vận hành** | **(1) Quyền:** Chỉ một số vai trò được thêm/sửa/xóa Indicator (vd. Admin, Quản lý danh mục); user thường chỉ **chọn** từ danh mục. **(2) Quy trình:** Tài liệu ngắn "Hướng dẫn quản lý danh mục chỉ tiêu" (ai được phép, khi nào thêm, đặt tên/ mã thống nhất). **(3) Audit:** Ghi log thay đổi danh mục (ai, khi nào, nội dung) để truy vết. | Giao **trách nhiệm rõ** cho một đơn vị/người; lên lịch review danh mục định kỳ; dùng báo cáo "Cột đang dùng chỉ tiêu X" để biết chỉ tiêu nào quan trọng, tránh xóa/sửa nhầm. |
| **Thay đổi thói quen** | **(1) UX:** Luồng mặc định "Chọn từ danh mục" đặt **bước đầu**, nhưng giao diện đơn giản (tìm kiếm, lọc theo catalog); nút "Tạo cột mới" luôn thấy, không ẩn. **(2) Hướng dẫn:** Tooltip hoặc help ngắn: "Nên chọn từ danh mục để thống nhất giữa các biểu mẫu; dùng Tạo cột mới cho trường hợp đặc biệt." **(3) Đào tạo:** Buổi giới thiệu ngắn cho người cấu hình form: lợi ích chọn từ danh mục, khi nào dùng "Tạo mới". | Đo **tỷ lệ dùng danh mục** sau vài tháng (vd. % cột mới có IndicatorId); nếu thấp thì thu thập phản hồi (danh mục thiếu? UI khó?). Điều chỉnh danh mục hoặc copy/ gợi ý chỉ tiêu thường dùng để giảm số lần "Tạo mới". |

**Chỉ số theo dõi (đạt hiệu quả tốt nhất):**

| Chỉ số | Cách đo | Mục tiêu gợi ý |
|--------|---------|-----------------|
| **Tỷ lệ cột mới từ danh mục** | Số FormColumn tạo mới có IndicatorId ≠ null / Tổng FormColumn tạo mới (theo kỳ). | Sau 3–6 tháng Phase 1: > 50%; nếu nghiệp vụ cần chuẩn hóa mạnh: > 70%. |
| **Độ phủ danh mục** | Số Indicator đang được ít nhất một FormColumn tham chiếu / Tổng Indicator (hoặc theo catalog). | Danh mục "sống": nhiều chỉ tiêu được dùng; chỉ tiêu không ai dùng có thể ẩn hoặc đánh dấu cần review. |
| **Số cột "Tạo mới" (ngoại lệ)** | Đếm FormColumn tạo mới với IndicatorId = null theo thời gian. | Ổn định hoặc giảm dần nếu danh mục đủ; nếu tăng đột biến → xem lại danh mục hoặc quy ước ngoại lệ. |
| **Sự cố / khiếu nại** | Số ticket/phản hồi liên quan "không tìm thấy chỉ tiêu", "bắt buộc chọn", "giao diện rối". | Giảm sau giai đoạn làm quen; nếu tăng → cải thiện UX hoặc bổ sung danh mục/hướng dẫn. |

**Checklist trước khi triển khai Phase 1 (để kiểm soát rủi ro và hiệu quả):**

1. [ ] **Nghiệp vụ đã xác nhận** nhu cầu tăng tỷ lệ cột từ danh mục (hoặc "có thể chọn" là đủ).
2. [ ] **Danh mục chỉ tiêu** đã rà soát: ít nhất một catalog đủ chỉ tiêu cho vài biểu mẫu mẫu; trách nhiệm quản lý danh mục đã giao.
3. [ ] **Quy ước ngoại lệ** đã thống nhất: loại cột nào không cần Indicator (Header, Formula, …); nút "Tạo cột mới" luôn có.
4. [ ] **Hướng dẫn / đào tạo** đã chuẩn bị (tooltip, help, hoặc tài liệu ngắn) để người dùng hiểu lợi ích và khi nào dùng "Tạo mới".
5. [ ] **Chỉ số theo dõi** đã định nghĩa (vd. % cột mới có IndicatorId); có kế hoạch xem lại sau 3–6 tháng để quyết định Phase 2a/2b.

---

## 6. Kiểm tra cho AI (checklist triển khai sau)

Khi triển khai **Phase 1** (UI ưu tiên "chọn từ danh mục"), chạy đủ các bước sau; báo **Pass** hoặc **Fail** từng bước.

| # | Bước | Hành động | Kỳ vọng |
|---|------|------------|---------|
| 1 | Build BE | Tắt process BCDT.Api (RUNBOOK 6.1). `dotnet build src/BCDT.Api/BCDT.Api.csproj` | Build succeeded. |
| 2 | API cột + indicatorId | POST /api/v1/forms/{formId}/sheets/{sheetId}/columns với body có **indicatorId** (optional) | 200/201; cột tạo có IndicatorId, metadata copy từ Indicator khi có. |
| 3 | API cột không indicatorId | POST .../columns không gửi indicatorId | 200/201; cột tạo với IndicatorId = null (vẫn cho phép). |
| 4 | FE – Luồng mặc định | FormConfig "Thêm cột": mặc định hiển thị chọn từ danh mục (TreeSelect/danh sách Indicator); có nút "Tạo cột mới" chuyển sang form nhập trực tiếp. | Luồng chọn từ danh mục là bước đầu; "Tạo mới" vẫn tồn tại. |
| 5 | FE – Build | Trong `src/bcdt-web`: `npm run build` | Build succeeded. |
| 6 | Postman | Validate JSON: `Get-Content docs/postman/BCDT-API.postman_collection.json -Raw -Encoding UTF8 \| ConvertFrom-Json` | Không lỗi parse. |

**Phase 2a (validation) – Kiểm tra cho AI:** Config key `FormStructure:RequireIndicatorForDataColumns` (appsettings / appsettings.Development). Chạy đủ và báo Pass/Fail từng bước:

| # | Bước | Hành động | Kỳ vọng |
|---|------|------------|---------|
| 2a-1 | Build BE | Tắt BCDT.Api (RUNBOOK 6.1). `dotnet build src/BCDT.Api/BCDT.Api.csproj` | Build succeeded. |
| 2a-2 | Policy = false | appsettings: `RequireIndicatorForDataColumns: false`. POST column DataType=Number, không indicatorId | 200/201. |
| 2a-3 | Policy = true, cột dữ liệu thiếu IndicatorId | appsettings.Development: `RequireIndicatorForDataColumns: true`. POST column DataType=Number, không indicatorId | 400, message "Cột dữ liệu bắt buộc chọn chỉ tiêu từ danh mục.". |
| 2a-4 | Policy = true, DataType=Formula | POST column DataType=Formula, không indicatorId | 200/201 (Formula không bắt buộc). |
| 2a-5 | Policy = true, có indicatorId | POST column DataType=Number, có indicatorId | 200/201. |
| 2a-6 | PUT bỏ indicatorId (policy = true) | PUT column DataType=Number, gửi indicatorId=null | 400, message như trên. |

**Phase 2b (NOT NULL + migration) – Kiểm tra cho AI:** Script `docs/script_core/sql/v2/25.form_column_indicator_not_null.sql`. Chạy đủ và báo Pass/Fail từng bước:

| # | Bước | Hành động | Kỳ vọng |
|---|------|------------|---------|
| 2b-1 | Build BE | Tắt BCDT.Api (RUNBOOK 6.1). `dotnet build src/BCDT.Api/BCDT.Api.csproj` | Build succeeded. |
| 2b-2 | Chạy migration | Chạy script 25 (trên DB đã có 01–20). | Script chạy xong; không lỗi. |
| 2b-3 | Kiểm tra DB | `SELECT COUNT(*) FROM BCDT_FormColumn WHERE IndicatorId IS NULL` | 0. |
| 2b-4 | POST thiếu indicatorId | POST column không gửi indicatorId hoặc indicatorId = 0 | 400, message bắt buộc IndicatorId. |
| 2b-5 | POST có indicatorId | POST column với indicatorId hợp lệ (vd. 1 hoặc _SPECIAL_GENERIC) | 200/201. |
| 2b-6 | PUT có indicatorId | PUT column với indicatorId hợp lệ | 200. |

**Ghi chú:** Chỉ tiêu đặc biệt Code `_SPECIAL_GENERIC` dùng cho cột "Tạo cột mới" (FE gửi id chỉ tiêu này khi user không chọn từ danh mục). **FE Phase 2b:** FormConfig dùng GET /api/v1/indicators/by-code/_SPECIAL_GENERIC để lấy id; luồng "Tạo cột mới" và form sửa cột luôn gửi indicatorId (tạo mới = _SPECIAL_GENERIC, sửa = record.indicatorId). Checklist: Build FE Pass; mở FormConfig → Tạo cột mới → điền form → Lưu → 200/201; request body có indicatorId.

---

## 7. Tài liệu tham chiếu

- [REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md](REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md) – Hiện trạng, gap, hướng xử lý.
- [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) – R3, R6, R8, R9; mục 4.6 FormColumn.IndicatorId.
- [B12_CHI_TIEU_CO_DINH_DONG.md](B12_CHI_TIEU_CO_DINH_DONG.md) – Ngữ cảnh B12, checklist 7.1.

---

**Version:** 1.2 · **Last updated:** 2026-02-24 (Thêm mục 5.6: Xử lý nhược điểm, kiểm soát rủi ro, chỉ số theo dõi và checklist trước Phase 1.)
