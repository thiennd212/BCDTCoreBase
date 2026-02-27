/** Vai trò (seed 14.seed_data.sql) */
export const ROLES = [
  { id: 1, code: 'SYSTEM_ADMIN', name: 'Quản trị hệ thống' },
  { id: 2, code: 'FORM_ADMIN', name: 'Quản trị biểu mẫu' },
  { id: 3, code: 'UNIT_ADMIN', name: 'Quản trị đơn vị' },
  { id: 4, code: 'DATA_ENTRY', name: 'Nhập liệu' },
  { id: 5, code: 'VIEWER', name: 'Xem báo cáo' },
] as const
