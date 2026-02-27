/**
 * Kích thước Modal form theo độ phức tạp (số trường, độ rộng nội dung).
 * Dùng cho Form trong Modal để cân đối: form ít trường → nhỏ, form nhiều trường → lớn.
 */
export const MODAL_FORM = {
  /** ~3–5 trường, form đơn giản (vd: đổi mật khẩu, filter nhanh) */
  SMALL: 440,
  /** ~6–8 trường, form trung bình (vd: user: tài khoản + thông tin + phân quyền) */
  MEDIUM: 600,
  /** ~9+ trường hoặc nhiều ô nhập rộng (vd: đơn vị: cơ bản + liên hệ + khác) */
  LARGE: 720,
} as const

/**
 * Modal form: không tạo scroll riêng bên trong body. Chỉ dùng scroll chính bên ngoài (trang).
 * styles={{ body: { overflow: 'visible', maxHeight: 'none' } }}
 */

/** Khoảng cách từ cạnh trên viewport đến modal (px) – modal gần trên để hiển thị nhiều trường hơn. */
export const MODAL_FORM_TOP_OFFSET = 24
