/**
 * Chuyển đổi giữa định dạng lưu backend (simple sheets/rows) và FortuneSheet (Sheet[]).
 * FortuneSheet hỗ trợ công thức, format, khóa ô (config.authority, rowReadOnly, colReadOnly).
 */

import type { Sheet } from '@fortune-sheet/core'
import type { WorkbookSheetData } from '../types/submission.types'
import type { FormColumnDto } from '../types/form.types'

/** Chữ cột Excel -> chỉ số cột (A=0, B=1, ..., Z=25, AA=26) */
export function colLetterToIndex(letter: string): number {
  let n = 0
  for (let i = 0; i < letter.length; i++) {
    n = n * 26 + (letter.toUpperCase().charCodeAt(i) - 64)
  }
  return n - 1
}

/** Chỉ số cột -> chữ cột (0=A, 26=AA) */
export function indexToColLetter(i: number): string {
  let s = ''
  let n = i + 1
  while (n > 0) {
    const r = (n - 1) % 26
    s = String.fromCharCode(65 + r) + s
    n = Math.floor((n - 1) / 26)
  }
  return s
}

/**
 * Kiểm tra JSON từ backend có phải định dạng FortuneSheet (Sheet[]) không.
 * FortuneSheet: mảng các object có name và celldata hoặc data.
 */
export function isFortuneSheetFormat(parsed: unknown): parsed is Sheet[] {
  return (
    Array.isArray(parsed) &&
    parsed.length > 0 &&
    typeof parsed[0] === 'object' &&
    parsed[0] !== null &&
    'name' in (parsed[0] as Sheet) &&
    ((parsed[0] as Sheet).celldata !== undefined || (parsed[0] as Sheet).data !== undefined)
  )
}

/**
 * Kiểm tra JSON từ backend có phải định dạng đơn giản (sheets[].rows với key A, B, C) không.
 */
export function isSimpleWorkbookFormat(parsed: unknown): parsed is { sheets: WorkbookSheetData[] } {
  return (
    typeof parsed === 'object' &&
    parsed !== null &&
    'sheets' in parsed &&
    Array.isArray((parsed as { sheets: unknown }).sheets) &&
    (parsed as { sheets: WorkbookSheetData[] }).sheets.length > 0 &&
    typeof (parsed as { sheets: WorkbookSheetData[] }).sheets[0].rows === 'object'
  )
}

const LIST_PREFIX = 'LIST:'

/**
 * Tạo config.colReadOnly từ cấu hình cột: cột có isEditable = false sẽ khóa (chỉ đọc).
 */
function buildColReadOnlyFromColumns(cols: FormColumnDto[]): Record<number, number> | undefined {
  const readOnly: Record<number, number> = {}
  cols.forEach((col, c) => {
    if (!col.isEditable) readOnly[c] = 1
  })
  return Object.keys(readOnly).length > 0 ? readOnly : undefined
}

/**
 * Tạo dataVerification cho dropdown: cột có validationRule = "LIST:val1,val2,..." → dropdown chọn giá trị.
 * Chỉ áp dụng cho dòng dữ liệu (từ dataRowStart), không áp dụng cho header.
 */
function buildDataVerificationFromColumns(
  cols: FormColumnDto[],
  dataRowStart: number,
  dataRowCount: number
): Record<string, { type: string; type2: string; value1: string }> | undefined {
  const out: Record<string, { type: string; type2: string; value1: string }> = {}
  cols.forEach((col, c) => {
    const rule = (col.validationRule ?? '').trim()
    if (!rule.startsWith(LIST_PREFIX)) return
    const listStr = rule.slice(LIST_PREFIX.length).trim()
    if (!listStr) return
    for (let r = 0; r < dataRowCount; r++) {
      out[`${dataRowStart + r}_${c}`] = { type: 'dropdown', type2: 'true', value1: listStr }
    }
  })
  return Object.keys(out).length > 0 ? out : undefined
}

/** Fortune-sheet cell value: có thể có mc (merge), bg (màu nền), bl (bold), ht/vt (align). */
type CellValue = {
  v?: string | number | boolean
  m?: string
  ct?: { fa: string; t: string }
  mc?: { r: number; c: number; rs?: number; cs?: number }
  bg?: string
  bl?: number
  ht?: number
  vt?: number
}
type CellItem = { r: number; c: number; v: CellValue | null }

const HEADER_BG_GROUP = '#d9e6f5'
const HEADER_BG_NAMES = '#e6f0fa'
const HEADER_FONT_BOLD = 1
const HEADER_ALIGN_CENTER = 1

const GROUP_LEVEL_KEYS: (keyof FormColumnDto)[] = [
  'columnGroupName',
  'columnGroupLevel2',
  'columnGroupLevel3',
  'columnGroupLevel4',
]

function getGroupLevelValue(col: FormColumnDto, levelIndex: number): string {
  const key = GROUP_LEVEL_KEYS[levelIndex]
  const v = key ? (col[key] as string | undefined) : undefined
  return (v ?? '').trim()
}

/**
 * Tạo celldata + merge cho header phân cấp N tầng (1–5 hàng).
 * - Mỗi ô thuộc vùng merge có mc (r, c, rs, cs) để Fortune-sheet vẽ merge đúng.
 * - Style: màu nền (bg), chữ đậm (bl), căn giữa (ht, vt).
 * Trả về { celldata, merge, headerRowCount }.
 */
function buildHeaderRows(cols: FormColumnDto[]): {
  celldata: CellItem[]
  merge: Record<string, { r: number; c: number; rs: number; cs: number }>
  headerRowCount: number
} {
  const celldata: CellItem[] = []
  const merge: Record<string, { r: number; c: number; rs: number; cs: number }> = {}

  let levelCount = 0
  for (let l = 0; l < GROUP_LEVEL_KEYS.length; l++) {
    if (cols.some((c) => getGroupLevelValue(c, l) !== '')) levelCount = l + 1
  }
  const headerRowCount = levelCount + 1

  const groupCellStyle: Partial<CellValue> = {
    bg: HEADER_BG_GROUP,
    bl: HEADER_FONT_BOLD,
    ht: HEADER_ALIGN_CENTER,
    vt: HEADER_ALIGN_CENTER,
  }
  const nameCellStyle: Partial<CellValue> = {
    bg: HEADER_BG_NAMES,
    bl: HEADER_FONT_BOLD,
    ht: HEADER_ALIGN_CENTER,
    vt: HEADER_ALIGN_CENTER,
  }

  for (let row = 0; row < levelCount; row++) {
    let c = 0
    while (c < cols.length) {
      const groupKey = getGroupLevelValue(cols[c], row)
      const groupName = groupKey || (row === levelCount - 1 ? cols[c].columnName : '')
      let cs = 1
      while (c + cs < cols.length && getGroupLevelValue(cols[c + cs], row) === groupKey) cs++
      const mc = cs > 1 && groupKey !== '' ? { r: row, c, rs: 1, cs } : undefined
      if (mc) merge[`${row}_${c}`] = mc
      celldata.push({
        r: row,
        c,
        v: {
          v: groupName,
          m: groupName,
          ct: { fa: 'General', t: 'g' },
          ...groupCellStyle,
          ...(mc && { mc }),
        },
      })
      for (let j = 1; j < cs; j++) {
        celldata.push({
          r: row,
          c: c + j,
          v: mc ? { mc } : null,
        })
      }
      c += cs
    }
  }

  const nameRow = levelCount
  cols.forEach((col, c) => {
    celldata.push({
      r: nameRow,
      c,
      v: {
        v: col.columnName,
        m: col.columnName,
        ct: { fa: 'General', t: 'g' },
        ...nameCellStyle,
      },
    })
  })

  return { celldata, merge, headerRowCount }
}

/**
 * Chuyển từ định dạng đơn giản (backend/upload) sang FortuneSheet Sheet[].
 * - Hàng header: 1 hàng tên cột, hoặc 2 hàng (nhóm cha + tên cột) nếu có columnGroupName.
 * - Dữ liệu bắt đầu ngay sau header. config.merge cho header phân cấp, rowReadOnly cho header.
 */
export function simpleToFortuneSheets(
  sheets: WorkbookSheetData[],
  columnsBySheet: Map<number, FormColumnDto[]>,
  sheetIds: number[]
): Sheet[] {
  return sheets.map((sheet, sheetIndex) => {
    const cols = sheetIds[sheetIndex] != null ? columnsBySheet.get(sheetIds[sheetIndex]) ?? [] : []
    type CellVal = string | number | boolean | undefined
    const { celldata: headerCelldata, merge: headerMerge, headerRowCount } = buildHeaderRows(cols)
    const celldata: CellItem[] = [...headerCelldata]
    const dataRowStart = headerRowCount
    sheet.rows.forEach((row, r) => {
      cols.forEach((col, c) => {
        const colKey = col.excelColumn ?? ''
        const raw = colKey ? row[colKey] : undefined
        const value: CellVal = raw === null || raw === undefined ? '' : typeof raw === 'number' || typeof raw === 'string' || typeof raw === 'boolean' ? raw : String(raw)
        const vStr = value !== '' && value !== undefined ? String(value) : ''
        const t = typeof value === 'number' ? 'n' : 'g'
        celldata.push({
          r: dataRowStart + r,
          c,
          v: { v: value, m: vStr, ct: { fa: 'General', t } },
        })
      })
    })
    const colReadOnly = buildColReadOnlyFromColumns(cols)
    const dataVerification = buildDataVerificationFromColumns(cols, dataRowStart, sheet.rows.length)
    const rowReadOnly: Record<number, number> = {}
    for (let i = 0; i < headerRowCount; i++) rowReadOnly[i] = 1
    const config: Sheet['config'] = {
      ...(colReadOnly && { colReadOnly }),
      ...(Object.keys(headerMerge).length > 0 && { merge: headerMerge }),
      ...(headerRowCount > 0 && { rowReadOnly }),
    }
    return {
      name: sheet.name,
      celldata,
      order: sheetIndex,
      row: Math.max(36, dataRowStart + sheet.rows.length + 5),
      column: Math.max(18, cols.length),
      ...(Object.keys(config).length > 0 && { config }),
      ...(dataVerification && { dataVerification }),
    }
  })
}

/** Lấy số dòng của sheet từ celldata hoặc data. */
function getSheetRowCount(sheet: Sheet): number {
  if (sheet.celldata?.length) {
    const maxR = Math.max(...sheet.celldata.map((cell) => cell.r))
    return maxR + 1
  }
  if (Array.isArray(sheet.data) && sheet.data.length) return sheet.data.length
  return 100
}

/** Dữ liệu sheet đơn giản từ backend (workbook-data). */
export type SimpleSheetData = { name: string; rows: Record<string, unknown>[] }

/**
 * Gộp template display (Fortune-sheet) với dữ liệu submission.
 * Giữ nguyên template (merge, style) cho vùng header (r < dataRowStart); điền dữ liệu từ dataSheets vào vùng data.
 * @param dataStartRowBySheet Map formSheetId -> hàng bắt đầu dữ liệu (1-based). Nếu có thì dùng thay cho header từ cột.
 */
export function mergeTemplateWithData(
  templateSheets: Sheet[],
  dataSheets: SimpleSheetData[],
  columnsBySheet: Map<number, FormColumnDto[]>,
  sheetIdsOrder: number[],
  dataStartRowBySheet?: Map<number, number>
): Sheet[] {
  return templateSheets.map((sheet, sheetIndex) => {
    const formSheetId = sheetIdsOrder[sheetIndex]
    const cols = formSheetId != null ? columnsBySheet.get(formSheetId) ?? [] : []
    let dataRowStart: number
    const configuredStart = formSheetId != null ? dataStartRowBySheet?.get(formSheetId) : undefined
    if (configuredStart != null && configuredStart >= 1) {
      dataRowStart = configuredStart - 1
    } else {
      let headerRowCount = 1
      for (let l = 0; l < GROUP_LEVEL_KEYS.length; l++) {
        if (cols.some((c) => getGroupLevelValue(c, l) !== '')) headerRowCount = l + 2
      }
      dataRowStart = headerRowCount
    }
    const dataRows = dataSheets[sheetIndex]?.rows ?? []
    const headerCelldata = (sheet.celldata ?? []).filter((cell) => cell.r < dataRowStart)
    const dataCelldata: CellItem[] = []
    dataRows.forEach((row, r) => {
      cols.forEach((col, c) => {
        const colKey = col.excelColumn ?? ''
        const raw = colKey ? row[colKey] : undefined
        const value: string | number | boolean | undefined =
          raw === null || raw === undefined
            ? ''
            : typeof raw === 'number' || typeof raw === 'string' || typeof raw === 'boolean'
              ? raw
              : String(raw)
        const vStr = value !== '' && value !== undefined ? String(value) : ''
        const t = typeof value === 'number' ? 'n' : 'g'
        dataCelldata.push({
          r: dataRowStart + r,
          c,
          v: { v: value, m: vStr, ct: { fa: 'General', t } },
        })
      })
    })
    const celldata = [...headerCelldata, ...dataCelldata]
    const maxR = celldata.length ? Math.max(...celldata.map((x) => x.r)) : 0
    const maxC = celldata.length ? Math.max(...celldata.map((x) => x.c)) : 0
    return {
      ...sheet,
      celldata,
      row: Math.max(sheet.row ?? 50, maxR + 10),
      column: Math.max(sheet.column ?? 20, maxC + 2),
    }
  })
}

/**
 * Áp dụng cấu hình form (khóa cột, dropdown) lên Sheet[] đã có (vd từ FortuneSheet load từ server).
 * sheetsOrder: thứ tự form sheet id tương ứng từng phần tử trong data (data[0] = sheet có id sheetsOrder[0]).
 */
export function applyFormConfigToFortuneSheets(
  data: Sheet[],
  columnsBySheet: Map<number, FormColumnDto[]>,
  sheetsOrder: number[]
): Sheet[] {
  return data.map((sheet, sheetIndex) => {
    const formSheetId = sheetsOrder[sheetIndex]
    const cols = formSheetId != null ? columnsBySheet.get(formSheetId) ?? [] : []
    const colReadOnly = buildColReadOnlyFromColumns(cols)
    const totalRows = getSheetRowCount(sheet)
    let headerRowCount = 1
    for (let l = 0; l < GROUP_LEVEL_KEYS.length; l++) {
      if (cols.some((c) => getGroupLevelValue(c, l) !== '')) headerRowCount = l + 2
    }
    const dataRowStart = headerRowCount
    const dataRowCount = Math.max(0, totalRows - headerRowCount)
    const dataVerification = buildDataVerificationFromColumns(cols, dataRowStart, dataRowCount)
    const nextConfig =
      colReadOnly || sheet.config
        ? { ...(sheet.config ?? {}), ...(colReadOnly && { colReadOnly }) }
        : undefined
    const nextDv =
      dataVerification || sheet.dataVerification
        ? { ...(sheet.dataVerification ?? {}), ...(dataVerification ?? {}) }
        : undefined
    return {
      ...sheet,
      ...(nextConfig != null && { config: nextConfig }),
      ...(nextDv != null && { dataVerification: nextDv }),
    }
  })
}
