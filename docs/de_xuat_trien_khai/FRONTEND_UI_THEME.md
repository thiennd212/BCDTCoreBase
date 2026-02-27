# Đề xuất UI & Theme – Frontend BCDT

Tài liệu quy định thư viện giao diện, theme và layout cho frontend: **hiện đại, cân đối, đầy đủ khối, responsive**.

---

## 1. Nguyên tắc sử dụng thư viện

| Phạm vi | Thư viện | Ghi chú |
|--------|----------|--------|
| **Nhập liệu Excel / biểu mẫu báo cáo** | **DevExpress (DevExtreme)** | Spreadsheet, import/export Excel. Giữ license key cho module này. |
| **Các module còn lại** | **Ant Design** | Login, layout, quản lý đơn vị, quản lý user, form CRUD, bảng dữ liệu. |

- **DevExpress** chỉ load trong **module nhập liệu Excel** (lazy), không load ở entry chung.
- **Ant Design** dùng cho toàn bộ shell: layout, auth, danh sách, form.

---

## 2. Theme – hiện đại, cân đối

Dùng **Ant Design v5+** với **Design Token** (ConfigProvider).

### 2.1. Token chính

- **Primary:** `#1668dc` (xanh dương, dễ đọc, chuyên nghiệp).
- **Màu chữ:** `#1f2937` (chính), `#6b7280` (phụ).
- **Nền:** `#f8fafc` (layout), `#ffffff` (container).
- **Border radius:** `8px` (control, card), `10px` (card lớn).
- **Font:** system stack (Segoe UI, Roboto, Arial).
- **Shadow:** nhẹ cho card và header (cân đối, không nặng).

### 2.2. Component token

- **Layout:** header nền trắng, sider trắng viền nhạt, content nền `#f8fafc`.
- **Card:** bo góc 10px, shadow nhẹ.
- **Table:** header nền `#f8fafc`.
- **Menu:** item selected nền `#eff6ff`, chữ primary.

File: `src/theme/antdTheme.ts`.

---

## 3. Layout – đầy đủ khối, responsive

Cấu trúc **đầy đủ khối** (dùng trong `AppLayout.tsx`):

| Khối | Mô tả | Responsive |
|------|--------|------------|
| **Header** | Logo BCDT, menu (desktop ẩn vì có Sider), user + Đăng xuất. Cố định trên (sticky). | Trên mobile: nút hamburger mở Drawer menu. |
| **Sider** | Menu dọc: Quản lý đơn vị, Quản lý người dùng. | `breakpoint="lg"` (992px): thu gọn; &lt; 992px: ẩn Sider, dùng Drawer. |
| **Content** | Nội dung trang (Outlet). Padding 24px, min-height cân đối. | Padding giảm trên màn nhỏ nếu cần. |
| **Footer** | Một dòng bản quyền. Cố định dưới. | Giữ nguyên. |

- **Desktop (≥ 992px):** Header + Sider + Content + Footer; Sider 220px.
- **Mobile (&lt; 992px):** Header (có nút menu) + Content + Footer; menu trong Drawer trượt từ trái.

Breakpoint dùng hook `useIsMobile()` (matchMedia max-width 991px).

---

## 4. Trang Login

- Full viewport, căn giữa (flex center).
- Một **Card** duy nhất: logo + title + form (username, password) + nút Đăng nhập.
- Responsive: max-width 420px, padding 24px (mobile 16px).
- Không dùng Header/Sider/Footer.

---

## 5. Cấu trúc code

- **`src/theme/antdTheme.ts`** – theme token + component token.
- **`src/components/AppLayout.tsx`** – Layout đầy đủ khối (Header, Sider, Content, Footer) + menu responsive.
- **`src/hooks/useBreakpoint.ts`** – `useIsMobile()` cho responsive.
- **`App.tsx`** – ConfigProvider + route; route bảo vệ bọc `AppLayout`, con là index/organizations/users.
- **Trang nội dung** (Organizations, Users) – chỉ render tiêu đề + Card + Table, không tự render Layout.

---

## 6. Tài liệu tham khảo

- [Ant Design – Customize Theme](https://ant.design/docs/react/customize-theme)
- [Ant Design – Layout](https://ant.design/components/layout)
- DevExtreme: chỉ dùng trong module nhập liệu Excel; license xem B6_FRONTEND.md.

---

**Version:** 1.1  
**Ngày:** 2026-02-05  
**Cập nhật:** Theme hiện đại, cân đối; layout đầy đủ khối (Header, Sider, Content, Footer); responsive (Sider/Drawer theo breakpoint 992px).
