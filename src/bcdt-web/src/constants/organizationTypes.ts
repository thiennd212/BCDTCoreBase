/** Loại đơn vị (seed 14.seed_data.sql) */
export const ORGANIZATION_TYPES = [
  { id: 1, code: 'MINISTRY', name: 'Bộ/Cơ quan ngang Bộ' },
  { id: 2, code: 'PROVINCE', name: 'Tỉnh/Thành phố' },
  { id: 3, code: 'LEVEL3', name: 'Cấp 3' },
  { id: 4, code: 'LEVEL4', name: 'Cấp 4' },
  { id: 5, code: 'LEVEL5', name: 'Cấp 5' },
] as const
