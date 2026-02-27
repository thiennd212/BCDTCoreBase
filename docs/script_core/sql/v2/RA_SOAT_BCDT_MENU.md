# Rà soát BCDT_Menu (kèm Url)

**Ngày rà soát:** 2026-02-23. Dữ liệu lấy qua MCP `user-mssql` / `execute_sql`.

---

## 1. Toàn bộ menu (Id, Code, Name, ParentId, Url)

| Id | Code | Name | ParentId | Url |
|----|------|------|----------|-----|
| 1 | MENU_DASHBOARD | Dashboard | NULL | /dashboard |
| 2 | MENU_ORG_MANAGEMENT | Quản lý tổ chức | NULL | *(null)* |
| 3 | MENU_AUTH | Phân quyền | NULL | *(null)* |
| 4 | MENU_FORM | Biểu mẫu & Báo cáo | NULL | *(null)* |
| 5 | MENU_SYSTEM | Hệ thống | NULL | *(null)* |
| 10 | MENU_ORGANIZATIONS | Đơn vị | 2 | /organizations |
| 11 | MENU_ORG_TYPES | Loại đơn vị | 2 | /organization-types |
| 12 | MENU_USERS | Người dùng | 2 | /users |
| 20 | MENU_ROLES | Vai trò | 3 | /roles |
| 21 | MENU_PERMISSIONS | Quyền | 3 | /permissions |
| 22 | MENU_MENUS | Menu | 3 | /menus |
| 30 | MENU_FORMS | Biểu mẫu | 4 | /forms |
| 31 | MENU_SUBMISSIONS | Báo cáo | 4 | /submissions |
| 32 | MENU_INDICATOR_CATALOGS | Danh mục chỉ tiêu | 4 | /indicator-catalogs |
| 33 | MENU_REPORTING_PERIODS | Kỳ báo cáo | 4 | /reporting-periods |
| 34 | MENU_REPORTING_FREQUENCIES | Chu kỳ báo cáo | 4 | /reporting-frequencies |
| **35** | **MENU_WORKFLOW** | **Quy trình duyệt** | **4** | **/workflow-definitions** |
| 40 | MENU_NOTIFICATIONS | Thông báo | 5 | /notifications |
| 41 | SYSTEM_CONFIG | Cấu hình hệ thống | 5 | /system-config |
| **102** | **WORKFLOW_DEFINITIONS** | **Quy trình phê duyệt** | **5** | **/workflow-definitions** |

*Sau khi chạy 24.fix_menu_duplicate_workflow_url.sql: mục Id 35 (MENU_WORKFLOW) đã bị xóa; chỉ còn Id 102 cho Url /workflow-definitions.*

---

## 2. Kiểm tra trùng Url

**Query:** `SELECT Url, COUNT(*) AS Cnt FROM BCDT_Menu WHERE Url IS NOT NULL AND Url <> '' GROUP BY Url HAVING COUNT(*) > 1`

**Kết quả (trước khi xử lý):** **1 Url trùng** – `/workflow-definitions` xuất hiện **2 lần**. **Đã xử lý (2026-02-23):** Script [24.fix_menu_duplicate_workflow_url.sql](24.fix_menu_duplicate_workflow_url.sql) xóa MENU_WORKFLOW (Id 35); chỉ còn WORKFLOW_DEFINITIONS (102). Query trùng Url sau khi chạy: 0 dòng.

| Id | Code | Name | ParentId | Nhóm cha |
|----|------|------|----------|----------|
| 35 | MENU_WORKFLOW | Quy trình duyệt | 4 | Biểu mẫu & Báo cáo (MENU_FORM) |
| 102 | WORKFLOW_DEFINITIONS | Quy trình phê duyệt | 5 | Hệ thống (MENU_SYSTEM) |

**Nhận xét:** Cùng một route FE (`/workflow-definitions`) có hai mục menu: một dưới "Biểu mẫu & Báo cáo", một dưới "Hệ thống". Script **23.seed_menu_workflow_definitions.sql** chỉ thêm **WORKFLOW_DEFINITIONS** (Id 102) dưới Hệ thống. Mục **MENU_WORKFLOW** (Id 35) có thể đến từ seed/migration khác (không nằm trong 14/23 trong repo hiện tại). Cả hai đều trỏ cùng Url → **chồng chéo hiển thị** (user có thể thấy "Quy trình" hai lần nếu có quyền cả hai).

---

## 3. Khuyến nghị

1. **Tránh trùng Url:** Chỉ giữ **một** mục menu cho `/workflow-definitions`. **Đã thực hiện:** Xóa MENU_WORKFLOW (Id 35) bằng [24.fix_menu_duplicate_workflow_url.sql](24.fix_menu_duplicate_workflow_url.sql); giữ WORKFLOW_DEFINITIONS (102) dưới Hệ thống.
2. **Ràng buộc DB (tùy chọn):** Có thể thêm UNIQUE trên `Url` (chỉ với dòng có Url NOT NULL và không rỗng) để tránh trùng về sau; cần cân nhắc trường hợp "nhiều menu cùng route" nếu nghiệp vụ cho phép.

---

## 4. Query kiểm tra nhanh (MCP)

```sql
-- Liệt kê menu có Url
SELECT Id, Code, Name, ParentId, Url FROM BCDT_Menu WHERE Url IS NOT NULL AND Url <> '' ORDER BY ParentId, DisplayOrder;

-- Url trùng (kỳ vọng 0 dòng sau khi xử lý)
SELECT Url, COUNT(*) AS Cnt FROM BCDT_Menu WHERE Url IS NOT NULL AND Url <> '' GROUP BY Url HAVING COUNT(*) > 1;

-- Code trùng (kỳ vọng 0 dòng – UQ_Menu_Code)
SELECT Code, COUNT(*) AS Cnt FROM BCDT_Menu GROUP BY Code HAVING COUNT(*) > 1;
```

---

**Version:** 1.1 · **Last Updated:** 2026-02-23 (đã xử lý trùng: script 24, xóa Id 35)
