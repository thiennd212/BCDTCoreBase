# Đề xuất triển khai từng bước (cho AI)

Thư mục chứa **các file đề xuất triển khai** cho từng bước/công việc khi được yêu cầu. Mỗi file hướng dẫn AI triển khai theo chuẩn BCDT (Agents, Skills, Rules, kiến trúc, thứ tự thực hiện, kiểm tra).

## Cấu trúc

| File | Công việc | Ghi chú |
|------|-----------|---------|
| [B1_JWT.md](B1_JWT.md) | B1: JWT authentication (login, logout, refresh token) | API `/api/v1/auth/*`, middleware JWT |
| [B3_RLS.md](B3_RLS.md) | B3: RLS & Session Context | Middleware set UserId lên session context, gọi sp_SetUserContext; mục 7.1 Kiểm tra cho AI |
| [ADMIN_PASSWORD_BCRYPT.md](ADMIN_PASSWORD_BCRYPT.md) | Cập nhật mật khẩu admin cho B1 | Seed dùng placeholder; B1 dùng BCrypt – cần UPDATE PasswordHash để login admin/Admin@123 |
| [HIERARCHICAL_DATA_BASE_AND_RULE.md](HIERARCHICAL_DATA_BASE_AND_RULE.md) | Base và rule dữ liệu phân cấp | Chuẩn chung cho Organization, Menu, ReferenceEntity, …: API `all=true`, util `buildTree<T>`, Table tree, TreeSelect. Rule: bcdt-hierarchical-data. Skill: bcdt-hierarchical-tree. Agent: bcdt-hierarchical-data. |
| [B6_DE_XUAT_TREE_DON_VI.md](B6_DE_XUAT_TREE_DON_VI.md) | B6: Hiển thị đơn vị dạng cây (Tree) | Triển khai lần đầu theo base; backend `all=true`, FE treeUtils, Table tree + TreeSelect. |
| [B7_FORM_DEFINITION.md](B7_FORM_DEFINITION.md) | B7: Form Definition (CRUD biểu mẫu) | Phase 2 Week 5–6; API /api/v1/forms; BCDT_FormDefinition, BCDT_FormVersion; mục 7.1 Kiểm tra cho AI. |
| [RA_SOAT_REFRESH_TOKEN.md](RA_SOAT_REFRESH_TOKEN.md) | Rà soát Refresh token FE | Backend có; FE lưu refreshToken, authApi.refresh(), interceptor 401→refresh→retry, logout gọi backend; mục 5.1 Kiểm tra cho AI. |

**Kế hoạch thực hiện (một nguồn)**

| File | Công việc | Ghi chú |
|------|-----------|---------|
| [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md) | Kế hoạch cấu hình biểu mẫu mở rộng (B12 + P8) | Trạng thái, thứ tự, chi tiết P2a, P4 mở rộng, P7, P8a–P8f; checklist. Cách giao AI: TONG_HOP mục 3.3, 3.5, 3.7. |

**Giải pháp (thiết kế)**

| File | Nội dung |
|------|----------|
| [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) | Chỉ tiêu cố định & động (R1–R11): data model, API, FE. |
| [GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md) | Lọc động theo trường + placeholder cột (P8). |

**Đề xuất từng bước (B12, B1–B11)**

| File | Công việc |
|------|-----------|
| [B12_CHI_TIEU_CO_DINH_DONG.md](B12_CHI_TIEU_CO_DINH_DONG.md) | B12: checklist 7.1, test cases; trạng thái phase tại KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG. |

## Cách dùng

- **Với AI:** Khi giao task (vd B1), chỉ dẫn: *"Triển khai theo docs/de_xuat_trien_khai/B1_JWT.md"* hoặc @-mention file đó.
- **Tạo file mới:** Khi cần đề xuất triển khai cho bước khác (B2, B3, …), tạo file mới trong thư mục này (vd `B2_RBAC.md`, `B3_RLS.md`) theo cấu trúc tương tự B1 (Agents, Skills, Rules, mục tiêu, kiến trúc, thứ tự, **kiểm tra / test cases**).
- **Test cases:** Mỗi file đề xuất phải có mục **"7. Kiểm tra"** và **"7.1. Kiểm tra cho AI"** (checklist + lệnh chạy). Nếu tính năng có nhiều case: thêm file `{Mã}_TEST_CASES.md` (vd `B1_TEST_CASES.md`). Template và quy tắc: [DE_XUAT_TEST_COVERAGE_TONG_QUAT.md](DE_XUAT_TEST_COVERAGE_TONG_QUAT.md). Rule `always-verify-after-work` yêu cầu AI chạy đủ test cases và báo Pass/Fail trước khi báo xong.

## Tham chiếu

- Tổng hợp tiến độ: [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md)
- Workflow & Agent/Skill: [WORKFLOW_GUIDE.md](../WORKFLOW_GUIDE.md)
- **Cấu trúc tài liệu:** Rà soát và phương án cấu trúc lại (tránh chồng chéo): [RA_SOAT_VA_PHUONG_AN_CAU_TRUC_LAI_TAI_LIEU.md](../RA_SOAT_VA_PHUONG_AN_CAU_TRUC_LAI_TAI_LIEU.md). Kế hoạch nội dung (B12+P8): [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md).
