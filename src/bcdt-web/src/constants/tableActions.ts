/**
 * Quy ước cột "Thao tác" trong bảng (Ant Design Table) – dùng thống nhất để tránh tràn chữ, giao diện gọn.
 *
 * --- Chuẩn 1: Icon + Tooltip (ưu tiên) ---
 * - Khi: 2–4 thao tác, nhãn có thể dài (Sửa, Xóa, Bộ lọc / Ánh xạ, Cấu hình).
 * - Cách làm: Chỉ hiển thị icon, tooltip = nhãn đầy đủ. Cột cố định ~110px, không tràn.
 * - Ví dụ: EditOutlined + Tooltip "Sửa", DeleteOutlined + "Xóa", FilterOutlined + "Bộ lọc / Ánh xạ".
 * - Dùng: ACTIONS_COLUMN_WIDTH_ICON, align: 'right'.
 *
 * --- Chuẩn 2: Dropdown "Thao tác" ---
 * - Khi: > 4 thao tác hoặc nhiều thao tác theo trạng thái (Nhập liệu, Gửi duyệt, Duyệt, Từ chối...).
 * - Cách làm: Một nút "Thao tác" (hoặc icon MoreOutlined) mở Dropdown; mỗi item = icon + nhãn.
 * - Cột cố định ~100px. Hành động có confirm (Xóa) có thể để trong dropdown và mở Popconfirm khi click.
 * - Dùng: ACTIONS_COLUMN_WIDTH_DROPDOWN.
 *
 * --- Chuẩn 3: Text link + wrap (dự phòng) ---
 * - Khi: Cần nhấn mạnh nhãn bằng chữ, ít thao tác (2–3), chấp nhận cột rộng hơn.
 * - Cách làm: Space size="small" wrap, width tối thiểu ~200px (tùy nhãn dài nhất).
 * - Tránh dùng khi có nhãn rất dài (dễ tràn trên màn nhỏ).
 *
 * --- Áp dụng ---
 * - Màn có 2–3 thao tác (Sửa, Xóa, Cấu hình): Chuẩn 1.
 * - Màn có 1 thao tác đặc biệt dài (Bộ lọc / Ánh xạ): Chuẩn 1 (icon FilterOutlined + tooltip).
 * - Màn có nhiều thao tác theo trạng thái (báo cáo: Nhập liệu, Gửi duyệt, Duyệt...): Chuẩn 2 hoặc giữ wrap với width ≥ 260.
 */

/** Độ rộng cột Thao tác khi dùng icon + Tooltip (2–4 nút). Đủ cho 3–4 icon nằm một hàng, không cắt. */
export const ACTIONS_COLUMN_WIDTH_ICON = 130

/** Độ rộng cột Thao tác khi dùng Dropdown (một nút mở menu). */
export const ACTIONS_COLUMN_WIDTH_DROPDOWN = 100

/** Độ rộng cột Thao tác khi bắt buộc dùng text link + wrap (ít dùng). */
export const ACTIONS_COLUMN_WIDTH_TEXT = 220

/** Độ rộng cột Thao tác khi có 4–5 icon (vd. Báo cáo: Nhập liệu, Gửi duyệt, Upload, Duyệt, Từ chối). */
export const ACTIONS_COLUMN_WIDTH_ICON_MANY = 165
