# Rà soát đánh giá và Phương án cấu trúc lại toàn bộ tài liệu BCDT

**Mục đích:** (1) Rà soát cấu trúc tài liệu hiện tại, chỉ ra chồng chéo và thiếu sót; (2) Đề xuất phương án cấu trúc lại để đảm bảo đầy đủ yêu cầu và không bị nội dung chồng chéo, khó kiểm soát toàn bộ công việc.

**Đã thực hiện tái cấu trúc (2026-02-06):** Nội dung kế hoạch cấu hình biểu mẫu (B12 + P8) gộp tại **một nguồn** → [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md). Các file RA_SOAT_DANH_GIA, DE_XUAT_TRIEN_KHAI_MO_RONG_CAU_HINH_BIEU_MAU, RÀ_SOÁT_VÙNG đã chuyển thành redirect tới file đó.

**Ngày:** 2026-02-06.

---

## Phần 1. Rà soát hiện trạng

### 1.1. Cấu trúc thư mục hiện tại (rút gọn)

```
docs/
├── AI_CONTEXT.md                    # Ngữ cảnh 1 trang cho AI
├── TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md   # Tiến độ + công việc tiếp + bảng 4.0 + blocks "Cách giao AI"
├── YEU_CAU_HE_THONG_TONG_HOP.md     # 104 yêu cầu MVP + R1–R11 + ánh xạ phase
├── CẤU_TRÚC_CODEBASE.md, RUNBOOK.md, WORKFLOW_GUIDE.md, ...
├── de_xuat_trien_khai/
│   ├── README.md                    # Mục lục đề xuất
│   ├── B1_JWT.md … B12_*.md         # Đề xuất theo từng hạng mục
│   ├── GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md   # Giải pháp R1–R11
│   ├── GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md                # Giải pháp P8 (lọc động, placeholder cột)
│   ├── KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md     # (Một nguồn) Trạng thái, kế hoạch, chi tiết B12+P8
│   ├── RA_SOAT_.../DE_XUAT_.../RÀ_SOÁT_...       # Redirect → KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG
│   ├── YEU_CAU_AI_MO_RONG_...                    # Redirect → TONG_HOP mục 4.1
│   └── DE_XUAT_TEST_COVERAGE_TONG_QUAT.md, ...
├── script_core/
│   ├── 01.YEU_CAU_HE_THONG.md       # 104 yêu cầu chi tiết
│   ├── 06.KE_HOACH_MVP.md           # Kế hoạch MVP 17 tuần
│   ├── 07.DANH_GIA_TONG_HOP.md      # Ma trận đánh giá 104 yêu cầu (có thể lỗi thời)
│   └── sql/v2/                      # Script SQL, seed, test
└── postman/
```

### 1.2. Phân loại nội dung và điểm chồng chéo

| Loại nội dung | Nơi xuất hiện | Vấn đề |
|---------------|----------------|--------|
| **Tiến độ / trạng thái đã làm** | TONG_HOP (mục 2.1, 2.2, 2.3…), B12 (bảng 1), RA_SOAT (1.1, 1.2), RÀ_SOÁT_VÙNG (1.2) | Cùng thông tin "B12 P1–P6 đã xong, P2a/P7 chưa" lặp ở 4+ file; cập nhật dễ lệch. |
| **Công việc tiếp theo / ưu tiên** | TONG_HOP (mục 4, 8), RA_SOAT (2.3, 2.5), DE_XUAT_TRIEN_KHAI (1, 2), B12 (1), YEU_CAU_HE_THONG_TONG_HOP (3) | Danh sách phase/ưu tiên trùng nhiều nơi; thứ tự có khi khác nhau. |
| **"Cách giao AI" (block copy-paste)** | TONG_HOP (4.1, 8), YEU_CAU_AI_MO_RONG (1, 2) | Hai nơi chứa block tương tự; bảo trì hai bên dễ lệch. |
| **Chi tiết phần cần làm (DB/BE/FE/Test)** | DE_XUAT_TRIEN_KHAI (2.1–2.9), RA_SOAT (2.3 bảng) | Nội dung gần giống; một bên theo phase, một bên theo bảng. |
| **Thiết kế giải pháp (R1–R11, P8)** | GIAI_PHAP_CAU_TRUC_BIEU_MAU, GIAI_PHAP_LOC_DONG | Đúng vai trò "design"; ít trùng. |
| **Yêu cầu (R1–R11, 104)** | YEU_CAU_HE_THONG_TONG_HOP, 01.YEU_CAU_HE_THONG, GIAI_PHAP (mục 8 đối chiếu) | R1–R11 có ở 2–3 file; 104 yêu cầu ở script_core. |
| **Checklist / Test case** | B12 (4, 5), DE_XUAT (4), RA_SOAT (3), từng Bx (7.1) | Checklist B12/P8 nằm rải; thiếu một "danh sách test" tập trung theo tính năng. |

### 1.3. Thiếu sót so với yêu cầu kiểm soát

| Yêu cầu | Hiện trạng |
|---------|------------|
| **Một nguồn sự thật cho tiến độ** | Chưa: TONG_HOP dài, nhiều mục; trạng thái B12/P8 còn nhân bản ở RA_SOAT, B12, RÀ_SOÁT_VÙNG. |
| **Một nguồn sự thật cho "công việc tiếp theo"** | Chưa: ưu tiên và phase list trùng TONG_HOP, RA_SOAT, DE_XUAT, B12. |
| **Một nguồn cho "Cách giao AI"** | Chưa: TONG_HOP 4.1 và YEU_CAU_AI_MO_RONG trùng nội dung giao task. |
| **Phân vai rõ: Yêu cầu vs Giải pháp vs Kế hoạch thực hiện** | Một phần: Yêu cầu (01, YEU_CAU_TONG_HOP), Giải pháp (GIAI_PHAP*), Kế hoạch (RA_SOAT, DE_XUAT, B12) bị trộn với tiến độ và block giao AI. |
| **Dễ tìm: theo tính năng (Auth, Form, B12, P8)** | Khó: B12/P8/cấu hình biểu mẫu có tới 6+ file (B12, GIAI_PHAP, GIAI_PHAP_LOC_DONG, RA_SOAT, DE_XUAT, RÀ_SOÁT_VÙNG, YEU_CAU_AI). |

### 1.4. Kết luận rà soát

- **Chồng chéo chính:** (1) Tiến độ/trạng thái B12 & mở rộng; (2) Danh sách phase/ưu tiên; (3) Block "Cách giao AI"; (4) Chi tiết phần cần làm (B12/P8).
- **Hệ quả:** Cập nhật một thay đổi phải sửa nhiều file; dễ quên; AI/người đọc không biết ưu tiên đọc file nào.
- **Cần:** Cấu trúc lại theo vai trò rõ (Index, Yêu cầu, Giải pháp, Kế hoạch thực hiện, Giao AI); mỗi loại thông tin **một nguồn sự thật**; giảm số file cho một phạm vi (vd cấu hình biểu mẫu).

---

## Phần 2. Nguyên tắc cấu trúc lại

1. **Một nguồn sự thật (Single source of truth)**  
   Mỗi loại thông tin có **một** file hoặc **một** mục chính; file khác chỉ **tham chiếu** (link) hoặc tóm tắt ngắn.

2. **Phân lớp rõ**  
   - **Lớp Index/Điều khiển:** Nơi AI và PM vào trước; trỏ tới đúng tài liệu theo task.  
   - **Lớp Yêu cầu:** Đủ 104 + R1–R11; không nhân bản nội dung chi tiết.  
   - **Lớp Giải pháp:** Thiết kế (data model, API, luồng); ít thay đổi khi đã duyệt.  
   - **Lớp Kế hoạch thực hiện:** Phase, phần cần làm (DB/BE/FE/Test), checklist; **một** kế hoạch cho một phạm vi (vd "Cấu hình biểu mẫu mở rộng").  
   - **Lớp Giao AI:** Block copy-paste "Cách giao AI" **chỉ ở một nơi** (vd TONG_HOP hoặc file chung), không nhân bản sang file khác.

3. **Gom theo phạm vi tính năng**  
   Một phạm vi (vd "Cấu trúc biểu mẫu – Chỉ tiêu cố định & động + P8") nên có: tối đa 1 file giải pháp (hoặc 2 nếu tách R1–R11 và P8), **1 file kế hoạch thực hiện** (gộp trạng thái + phase + phần cần làm + checklist), và được trỏ từ Index.

4. **Giảm số file trong de_xuat_trien_khai**  
   Với B12/P8: thay vì 6+ file (B12, RA_SOAT, DE_XUAT, RÀ_SOÁT_VÙNG, YEU_CAU_AI, GIAI_PHAP_LOC_DONG), hướng tới: **1–2 file giải pháp** (GIAI_PHAP*, giữ nguyên) + **1 file kế hoạch thực hiện** (gộp B12 + RA_SOAT + DE_XUAT + RÀ_SOÁT_VÙNG; "Cách giao AI" trỏ về TONG_HOP hoặc section trong file đó).

---

## Phần 3. Đề xuất cấu trúc mới

### 3.1. Sơ đồ vai trò tài liệu

```
                    ┌─────────────────────────────────────┐
                    │  AI_CONTEXT.md (1 trang)             │  ← Điểm vào cho AI
                    │  + TONG_HOP (Index: mục 4.0, 4.1)    │
                    └─────────────────┬───────────────────┘
                                      │ trỏ tới
        ┌─────────────────────────────┼─────────────────────────────┐
        ▼                             ▼                             ▼
┌───────────────┐           ┌─────────────────┐           ┌─────────────────┐
│ YÊU CẦU       │           │ GIẢI PHÁP       │           │ KẾ HOẠCH THỰC   │
│               │           │ (thiết kế)      │           │ HIỆN + GIAO AI  │
│ 01.YEU_CAU_   │           │ GIAI_PHAP_*.md  │           │                 │
│ HE_THONG      │           │ (R1–R11, P8)    │           │ - Tiến độ/      │
│ YEU_CAU_      │           │                 │           │   trạng thái     │
│ TONG_HOP      │           │                 │           │ - Phase & phần  │
└───────────────┘           └─────────────────┘           │   cần làm       │
                                                           │ - Checklist     │
                                                           │ - "Cách giao AI"│
                                                           │   (1 nơi)       │
                                                           └────────┬────────┘
                                                                    │
                                    ┌───────────────────────────────┼───────────────────────────────┐
                                    ▼                               ▼                               ▼
                            ┌───────────────┐             ┌───────────────┐             ┌───────────────┐
                            │ TONG_HOP      │             │ KE_HOACH_     │             │ Bx_*.md       │
                            │ (tiến độ tổng, │             │ CAU_HINH_     │             │ (đề xuất      │
                            │ ưu tiên,      │             │ BIEU_MAU_     │             │  từng B1–B11) │
                            │ bảng 4.0,     │             │ MO_RONG.md    │             │               │
                            │ block 4.1)    │             │ (B12+P8 gộp)  │             │               │
                            └───────────────┘             └───────────────┘             └───────────────┘
```

### 3.2. Cấu trúc thư mục đề xuất

```
docs/
├── AI_CONTEXT.md                          # Giữ: 1 trang, trỏ TONG_HOP + lớp Yêu cầu/Giải pháp/Kế hoạch
├── TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md   # Thu gọn: chỉ tiến độ tổng, ưu tiên, bảng 4.0, block 4.1 (một nguồn "Cách giao AI")
├── YEU_CAU_HE_THONG_TONG_HOP.md           # Giữ: 104 + R1–R11 + ánh xạ phase (chỉ tham chiếu, không duplicate chi tiết phase)
├── RUNBOOK.md, CẤU_TRÚC_CODEBASE.md, WORKFLOW_GUIDE.md, ...   # Giữ
│
├── de_xuat_trien_khai/
│   ├── README.md                          # Cập nhật: mục lục theo cấu trúc mới (Yêu cầu / Giải pháp / Kế hoạch / Đề xuất từng Bx)
│   │
│   ├── [GIẢI PHÁP – giữ nguyên]
│   ├── GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md
│   ├── GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md
│   │
│   ├── [KẾ HOẠCH THỰC HIỆN – một file gộp cho B12+P8]
│   ├── KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md   # MỚI: gộp nội dung chính từ RA_SOAT + DE_XUAT + B12 + RÀ_SOÁT_VÙNG
│   │   # Nội dung: 1.Tổng quan phase (B12 P2a/P4/P7, P8a–P8f). 2.Trạng thái đã làm/chưa. 3.Chi tiết từng phần (DB/BE/FE/Test). 4.Checklist. 5.Tham chiếu GIAI_PHAP & "Cách giao AI" (link TONG_HOP 4.1).
│   │
│   ├── [ĐỀ XUẤT TỪNG HẠNG MỤC – giữ B1–B11, B12 thu gọn]
│   ├── B1_JWT.md … B11_*.md
│   ├── B12_CHI_TIEU_CO_DINH_DONG.md       # Thu gọn: chỉ checklist 7.1, test cases, link KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG cho phase/trạng thái
│   │
│   ├── [TÀI LIỆU HỖ TRỢ – giữ hoặc gộp]
│   ├── DE_XUAT_TEST_COVERAGE_TONG_QUAT.md
│   ├── HIERARCHICAL_DATA_BASE_AND_RULE.md
│   ├── RA_SOAT_REFRESH_TOKEN.md
│   │
│   └── [CHUYỂN THÀNH "Lưu trữ" hoặc XÓA sau khi gộp]
│       # RA_SOAT_DANH_GIA_VA_KE_HOACH_CHI_TIET.md → nội dung chính chuyển vào KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG
│       # DE_XUAT_TRIEN_KHAI_MO_RONG_CAU_HINH_BIEU_MAU.md → chuyển vào KE_HOACH_...
│       # RÀ_SOÁT_VÙNG_CHỈ_TIÊU_ĐỘNG_VÀ_CỘT_HÀNG_ĐỘNG.md → phần "ý nghĩa + đã/chưa" gộp vào KE_HOACH_...; có thể giữ file ngắn "ý nghĩa vùng" hoặc xóa
│       # YEU_CAU_AI_MO_RONG_CHI_TIEU_CO_DINH_DONG.md → XÓA; "Cách giao AI" chỉ còn trong TONG_HOP 4.1
│
└── script_core/
    ├── 01.YEU_CAU_HE_THONG.md, 06.KE_HOACH_MVP.md   # Giữ
    ├── 07.DANH_GIA_TONG_HOP.md                      # Rà soát lại (DevExpress có thể lỗi thời); hoặc đánh dấu "Tham khảo lịch sử"
    └── sql/v2/                                       # Giữ
```

### 3.3. Bảng ánh xạ: file hiện tại → vai trò sau cấu trúc lại

| File hiện tại | Hành động đề xuất |
|---------------|-------------------|
| **TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md** | **Giữ**, thu gọn: bỏ trùng lặp chi tiết B12/P8 (chỉ giữ tóm tắt + link KE_HOACH_...). Giữ **mục 4.0, 4.1** làm **một nguồn duy nhất** cho "Cách giao AI". Mục 2 không duplicate chi tiết phase từng B12/P8. |
| **AI_CONTEXT.md** | **Giữ**, cập nhật: bảng "Tìm yêu cầu" trỏ thêm KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG; bỏ trỏ RA_SOAT/DE_XUAT khi đã gộp. |
| **YEU_CAU_HE_THONG_TONG_HOP.md** | **Giữ**, không nhân bản danh sách phase chi tiết; giữ ánh xạ R↔Phase (có thể trỏ KE_HOACH_... cho phase B12/P8). |
| **GIAI_PHAP_CAU_TRUC_BIEU_MAU_...**, **GIAI_PHAP_LOC_DONG_...** | **Giữ nguyên** (lớp Giải pháp). |
| **RA_SOAT_DANH_GIA_VA_KE_HOACH_CHI_TIET.md** | **Gộp** nội dung chính vào **KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md** (trạng thái, bảng kế hoạch 2.3, checklist 3). Sau đó file cũ: đánh dấu "Đã chuyển vào KE_HOACH_..." hoặc xóa. |
| **DE_XUAT_TRIEN_KHAI_MO_RONG_CAU_HINH_BIEU_MAU.md** | **Gộp** vào **KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md** (chi tiết 2.1–2.9, phụ thuộc, checklist 4). File cũ: chuyển thành redirect hoặc xóa. |
| **B12_CHI_TIEU_CO_DINH_DONG.md** | **Thu gọn**: giữ checklist 7.1, test cases, link tới KE_HOACH_... cho "phase list + trạng thái + phần cần làm". Bỏ bảng phase trùng với KE_HOACH_.... |
| **RÀ_SOÁT_VÙNG_CHỈ_TIÊU_ĐỘNG_VÀ_CỘT_HÀNG_ĐỘNG.md** | **Tóm tắt** "ý nghĩa vùng chỉ tiêu động" (1 trang) gộp vào KE_HOACH_... mục "Tổng quan / Ý nghĩa"; phần "đã/chưa" đã có trong KE_HOACH. File cũ: giữ ngắn "Ý nghĩa vùng (reference)" hoặc xóa. |
| **YEU_CAU_AI_MO_RONG_CHI_TIEU_CO_DINH_DONG.md** | **Xóa** hoặc chuyển thành 1 đoạn: "Cách giao AI: xem TONG_HOP mục 4.1 (block B12 P2a, P4 mở rộng, P8)." Tránh nhân bản block. |
| **Các B1–B11** | **Giữ** (đề xuất từng hạng mục). README cập nhật mục lục. |

### 3.4. Nội dung file mới KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md (gợi ý cấu trúc)

1. **Tổng quan** – Phạm vi (B12 P2a, P4 mở rộng, P7, P8a–P8f); thứ tự thực hiện; ước lượng tổng.
2. **Trạng thái đã làm / chưa làm** – Bảng ngắn (tương tự RA_SOAT 1.2); cập nhật một nơi khi phase xong.
3. **Chi tiết từng phần cần làm** – Bảng hoặc mục con: P2a, P4 mở rộng, P7, P8a…P8f (DB/BE/FE/Test); phụ thuộc.
4. **Checklist nghiệm thu** – Nghiệp vụ + hiệu năng (từ RA_SOAT phần 3).
5. **Tham chiếu** – Link GIAI_PHAP_CAU_TRUC_BIEU_MAU, GIAI_PHAP_LOC_DONG; **"Cách giao AI"**: xem TONG_HOP mục 4.1 (block B12 P2a, P4 mở rộng, P8).

---

## Phần 4. Kế hoạch thực hiện cấu trúc lại

| Bước | Hành động | Ưu tiên |
|------|-----------|---------|
| 1 | Tạo **KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md** (gộp nội dung chính từ RA_SOAT + DE_XUAT + RÀ_SOÁT_VÙNG; giữ cấu trúc mục 3.4). | Cao |
| 2 | Thu gọn **B12_CHI_TIEU_CO_DINH_DONG.md**: bỏ bảng phase/trạng thái trùng; thêm link "Phase & trạng thái: KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG". Giữ checklist 7.1, test cases. | Cao |
| 3 | Cập nhật **TONG_HOP**: mục 2.1/2.2/4/8 với B12/P8 chỉ tóm tắt 1–2 dòng + link KE_HOACH_...; giữ mục 4.0, 4.1 (một nguồn "Cách giao AI"). | Cao |
| 4 | Cập nhật **AI_CONTEXT**: bảng "Tìm yêu cầu" / "Tiến độ" trỏ KE_HOACH_...; bỏ trỏ RA_SOAT, DE_XUAT (sau khi gộp). | Trung bình |
| 5 | **YEU_CAU_AI_MO_RONG_CHI_TIEU_CO_DINH_DONG.md**: xóa hoặc thay bằng 1 đoạn redirect tới TONG_HOP 4.1. | Trung bình |
| 6 | **RA_SOAT**, **DE_XUAT_TRIEN_KHAI_MO_RONG**, **RÀ_SOÁT_VÙNG**: đánh dấu "Nội dung đã chuyển vào KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG" (đầu file) hoặc xóa nếu không cần lưu lịch sử. | Trung bình |
| 7 | Cập nhật **de_xuat_trien_khai/README.md**: mục lục theo lớp (Giải pháp, Kế hoạch thực hiện, Đề xuất từng Bx); link KE_HOACH_.... | Trung bình |
| 8 | Cập nhật **agents/skills/rules** (bcdt-form-structure-indicators, bcdt-ai-context): trỏ KE_HOACH_... thay vì RA_SOAT, DE_XUAT. | Trung bình |

---

## Phần 5. Tóm tắt lợi ích sau cấu trúc lại

| Trước | Sau |
|-------|-----|
| Tiến độ B12/P8 ở 4+ file | **Một nơi**: KE_HOACH_... (+ TONG_HOP tóm tắt). |
| "Cách giao AI" ở 2 file | **Một nơi**: TONG_HOP mục 4.1. |
| Chi tiết phần cần làm (B12, P8) ở 3 file | **Một nơi**: KE_HOACH_... (B12 vẫn có checklist riêng, link KE_HOACH cho phase/trạng thái). |
| Khó biết đọc file nào cho "cấu hình biểu mẫu mở rộng" | **Rõ**: Giải pháp → GIAI_PHAP*; Kế hoạch & trạng thái → KE_HOACH_...; Giao AI → TONG_HOP 4.1. |
| Cập nhật một phase xong phải sửa nhiều file | **Chỉ**: KE_HOACH_... (trạng thái) + TONG_HOP (tóm tắt mục 2, 8) + B12 (nếu checklist thay đổi). |

---

**Version:** 1.0 · **Last updated:** 2026-02-06
